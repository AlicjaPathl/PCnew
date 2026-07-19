import struct

def compile(compiler, args):
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"MOD: Za malo parametrow: {args}")
    dest_str = parts[0].upper()
    src_str  = parts[1].upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if dest_str not in reg_map:
        raise Exception(f"MOD: Pierwszy argument musi byc rejestrem: {dest_str}")
    dest = reg_map[dest_str]
    if src_str in reg_map:
        mode, src = 1, reg_map[src_str]
    else:
        mode = 0
        src_raw = parts[1]
        if src_raw in compiler.labels:
            src = compiler.labels[src_raw]
        else:
            try:
                src = int(src_raw, 0) & 0xFFFFFFFF
            except ValueError:
                raise Exception(f"MOD: Nieznana wartosc '{src_raw}'")
    # Opcode 31
    return struct.pack('>B B H I B', 31, mode, dest, src, 0)
