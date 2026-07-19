import os
import glob
import struct
import op

SECTOR_SIZE = 512

class Compiler:
    def __init__(self):
        self.binary = bytearray()
        self.labels = {}
        
        self.dispatch = {}
        for name, info in op.INSTRUCTION_SET.items():
            opcode, compile_func, _ = info
            self.dispatch[name] = self.make_compile_wrapper(opcode, name, compile_func)

    def make_compile_wrapper(self, opcode, name, compile_func):
        return lambda compiler, args: compile_func(opcode, name, args, compiler.labels)

    def clean_line(self, raw_line):
        line = raw_line.split(';')[0]
        return line.strip()

    def parse_db_line(self, line):
        db_idx = line.lower().find(" db ")
        if db_idx == -1:
            return None, None

        label_name = line[:db_idx].strip()
        data_part = line[db_idx + 4:].strip()

        if data_part.startswith('"') and data_part.endswith('"'):
            raw_str = data_part[1:-1]
            decoded_str = raw_str.encode('raw_unicode_escape').decode('unicode_escape')
            data_bytes = decoded_str.encode('utf-8') + b'\x00'
        else:
            data_bytes = bytearray()
            for token in data_part.replace(",", " ").split():
                data_bytes.append(int(token, 0))

        return label_name, data_bytes

    def compile_file(self, input_file, base_address=0):
        self.binary = bytearray()
        self.labels = {}

        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        cleaned_lines = []
        for line in lines:
            cleaned = self.clean_line(line)
            if cleaned:
                cleaned_lines.append(cleaned)
        self.cleaned_lines = cleaned_lines

        # PASS 1: collect label addresses
        current_address = base_address
        for line in cleaned_lines:
            if line.endswith(':'):
                label = line[:-1].strip()
                if label.lstrip('-').isdigit() or (label.startswith('0x') and all(c in '0123456789abcdefABCDEF' for c in label[2:])):
                    raise Exception(f"COMPILE ERROR: Label '{label}' is a plain number. Use a name like 'n_{label}' instead.")
                self.labels[label] = current_address
                continue
            label_name, data_bytes = self.parse_db_line(line)
            if label_name is not None:
                if label_name.lstrip('-').isdigit():
                    raise Exception(f"COMPILE ERROR: db label '{label_name}' is a plain number. Use a name like 'n_boot' instead.")
                self.labels[label_name] = current_address
                current_address += len(data_bytes)
                continue
            current_address += 9

        print(f"  Labels ({input_file}, base=0x{base_address:04X}):")
        for name, addr in self.labels.items():
            print(f"    {name}: 0x{addr:04X} ({addr})")

        # PASS 2: generate binary
        for line in cleaned_lines:
            if line.endswith(':'):
                continue
            label_name, data_bytes = self.parse_db_line(line)
            if label_name is not None:
                self.binary.extend(data_bytes)
                continue
            parts = line.replace(",", " ").split()
            cmd = parts[0].upper()
            args = parts[1:]
            if cmd in self.dispatch:
                self.binary.extend(self.dispatch[cmd](self, args))
            else:
                raise Exception(f"Unknown instruction '{cmd}' in {input_file}")

        return self.binary

def load_disk():
    if os.path.exists('disk.ds'):
        with open('disk.ds', 'r', encoding='utf-8') as f:
            content = f.read().strip()
        if content:
            raw_bytes = bytearray()
            for i in range(0, len(content), 8):
                byte_str = content[i:i+8]
                if len(byte_str) == 8:
                    raw_bytes.append(int(byte_str, 2))
            if len(raw_bytes) >= 4:
                return bytearray(raw_bytes[4:])
            return bytearray(raw_bytes)
    return bytearray()

def save_disk(disk):
    with open('disk.ds', 'w', encoding='utf-8') as f:
        binary_str = "".join(f"{b:08b}" for b in disk)
        f.write(binary_str + '\n')

def ensure_disk_size(disk, min_sectors):
    required = min_sectors * SECTOR_SIZE
    if len(disk) < required:
        disk.extend(b'\x00' * (required - len(disk)))
    return disk

def write_sector(disk, sector_num, data_bytes):
    disk = ensure_disk_size(disk, sector_num + 1)
    offset = sector_num * SECTOR_SIZE
    padded = data_bytes.ljust(SECTOR_SIZE, b'\x00')[:SECTOR_SIZE]
    disk[offset:offset + SECTOR_SIZE] = padded
    return disk

def compile_to_disk_string(input_file):
    c = Compiler()
    boot_bytes = c.compile_file(input_file, base_address=0)
    
    # Rule validation for bootloader
    if c.labels.get('_global', -1) != 0:
        raise Exception("BOOT ERROR: '_global' label missing or not at address 0")
    if '_start' not in c.labels:
        raise Exception("BOOT ERROR: '_start' label missing")
        
    entry_addr = c.labels.get('_global', c.labels.get('_start', 0))
    
    disk = bytearray()
    boot_sectors = (len(boot_bytes) + SECTOR_SIZE - 1) // SECTOR_SIZE
    disk.extend(b'\x00' * (boot_sectors * SECTOR_SIZE))
    for i in range(boot_sectors):
        chunk = boot_bytes[i * SECTOR_SIZE : (i + 1) * SECTOR_SIZE]
        offset = i * SECTOR_SIZE
        disk[offset:offset + len(chunk)] = chunk
        
    header = struct.pack('>I', entry_addr)
    disk_with_header = header + bytes(disk)
    return "".join(f"{b:08b}" for b in disk_with_header)

if __name__ == "__main__":
    import sys

    # Szybka kompilacja pojedynczego pliku: py comp.py program.s [program.ds]
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(input_file)[0] + '.ds'
        if not os.path.exists(input_file):
            print(f"ERROR: file not found: {input_file}")
            sys.exit(1)
        print(f"Compiling {input_file} -> {output_file} ...")
        try:
            disk_string = compile_to_disk_string(input_file)
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(disk_string + '\n')
            print(f"Done. Output: {output_file}")
        except Exception as e:
            print(f"Compilation failed: {e}")
            sys.exit(1)
        sys.exit(0)

    c = Compiler()

    print("=" * 50)
    print("  PC Compiler")
    print("=" * 50)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    main_s_path = os.path.join(script_dir, 'main.s')

    if not os.path.exists(main_s_path):
        print("ERROR: main.s not found!")
        exit(1)

    print("\n[Sector 0] Compiling bootloader: main.s")
    boot_bytes = c.compile_file(main_s_path, base_address=0)

    # --- BOOTLOADER VALIDATION ---
    if c.labels.get('_global', -1) != 0:
        print("BOOT ERROR: '_global' label missing or not at address 0 in main.s")
        exit(1)

    if '_start' not in c.labels:
        print("BOOT ERROR: '_start' label missing in main.s")
        exit(1)

    with open(main_s_path, 'r', encoding='utf-8') as _f:
        _src = _f.read()
    import re as _re
    hex_addr = f"0x{op.BOOT_STRING_ADDR:04X}"
    _match = _re.search(rf'(?i)mov\s+{hex_addr}\s*,\s*(\S+)', _src)
    if not _match:
        # Also check without leading zero or lowercase hex
        hex_addr_alt = f"0x{op.BOOT_STRING_ADDR:x}"
        _match = _re.search(rf'(?i)mov\s+{hex_addr_alt}\s*,\s*(\S+)', _src)
        if _match:
            hex_addr = hex_addr_alt

    if not _match:
        print(f"BOOT ERROR: 'MOV 0x{op.BOOT_STRING_ADDR:04X}, ...' missing in main.s")
        exit(1)

    _val = _match.group(1).strip().rstrip(',')
    try:
        int(_val, 0)
        print(f"BOOT ERROR: 'MOV {hex_addr}, {_val}' uses a raw number. Use a named label.")
        exit(1)
    except ValueError:
        _db_match = _re.search(rf'(?i)^\s*{_val}\s+db\s+"([^"]*)"', _src, _re.MULTILINE)
        if _db_match:
            _string_val = _db_match.group(1)
            if "BOOT" not in _string_val:
                print(f"BOOT ERROR: String for boot label '{_val}' must contain 'BOOT'.")
                exit(1)
        else:
            print(f"BOOT ERROR: Label '{_val}' is not defined as a db string.")
            exit(1)

    found_mov = False
    for i, line in enumerate(c.cleaned_lines):
        line_norm = " ".join(line.split()).lower()
        if line_norm.startswith(f"mov {hex_addr.lower()}") or line_norm.startswith(f"mov 0x{op.BOOT_STRING_ADDR:x}") or line_norm.startswith(f"mov 0x{op.BOOT_STRING_ADDR:04x}"):
            found_mov = True
            next_line = None
            for j in range(i + 1, len(c.cleaned_lines)):
                if not c.cleaned_lines[j].endswith(':'):
                    next_line = " ".join(c.cleaned_lines[j].split()).lower()
                    break
            if next_line != "syscall":
                print(f"BOOT ERROR: Instruction following 'MOV {hex_addr}, ...' must be 'syscall', but found '{next_line}'.")
                exit(1)
            break

    if not found_mov:
        print(f"BOOT ERROR: 'MOV {hex_addr}, ...' not found.")
        exit(1)

    print("  [Validation] Bootloader OK")

    entry_addr = c.labels.get('_global', c.labels.get('_start', 0))

    disk = load_disk()
    boot_sectors = (len(boot_bytes) + SECTOR_SIZE - 1) // SECTOR_SIZE
    for i in range(boot_sectors):
        chunk = boot_bytes[i * SECTOR_SIZE : (i + 1) * SECTOR_SIZE]
        disk = write_sector(disk, i, chunk)
    print(f"  -> Written to sectors 0 to {boot_sectors - 1} ({len(boot_bytes)} bytes)")

    other_files_paths = sorted(glob.glob(os.path.join(script_dir, '*.s')))
    other_files = [
        os.path.basename(f) for f in other_files_paths
        if os.path.basename(f) != 'main.s'
    ]

    if not other_files:
        print("\nNo other .s files found.")
    else:
        print(f"\nFound {len(other_files)} other .s file(s):")
        for fname in other_files:
            print(f"  - {fname}")

        for fname in other_files:
            print(f"\n--- {fname} ---")
            while True:
                try:
                    start_sector = int(input(f"  Starting sector for '{fname}' (1 or higher): ").strip())
                    if start_sector < 1:
                        print("  Must be >= 1")
                        continue
                    break
                except ValueError:
                    print("  Enter a number.")

            default_base = 0x0800 if start_sector == 1 else start_sector * SECTOR_SIZE
            while True:
                base_str = input(f"  RAM base address for '{fname}' (default 0x{default_base:04X}): ").strip()
                if not base_str:
                    base_addr = default_base
                    break
                try:
                    base_addr = int(base_str, 0)
                    break
                except ValueError:
                    print("  Enter a valid number.")

            print(f"  Compiling '{fname}' at base address 0x{base_addr:04X} ...")
            prog_bytes = c.compile_file(os.path.join(script_dir, fname), base_address=base_addr)
            sectors_needed = (len(prog_bytes) + SECTOR_SIZE - 1) // SECTOR_SIZE
            print(f"  Compiled: {len(prog_bytes)} bytes = {sectors_needed} sector(s)")

            for i in range(sectors_needed):
                chunk = prog_bytes[i * SECTOR_SIZE : (i + 1) * SECTOR_SIZE]
                disk = write_sector(disk, start_sector + i, chunk)
                print(f"  -> Written to sector {start_sector + i}")

    header = struct.pack('>I', entry_addr)
    disk_with_header = header + bytes(disk)

    with open('disk.ds', 'w', encoding='utf-8') as f:
        binary_str = "".join(f"{b:08b}" for b in disk_with_header)
        f.write(binary_str + '\n')

    total_sectors = len(disk) // SECTOR_SIZE
    print(f"\nDone. Disk image: {len(disk)} bytes ({total_sectors} sectors) -> disk.ds")