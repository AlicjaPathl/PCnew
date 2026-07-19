import struct

def compile(compiler, args):
    # Opcode 6, followed by 8 bytes of padding
    return struct.pack('>B 8x', 6)
