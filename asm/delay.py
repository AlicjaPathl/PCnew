import struct

def compile(compiler, args):
    # args: ['500']
    if not args:
        raise Exception("DELAY: Brak parametru czasu opoznienia")
        
    try:
        delay_ms = int(args[0], 0)
    except ValueError:
        raise Exception(f"DELAY: Nieprawidlowa wartosc czasu '{args[0]}'")
        
    # Format: Opcode 20 (1B) + delay_ms (4B) + padding (4B) = 9 bytes
    return struct.pack('>B I 4x', 20, delay_ms)
