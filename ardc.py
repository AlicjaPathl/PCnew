#!/usr/bin/env python3
"""
ardc.py — Arduino C Compiler
Oparty na cc.py. Kompiluje Vanilla-C do .s (ASM) i .ds (obraz dysku)
z pełną obsługą nagłówków Arduino (ard.h, display.h).

Syscalle Arduino (mapowane na Arduino hardware przez main.ino):

  AX=1   print_string(CX=addr)         → Serial.print + LCD row 0
  AX=2   read_int(CX=addr)             → Serial.parseInt
  AX=40  lcd_print(BX=row, CX=addr)   → LCD wiersz 0 lub 1
  AX=41  lcd_clear()                   → CLR pakiet
  AX=42  lcd_backlight(BX=0/1)         → BLOFF/BLON
  AX=43  lcd_cursor(BX=row, CX=col)   → CURSOR pakiet
  AX=44  pin_mode(BX=pin, CX=mode)    → PIN_MODE
  AX=45  pin_write(BX=pin, CX=val)    → PIN_WRITE
  AX=46  pin_read(BX=pin) → AX        → PIN_READ
  AX=47  analog_read(BX=pin) → AX     → ANA_READ
  AX=48  analog_write(BX=pin, CX=val) → ANA_WRITE
  AX=49  millis_now() → AX            → MILLIS
  AX=50  eeprom_write(BX=addr,CX=val) → EE_WRITE
  AX=51  eeprom_read(BX=addr) → AX    → EE_READ
  AX=52  serial_avail() → AX          → SER_AVAIL
  AX=53  serial_readbyte() → AX       → SER_READ
  AX=60  exit(CX=code)

Użycie:
  python ardc.py <plik.c>              # kompiluje do <plik>.s i <plik>.ds
  python ardc.py <plik.c> --upload    # kompiluje + wgrywa przez write.py
"""

import re
import sys
import os

# Dodaj katalog projektu do path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

import comp as comp_module

# ─────────────────────────────────────────────────────────────────────────────
# Arduino stdlib — implementacje funkcji Arduino jako ASM (syscalle)
# ─────────────────────────────────────────────────────────────────────────────

ARD_STDLIB = {
    # display.h
    'lcd_print': {
        'args': ['row', 'text'],
        'syscall': 40,
        'reg_map': {'row': 'BX', 'text': 'CX'},
    },
    'lcd_print0': {
        'args': ['text'],
        'syscall': 40,
        'setup': 'MOV BX, 0\n',
        'reg_map': {'text': 'CX'},
    },
    'lcd_print1': {
        'args': ['text'],
        'syscall': 40,
        'setup': 'MOV BX, 1\n',
        'reg_map': {'text': 'CX'},
    },
    'lcd_clear': {
        'args': [],
        'syscall': 41,
        'reg_map': {},
    },
    'lcd_backlight': {
        'args': ['on'],
        'syscall': 42,
        'reg_map': {'on': 'BX'},
    },
    'lcd_cursor': {
        'args': ['row', 'col'],
        'syscall': 43,
        'reg_map': {'row': 'BX', 'col': 'CX'},
    },
    'lcd_char': {
        'args': ['c'],
        'syscall': 44,
        'reg_map': {'c': 'CX'},
        'setup': 'MOV BX, 255\n',  # sentinel: char mode
    },
    'lcd_init': {
        'args': [],
        'syscall': 41,  # lcd_clear reinitializes
        'reg_map': {},
    },
    'lcd_scroll_left': {
        'args': [],
        'syscall': 45,
        'reg_map': {},
        'setup': 'MOV BX, 0\n',
    },
    'lcd_scroll_right': {
        'args': [],
        'syscall': 45,
        'reg_map': {},
        'setup': 'MOV BX, 1\n',
    },
    # ard.h — GPIO
    'pin_mode': {
        'args': ['pin', 'mode'],
        'syscall': 46,
        'reg_map': {'pin': 'BX', 'mode': 'CX'},
    },
    'pin_write': {
        'args': ['pin', 'val'],
        'syscall': 47,
        'reg_map': {'pin': 'BX', 'val': 'CX'},
    },
    'pin_read': {
        'args': ['pin'],
        'syscall': 48,
        'reg_map': {'pin': 'BX'},
        'returns': 'AX',
    },
    'analog_read': {
        'args': ['pin'],
        'syscall': 49,
        'reg_map': {'pin': 'BX'},
        'returns': 'AX',
    },
    'analog_write': {
        'args': ['pin', 'val'],
        'syscall': 50,
        'reg_map': {'pin': 'BX', 'val': 'CX'},
    },
    # Timing
    'delay_ms': {
        'args': ['ms'],
        'syscall': 51,
        'reg_map': {'ms': 'BX'},
    },
    'millis_now': {
        'args': [],
        'syscall': 52,
        'reg_map': {},
        'returns': 'AX',
    },
    # Serial
    'serial_println': {
        'args': ['s'],
        'syscall': 1,  # same as print_string
        'reg_map': {'s': 'CX'},
        'setup': 'MOV BX, 2\n',  # BX=2 = println mode
    },
    'serial_avail': {
        'args': [],
        'syscall': 53,
        'reg_map': {},
        'returns': 'AX',
    },
    'serial_readbyte': {
        'args': [],
        'syscall': 54,
        'reg_map': {},
        'returns': 'AX',
    },
    # EEPROM
    'eeprom_write': {
        'args': ['addr', 'val'],
        'syscall': 55,
        'reg_map': {'addr': 'BX', 'val': 'CX'},
    },
    'eeprom_read': {
        'args': ['addr'],
        'syscall': 56,
        'reg_map': {'addr': 'BX'},
        'returns': 'AX',
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# Stdlib ASM implementations (injected before user code)
# ─────────────────────────────────────────────────────────────────────────────

def gen_ard_func_asm(name, info):
    """Generate assembly for an Arduino stdlib function."""
    args = info['args']
    sc = info['syscall']
    reg_map = info.get('reg_map', {})
    setup = info.get('setup', '')
    returns_ax = info.get('returns', None) == 'AX'
    
    lines = [f'{name}:']
    lines.append(f'    PUSH BP')
    lines.append(f'    MOV BP, SP')
    
    # Load args from stack into registers
    # Args are at BP+8, BP+12, BP+16 ... (after saved BP and return addr)
    offsets = [8 + i*4 for i in range(len(args))]
    
    for arg, offset in zip(args, offsets):
        reg = reg_map.get(arg)
        if reg:
            lines.append(f'    LOAD {reg}, [BP+{offset}]')
    
    # Optional setup (MOV BX, N etc.)
    if setup:
        for s in setup.strip().split('\n'):
            s = s.strip()
            if s:
                lines.append(f'    {s}')
    
    # Syscall
    lines.append(f'    MOV AX, {sc}')
    lines.append(f'    SYSCALL')
    
    lines.append(f'epilogue_{name}:')
    lines.append(f'    POP BP')
    lines.append(f'    RET')
    
    return '\n'.join(lines) + '\n'


def get_ard_stdlib_asm():
    """Generate all Arduino stdlib functions as ASM."""
    parts = []
    for name, info in ARD_STDLIB.items():
        parts.append(gen_ard_func_asm(name, info))
    return '\n'.join(parts)


# ─────────────────────────────────────────────────────────────────────────────
# Preprocess: resolve #include <ard.h>, <display.h>, <Wire.h>, etc.
# ─────────────────────────────────────────────────────────────────────────────

# Arduino includes that we handle (map to our header files)
ARD_INCLUDES = {
    'ard.h':              os.path.join(SCRIPT_DIR, 'ard', 'ard.h'),
    'display.h':          os.path.join(SCRIPT_DIR, 'ard', 'display.h'),
    'Wire.h':             None,   # ignored — handled by Arduino IDE
    'LiquidCrystal_I2C.h': None,  # ignored — handled by Arduino IDE
    'Arduino.h':          None,   # ignored
    'avr/pgmspace.h':     None,   # ignored
}

# Standard library headers (from std/)
STD_INCLUDES = {
    'stdio.h':   os.path.join(SCRIPT_DIR, 'std', 'stdio.h'),
    'stdlib.h':  os.path.join(SCRIPT_DIR, 'std', 'stdlib.h'),
    'string.h':  os.path.join(SCRIPT_DIR, 'std', 'string.h'),
    'fileio.h':  os.path.join(SCRIPT_DIR, 'std', 'fileio.h'),
}

def preprocess(source, filename):
    """Resolve #include, #define for Arduino + std libraries."""
    lines = source.split('\n')
    result = []
    defines = {}
    
    # Built-in Arduino constants as #defines
    defines.update({
        'INPUT':        '0',
        'OUTPUT':       '1',
        'INPUT_PULLUP': '2',
        'LOW':          '0',
        'HIGH':         '1',
        'LED_BUILTIN':  '13',
        'A0': '14', 'A1': '15', 'A2': '16',
        'A3': '17', 'A4': '18', 'A5': '19',
        'true': '1', 'false': '0',
        'NULL': '0',
    })
    
    for line in lines:
        stripped = line.strip()
        
        # #include
        if stripped.startswith('#include'):
            m = re.match(r'#include\s+[<"]([^>"]+)[>"]', stripped)
            if m:
                hdr = m.group(1)
                # Arduino-specific headers
                if hdr in ARD_INCLUDES:
                    path = ARD_INCLUDES[hdr]
                    if path and os.path.exists(path):
                        with open(path, 'r', encoding='utf-8') as f:
                            # Only extract declarations (strip comments, keep signatures)
                            hdr_content = f.read()
                            # Strip C-style comments
                            hdr_content = re.sub(r'/\*.*?\*/', '', hdr_content, flags=re.DOTALL)
                            hdr_content = re.sub(r'//.*', '', hdr_content)
                            # Remove #ifndef guards and #define guards
                            hdr_content = re.sub(r'#ifndef\s+\w+', '', hdr_content)
                            hdr_content = re.sub(r'#define\s+\w+\s*$', '', hdr_content, flags=re.MULTILINE)
                            hdr_content = re.sub(r'#endif.*', '', hdr_content)
                            result.append(f'// included: {hdr}')
                            result.append(hdr_content)
                    # else: just ignore (Wire.h etc. — Arduino IDE handles it)
                else:
                    # Keep standard includes or local files for cc.py to resolve
                    result.append(line)
            continue
        
        # #define
        if stripped.startswith('#define'):
            m = re.match(r'#define\s+(\w+)\s+(.*)', stripped)
            if m:
                defines[m.group(1)] = m.group(2).strip()
            continue
        
        # Apply defines (simple text substitution)
        processed = line
        for name, val in defines.items():
            processed = re.sub(r'\b' + re.escape(name) + r'\b', val, processed)
        
        result.append(processed)
    
    return '\n'.join(result)


# ─────────────────────────────────────────────────────────────────────────────
# Import cc.py's compiler internals
# ─────────────────────────────────────────────────────────────────────────────

def compile_arduino(source_file, output_ds=None, output_s=None, verbose=True):
    """
    Compile a .c file (Arduino-flavored) to .s and .ds.
    Returns (asm_path, ds_path).
    """
    if not os.path.exists(source_file):
        print(f"ardc.py: ERROR: File '{source_file}' not found.")
        sys.exit(1)
    
    base = os.path.splitext(source_file)[0]
    if output_s is None:
        output_s = base + '.s'
    if output_ds is None:
        output_ds = base + '.ds'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        source = f.read()
    
    # ── Step 1: Preprocess ──────────────────────────────────────────────
    if verbose:
        print(f"[ardc] Preprocessing {source_file}...")
    preprocessed = preprocess(source, source_file)
    
    # Save preprocessed for debugging
    prep_path = base + '_prep.c'
    with open(prep_path, 'w', encoding='utf-8') as f:
        f.write(preprocessed)
    
    # ── Step 2: Import cc.py and compile ──────────────────────────────
    if verbose:
        print(f"[ardc] Compiling C → ASM...")
    
    # We use cc.py's tokenize/parse/compile pipeline
    # Import cc module
    import cc as cc_module
    
    # Patch cc module to recognize Arduino function declarations
    # (they appear as extern declarations in headers)
    
    tokens = cc_module.tokenize(preprocessed)
    ast_tree = cc_module.parse(tokens)
    
    # Generate standard library ASM (stdio, stdlib, string)
    std_asm = cc_module.compile_stdlib()
    
    # Generate Arduino stdlib ASM
    ard_asm = get_ard_stdlib_asm_from_cc(cc_module)
    
    # Compile user code
    user_asm = cc_module.compile_program(ast_tree)
    
    # Combine: bootloader + std + arduino_stdlib + user_code
    full_asm = std_asm + '\n' + ard_asm + '\n' + user_asm
    
    with open(output_s, 'w', encoding='utf-8') as f:
        f.write(full_asm)
    
    if verbose:
        print(f"[ardc] ASM written to {output_s}")
    
    # ── Step 3: Assemble to .ds ─────────────────────────────────────────
    if verbose:
        print(f"[ardc] Assembling {output_s} → {output_ds}...")
    
    comp_module.compile_file(output_s, output_ds)
    
    if verbose:
        print(f"[ardc] Done! → {output_ds}")
    
    return output_s, output_ds


def get_ard_stdlib_asm_from_cc(cc_module):
    """
    Generate Arduino stdlib as a string of ASM using cc.py's code generator.
    We use inline ASM approach for simplicity.
    """
    # For each Arduino function, generate a minimal ASM function body
    # using the cc.py assembler syntax
    lines = []
    
    for name, info in ARD_STDLIB.items():
        args = info['args']
        sc = info['syscall']
        reg_map = info.get('reg_map', {})
        setup = info.get('setup', '')
        
        lines.append(f'{name}:')
        lines.append(f'    PUSH BP')
        lines.append(f'    MOV BP, SP')
        
        # Load args: first arg at [BP+8], second at [BP+12], etc.
        for i, arg in enumerate(args):
            reg = reg_map.get(arg)
            if reg:
                offset = 8 + i * 4
                lines.append(f'    LOAD {reg}, [BP+{offset}]')
        
        # Setup instructions
        if setup:
            for s in setup.strip().split('\n'):
                s = s.strip()
                if s:
                    lines.append(f'    {s}')
        
        lines.append(f'    MOV AX, {sc}')
        lines.append(f'    SYSCALL')
        lines.append(f'epilogue_{name}:')
        lines.append(f'    MOV SP, BP')
        lines.append(f'    POP BP')
        lines.append(f'    RET')
        lines.append('')
    
    return '\n'.join(lines)


# ─────────────────────────────────────────────────────────────────────────────
# Direct compilation using cc.py subprocess approach (more reliable)
# ─────────────────────────────────────────────────────────────────────────────

def compile_arduino_via_cc(source_file, output_ds=None, output_s=None, verbose=True):
    """
    Preprocess the .c file for Arduino, then call cc.py for actual compilation.
    This is the reliable path: cc.py does all the heavy lifting.
    """
    if not os.path.exists(source_file):
        print(f"ardc.py: ERROR: File '{source_file}' not found.")
        sys.exit(1)
    
    base = os.path.splitext(source_file)[0]
    if output_s is None:
        output_s = base + '.s'
    if output_ds is None:
        output_ds = base + '.ds'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        source = f.read()
    
    # ── Step 1: Inject Arduino function declarations ────────────────────
    # Inject extern declarations for all Arduino stdlib functions
    # so cc.py treats them as known functions
    ard_decls = []
    ard_decls.append('// === Arduino stdlib declarations (auto-injected by ardc.py) ===')
    
    # lcd functions
    ard_decls.append('void lcd_print(int row, char *text);')
    ard_decls.append('void lcd_print0(char *text);')
    ard_decls.append('void lcd_print1(char *text);')
    ard_decls.append('void lcd_clear();')
    ard_decls.append('void lcd_backlight(int on);')
    ard_decls.append('void lcd_cursor(int row, int col);')
    ard_decls.append('void lcd_char(int c);')
    ard_decls.append('void lcd_init();')
    ard_decls.append('void lcd_scroll_left();')
    ard_decls.append('void lcd_scroll_right();')
    # ard functions
    ard_decls.append('void pin_mode(int pin, int mode);')
    ard_decls.append('void pin_write(int pin, int val);')
    ard_decls.append('int pin_read(int pin);')
    ard_decls.append('int analog_read(int pin);')
    ard_decls.append('void analog_write(int pin, int val);')
    ard_decls.append('void delay_ms(int ms);')
    ard_decls.append('int millis_now();')
    ard_decls.append('void serial_println(char *s);')
    ard_decls.append('int serial_avail();')
    ard_decls.append('int serial_readbyte();')
    ard_decls.append('void eeprom_write(int addr, int val);')
    ard_decls.append('int eeprom_read(int addr);')
    ard_decls.append('// === end arduino decls ===')
    
    # ── Step 2: Preprocess ─────────────────────────────────────────────
    if verbose:
        print(f"[ardc] Preprocessing {source_file} for Arduino...")
    preprocessed = preprocess(source, source_file)
    
    # Inject declarations at top (after any initial includes already resolved)
    preprocessed = '\n'.join(ard_decls) + '\n' + preprocessed
    
    # Write temp .c file for cc.py
    tmp_c = base + '__ard_tmp.c'
    with open(tmp_c, 'w', encoding='utf-8') as f:
        f.write(preprocessed)
    
    # ── Step 3: Compile with cc.py ─────────────────────────────────────
    if verbose:
        print(f"[ardc] Compiling with cc.py (Arduino target)...")
    
    import cc as cc_module
    
    try:
        # Let cc.py do the heavy lifting of preprocessing and compiling
        full_asm = cc_module.preprocess_and_compile(tmp_c)
        
        # Generate Arduino stdlib (as inline ASM functions)  
        ard_asm_text = generate_ard_asm_text()
        
        # Append Arduino stdlib to the compiled ASM
        full_asm = full_asm + '\n\n; === Arduino stdlib ===\n' + ard_asm_text
        
    finally:
        # Clean up temp file
        if os.path.exists(tmp_c):
            os.remove(tmp_c)
    
    # ── Step 4: Write .s ───────────────────────────────────────────────
    with open(output_s, 'w', encoding='utf-8') as f:
        f.write(full_asm)
    
    if verbose:
        print(f"[ardc] ASM -> {output_s}")
    
    # ── Step 5: Assemble to .ds ────────────────────────────────────────
    if verbose:
        print(f"[ardc] Assembling -> {output_ds}...")
    
    disk_string = comp_module.compile_to_disk_string(output_s)
    with open(output_ds, 'w', encoding='utf-8') as f:
        f.write(disk_string + '\n')
    
    if verbose:
        print(f"[ardc] OK Done! Output: {output_ds}")
    
    return output_s, output_ds


def generate_ard_asm_text():
    """Generate all Arduino stdlib functions in ASM syntax understood by comp.py."""
    lines = []
    for name, info in ARD_STDLIB.items():
        args = info['args']
        sc = info['syscall']
        reg_map = info.get('reg_map', {})
        setup = info.get('setup', '')
        
        lines.append(f'{name}:')
        lines.append(f'    PUSH BP')
        lines.append(f'    MOV BP, SP')
        
        for i, arg in enumerate(args):
            reg = reg_map.get(arg)
            if reg:
                offset = 8 + i * 4
                lines.append(f'    LOAD {reg}, [BP+{offset}]')
        
        if setup:
            for s in setup.strip().split('\n'):
                s = s.strip()
                if s:
                    lines.append(f'    {s}')
        
        lines.append(f'    MOV AX, {sc}')
        lines.append(f'    SYSCALL')
        lines.append(f'epilogue_{name}:')
        lines.append(f'    MOV SP, BP')
        lines.append(f'    POP BP')
        lines.append(f'    RET')
        lines.append('')
    
    return '\n'.join(lines)


# ─────────────────────────────────────────────────────────────────────────────
# Main entry point
# ─────────────────────────────────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(
        description='ardc.py — Arduino C Compiler (based on cc.py)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ardc.py hello.c              # compile only
  python ardc.py hello.c --upload     # compile + upload via write.py
  python ardc.py hello.c --port COM5  # compile + upload to COM5
  python ardc.py hello.c --board arduino:avr:mega  # Mega board
        """
    )
    parser.add_argument('source', help='.c source file')
    parser.add_argument('--upload', '-u', action='store_true',
                        help='Upload to Arduino after compiling (uses write.py)')
    parser.add_argument('--port', default=None,
                        help='Serial port for upload (default: from write.py)')
    parser.add_argument('--board', default=None,
                        help='Arduino board FQBN (default: arduino:avr:uno)')
    parser.add_argument('--output', '-o', default=None,
                        help='Output .ds filename')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Verbose output')
    args = parser.parse_args()
    
    source = args.source
    base = os.path.splitext(source)[0]
    output_ds = args.output or (base + '.ds')
    output_s  = base + '.s'
    
    print(f"ardc.py — Arduino C Compiler")
    print(f"Source: {source}")
    print()
    
    # Compile
    try:
        compile_arduino_via_cc(source, output_ds, output_s, verbose=True)
    except Exception as e:
        print(f"\n[ERROR] Compilation failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    print()
    print(f"  ASM:  {output_s}")
    print(f"  Disk: {output_ds}")
    
    # Upload if requested
    if args.upload:
        print()
        print("[ardc] Uploading to Arduino...")
        
        # Update write.py to use our .ds
        import write_helper
        write_helper.upload(
            ds_path=output_ds,
            port=args.port,
            board=args.board,
        )


if __name__ == '__main__':
    main()
