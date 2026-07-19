import struct

def compile(compiler, args):
    # args: ['ax,', 'choice']
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"LOAD: Za malo parametrow: {args}")
        
    reg_str = parts[0].upper()
    addr_str = parts[1]
    
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if reg_str not in reg_map:
        raise Exception(f"LOAD: Nieprawidlowy rejestr '{reg_str}'")
    reg = reg_map[reg_str]
    
    # Resolve memory address
    if addr_str in compiler.labels:
        addr = compiler.labels[addr_str]
    else:
        if addr_str.isdigit():
            raise Exception(f"LOAD ERROR: Memory address '{addr_str}' must be in hexadecimal format (e.g. '0x{int(addr_str):04X}') or a named label.")
        try:
            addr = int(addr_str, 0)
        except ValueError:
            raise Exception(f"LOAD: Nieznany symbol lub adres '{addr_str}'")
            
    # Format: Opcode 8 (1B) + reg (1B) + address (4B) + padding (3B) = 9 bytes
    return struct.pack('>B B I 3x', 8, reg, addr)
