import struct

def compile(compiler, args):
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"CMP: Za malo parametrow: {args}")
        
    dest_str = parts[0].upper()
    src_str = parts[1].upper()
    
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    
    if dest_str not in reg_map:
        raise Exception(f"CMP: Pierwszy argument musi byc rejestrem: {dest_str}")
    dest = reg_map[dest_str]
    
    if src_str in reg_map:
        # Register to Register comparison: Mode = 1
        mode = 1
        src = reg_map[src_str]
    else:
        # Immediate to Register comparison: Mode = 0
        mode = 0
        try:
            src = int(src_str, 0)
        except ValueError:
            raise Exception(f"CMP: Nieprawidlowa wartosc '{src_str}'")
            
    # Format: Opcode 2 (1B) + mode (1B) + dest (2B) + src (4B) + padding (1B) = 9 bytes
    return struct.pack('>B B H I B', 2, mode, dest, src, 0)
