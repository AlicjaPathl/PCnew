import struct

def compile_push(compiler, args):
    # PUSH val (can be register or immediate/label)
    arg_str = " ".join(args).strip()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    val_str = arg_str.upper()
    if val_str in reg_map:
        mode = 1
        val = reg_map[val_str]
    else:
        mode = 0
        if arg_str in compiler.labels:
            val = compiler.labels[arg_str]
        else:
            try:
                val = int(arg_str, 0) & 0xFFFFFFFF
            except ValueError:
                raise Exception(f"PUSH: Nieznana wartosc, rejestr lub symbol '{arg_str}'")
    # Opcode 21 + mode(1) + val(4) + pad(3) = 9 bytes
    return struct.pack('>B B I 3x', 21, mode, val)

def compile_pop(compiler, args):
    # POP reg (must be register)
    arg_str = " ".join(args).strip().upper()
    reg_map = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}
    if arg_str not in reg_map:
        raise Exception(f"POP: Nieprawidlowy rejestr '{arg_str}'")
    reg = reg_map[arg_str]
    # Opcode 22 + reg(1) + pad(7) = 9 bytes
    return struct.pack('>B B 7x', 22, reg)

def compile_call(compiler, args):
    # CALL target
    arg_str = " ".join(args).strip()
    if arg_str in compiler.labels:
        addr = compiler.labels[arg_str]
    else:
        try:
            addr = int(arg_str, 0)
        except ValueError:
            raise Exception(f"CALL: Nieznany symbol lub adres '{arg_str}'")
    # Opcode 23 + target(8) = 9 bytes
    return struct.pack('>B Q', 23, addr)

def compile_ret(compiler, args):
    # RET
    # Opcode 24 + pad(8) = 9 bytes
    return struct.pack('>B 8x', 24)
