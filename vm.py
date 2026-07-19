import struct
import op

class VM:
    def __init__(self, disk_file=None, disk_content=None):
        self.disk_file = disk_file
        
        # System RAM configured dynamically
        self.ram = bytearray(op.RAM_SIZE)
        
        # Registers: AX=0, BX=1, CX=2, DX=3, SP=4, BP=5
        self.regs = [0, 0, 0, 0, op.SP_START, 0]
        
        if disk_content is not None:
            content = disk_content.strip()
        else:
            if not disk_file:
                raise Exception("VM Error: No disk file or embedded content provided")
            with open(disk_file, 'r', encoding='utf-8') as f:
                content = f.read().strip()
        
        # Convert binary bits string to bytes
        raw_list = []
        for i in range(0, len(content), 8):
            byte_str = content[i:i+8]
            if len(byte_str) == 8:
                raw_list.append(int(byte_str, 2))
        raw = bytes(raw_list)

        # Read entry point from 4-byte header
        self.pc = struct.unpack('>I', raw[0:4])[0]

        # Load the rest (actual sectors) into RAM from address 0
        binary_data = raw[4:]
        self.ram[:len(binary_data)] = binary_data

        # Cache sectors data for disk I/O (syscall 25)
        self.disk_raw = raw[4:]

        # VM state
        self.running = True
        self.zf = False
        self.lf = False
        self.disk_buffer = bytearray(512)
        
        # File descriptor tracking for syscalls
        self.files = {}
        self.next_fd = 3
        
        # Parse and write CLI arguments to RAM
        import sys
        if len(sys.argv) > 1 and sys.argv[1] == self.disk_file:
            cli_args = sys.argv[2:]
        else:
            cli_args = sys.argv[1:]
            
        binary_end = len(binary_data)
        arg_start = (binary_end + 255) & ~255
        
        argc = len(cli_args)
        argv_ptrs = []
        curr_addr = arg_start + (argc * 4) + 4
        
        for arg in cli_args:
            arg_bytes = arg.encode('utf-8') + b'\x00'
            if curr_addr + len(arg_bytes) <= len(self.ram):
                self.ram[curr_addr : curr_addr + len(arg_bytes)] = arg_bytes
                argv_ptrs.append(curr_addr)
                curr_addr += len(arg_bytes)
            else:
                raise Exception("VM Error: RAM overflow while writing CLI arguments")
                
        # Write argv pointers array
        for idx, ptr in enumerate(argv_ptrs):
            struct.pack_into('>I', self.ram, arg_start + idx * 4, ptr)
        struct.pack_into('>I', self.ram, arg_start + argc * 4, 0)
        
        self.regs[0] = argc
        self.regs[1] = arg_start

        # Dynamic dispatch from instruction set
        self.dispatch = {info[0]: info[2] for info in op.INSTRUCTION_SET.values()}

    def run(self):
        ram = self.ram
        dispatch = self.dispatch
        
        while self.running and self.pc < len(ram):
            opcode = ram[self.pc]
            if opcode == 0:
                break

            if self.pc + 9 > len(ram):
                print("VM Error: Program Counter out of memory range")
                break

            # Execute command directly with the offset to arguments
            if opcode in dispatch:
                dispatch[opcode](self, self.pc + 1)
            else:
                print(f"VM Error: Unknown opcode {opcode} at PC={self.pc}")
                break
                
            self.pc += 9

if __name__ == "__main__":
    import sys
    import os
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        vm = VM(sys.argv[1])
    else:
        # Default fallback to disk.ds
        vm = VM('disk.ds')
    vm.run()