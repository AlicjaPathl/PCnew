import struct

def compile_not(compiler, args):
    # NOT reg — opcode 17, 1 operand
    arg_str = " ".join(args).strip().upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if arg_str not in reg_map:
        raise Exception(f"NOT: Nieprawidlowy rejestr '{arg_str}'")
    reg = reg_map[arg_str]
    # Opcode 17 + reg(1) + pad(7) = 9 bytes
    return struct.pack('>B B 7x', 17, reg)

def compile_neg(compiler, args):
    # NEG reg — opcode 28, 1 operand
    arg_str = " ".join(args).strip().upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if arg_str not in reg_map:
        raise Exception(f"NEG: Nieprawidlowy rejestr '{arg_str}'")
    reg = reg_map[arg_str]
    # Opcode 28 + reg(1) + pad(7) = 9 bytes
    return struct.pack('>B B 7x', 28, reg)

def compile_inc(compiler, args):
    # INC reg — opcode 29, 1 operand
    arg_str = " ".join(args).strip().upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if arg_str not in reg_map:
        raise Exception(f"INC: Nieprawidlowy rejestr '{arg_str}'")
    reg = reg_map[arg_str]
    # Opcode 29 + reg(1) + pad(7) = 9 bytes
    return struct.pack('>B B 7x', 29, reg)

def compile_dec(compiler, args):
    # DEC reg — opcode 30, 1 operand
    arg_str = " ".join(args).strip().upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if arg_str not in reg_map:
        raise Exception(f"DEC: Nieprawidlowy rejestr '{arg_str}'")
    reg = reg_map[arg_str]
    # Opcode 30 + reg(1) + pad(7) = 9 bytes
    return struct.pack('>B B 7x', 30, reg)
