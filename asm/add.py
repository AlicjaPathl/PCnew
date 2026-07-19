import struct

def compile(compiler, args):
    # args: ['ax,', '1']
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"ADD: Za malo parametrow: {args}")
        
    dest_str = parts[0].upper()
    src_str = parts[1].upper()
    
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    
    if dest_str not in reg_map:
        raise Exception(f"ADD: Pierwszy argument musi byc rejestrem: {dest_str}")
    dest = reg_map[dest_str]
    
    if src_str in reg_map:
        # Register to Register addition: Mode = 1
        mode = 1
        src = reg_map[src_str]
    else:
        # Immediate to Register addition: Mode = 0
        mode = 0
        try:
            src = int(src_str, 0) & 0xFFFFFFFF
        except ValueError:
            raise Exception(f"ADD: Nieprawidlowa wartosc '{src_str}'")
            
    # Format: Opcode 9 (1B) + mode (1B) + dest (2B) + src (4B) + padding (1B) = 9 bytes
    return struct.pack('>B B H I B', 9, mode, dest, src, 0)
