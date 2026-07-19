import struct

def compile(compiler, args):
    label = args[0].strip()
    if label in compiler.labels:
        addr = compiler.labels[label]
    else:
        try:
            addr = int(label, 0)
        except ValueError:
            raise Exception(f"JNZ: Nieznany symbol lub adres '{label}'")
            
    # Opcode 5 (1B) + address (8B) = 9 bytes
    return struct.pack('>B Q', 5, addr)
