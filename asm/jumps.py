import struct

def _compile_jump(opcode, name, compiler, args):
    arg_str = " ".join(args).strip()
    if arg_str in compiler.labels:
        addr = compiler.labels[arg_str]
    else:
        try:
            addr = int(arg_str, 0)
        except ValueError:
            raise Exception(f"{name}: Nieznany symbol lub adres '{arg_str}'")
    return struct.pack('>B Q', opcode, addr)

def compile_jg (compiler, args): return _compile_jump(25, 'JG',  compiler, args)
def compile_jge(compiler, args): return _compile_jump(26, 'JGE', compiler, args)
def compile_jle(compiler, args): return _compile_jump(27, 'JLE', compiler, args)
