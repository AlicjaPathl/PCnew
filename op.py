import struct
import time
import os
import socket

def load_config():
    config = {
        'ram_size': 65536,
        'sp_start': 65536,
        'boot_string_addr': 2032
    }
    try:
        proj_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(proj_dir, 'conf_vm.toml')
        if os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#') or line.startswith('['):
                        continue
                    if '=' in line:
                        k, v = line.split('=', 1)
                        k = k.strip()
                        v = v.split('#')[0].strip()
                        if v.startswith('0x') or v.startswith('0X'):
                            val = int(v, 16)
                        else:
                            try:
                                val = int(v)
                            except ValueError:
                                val = v
                        config[k] = val
    except Exception as e:
        print(f"Warning: Failed to load conf_vm.toml: {e}")
    return config

CONFIG = load_config()
RAM_SIZE = CONFIG['ram_size']
SP_START = CONFIG['sp_start']
BOOT_STRING_ADDR = CONFIG['boot_string_addr']

# Central register mapping
REG_MAP = {'AX': 0, 'BX': 1, 'CX': 2, 'DX': 3, 'SP': 4, 'BP': 5}

def read_string(vm, addr):
    chars = []
    while addr < len(vm.ram):
        c = vm.ram[addr]
        if c == 0:
            break
        chars.append(chr(c))
        addr += 1
    return "".join(chars)

def exec_mov(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    if mode == 0:
        # Immediate/label to Register
        if 0 <= dest < len(vm.regs):
            vm.regs[dest] = src
        else:
            raise Exception(f"VM Error: Invalid register index {dest}")
    elif mode == 1:
        # Immediate/label to Memory (write 4 bytes of src to RAM)
        if dest + 4 <= len(vm.ram):
            struct.pack_into('>I', vm.ram, dest, src)
        else:
            raise Exception(f"VM Error: Memory write out of bounds at address {dest}")
    elif mode == 2:
        # Register to Register
        if 0 <= dest < len(vm.regs) and 0 <= src < len(vm.regs):
            vm.regs[dest] = vm.regs[src]
        else:
            raise Exception(f"VM Error: Invalid register index dest={dest}, src={src}")

def exec_store(vm, offset):
    reg, addr, mode = struct.unpack_from('>B I B 2x', vm.ram, offset)
    if mode == 0:
        target_addr = addr
    elif mode == 1:
        target_addr = vm.regs[addr]
    elif mode == 2:
        reg_idx = (addr >> 24) & 0xFF
        off_val = addr & 0xFFFFFF
        if off_val >= 0x800000:
            off_val -= 0x1000000
        target_addr = (vm.regs[reg_idx] + off_val) & 0xFFFFFFFF
    else:
        raise Exception(f"VM Error: Invalid STORE mode {mode}")

    # Heuristic: if memory address is 512-byte aligned and mode is 0, copy 512-byte disk buffer.
    # Otherwise, write the 4-byte register value.
    if mode == 0 and target_addr % 512 == 0:
        if target_addr + 512 <= len(vm.ram):
            vm.ram[target_addr : target_addr + 512] = vm.disk_buffer
            print(f"Disk buffer of 512 bytes stored to memory address 0x{target_addr:04X}.")
        else:
            raise Exception(f"VM Error: Store address 0x{target_addr:04X} out of bounds")
    else:
        if target_addr + 4 <= len(vm.ram):
            struct.pack_into('>I', vm.ram, target_addr, vm.regs[reg] & 0xFFFFFFFF)
        else:
            raise Exception(f"VM Error: Store address 0x{target_addr:04X} out of bounds")

def exec_load(vm, offset):
    reg, addr, mode = struct.unpack_from('>B I B 2x', vm.ram, offset)
    if mode == 0:
        target_addr = addr
    elif mode == 1:
        target_addr = vm.regs[addr]
    elif mode == 2:
        reg_idx = (addr >> 24) & 0xFF
        off_val = addr & 0xFFFFFF
        if off_val >= 0x800000:
            off_val -= 0x1000000
        target_addr = (vm.regs[reg_idx] + off_val) & 0xFFFFFFFF
    else:
        raise Exception(f"VM Error: Invalid LOAD mode {mode}")

    if target_addr + 4 <= len(vm.ram):
        vm.regs[reg] = struct.unpack_from('>I', vm.ram, target_addr)[0]
    else:
        raise Exception(f"VM Error: Load address 0x{target_addr:04X} out of bounds")

def exec_load_b(vm, offset):
    reg, addr, mode = struct.unpack_from('>B I B 2x', vm.ram, offset)
    if mode == 0:
        target_addr = addr
    elif mode == 1:
        target_addr = vm.regs[addr]
    elif mode == 2:
        reg_idx = (addr >> 24) & 0xFF
        off_val = addr & 0xFFFFFF
        if off_val >= 0x800000:
            off_val -= 0x1000000
        target_addr = (vm.regs[reg_idx] + off_val) & 0xFFFFFFFF
    else:
        raise Exception(f"VM Error: Invalid LOAD_B mode {mode}")

    if target_addr < len(vm.ram):
        vm.regs[reg] = vm.ram[target_addr]
    else:
        raise Exception(f"VM Error: Load byte address 0x{target_addr:04X} out of bounds")

def exec_store_b(vm, offset):
    reg, addr, mode = struct.unpack_from('>B I B 2x', vm.ram, offset)
    if mode == 0:
        target_addr = addr
    elif mode == 1:
        target_addr = vm.regs[addr]
    elif mode == 2:
        reg_idx = (addr >> 24) & 0xFF
        off_val = addr & 0xFFFFFF
        if off_val >= 0x800000:
            off_val -= 0x1000000
        target_addr = (vm.regs[reg_idx] + off_val) & 0xFFFFFFFF
    else:
        raise Exception(f"VM Error: Invalid STORE_B mode {mode}")

    if target_addr < len(vm.ram):
        vm.ram[target_addr] = vm.regs[reg] & 0xFF
    else:
        raise Exception(f"VM Error: Store byte address 0x{target_addr:04X} out of bounds")

def exec_jmp(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    vm.pc = target - 9

def exec_add(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    if mode == 0:
        # Immediate to Register
        vm.regs[dest] = (vm.regs[dest] + src) & 0xFFFFFFFF
    elif mode == 1:
        # Register to Register
        vm.regs[dest] = (vm.regs[dest] + vm.regs[src]) & 0xFFFFFFFF

def exec_cmp(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val1 = vm.regs[dest]
    val2 = vm.regs[src] if mode == 1 else src
    vm.zf = (val1 == val2)
    s_val1 = val1 if val1 < 0x80000000 else val1 - 0x100000000
    s_val2 = val2 if val2 < 0x80000000 else val2 - 0x100000000
    vm.lf = (s_val1 < s_val2)

def exec_delay(vm, offset):
    mode, val, _ = struct.unpack_from('>B B I 3x', vm.ram, offset)
    if mode == 0:
        delay_ms = val
    elif mode == 1:
        delay_ms = vm.regs[val]
    else:
        raise Exception(f"VM Error: Invalid DELAY mode {mode}")
    time.sleep(delay_ms / 1000.0)

def exec_jz(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if getattr(vm, 'zf', False):
        vm.pc = target - 9

def exec_jnz(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if not getattr(vm, 'zf', False):
        vm.pc = target - 9

def exec_jl(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if getattr(vm, 'lf', False):
        vm.pc = target - 9

def exec_syscall(vm, offset):
    ax = vm.regs[0]
    if ax == 0:
        addr = struct.unpack_from('>I', vm.ram, BOOT_STRING_ADDR)[0]
        msg = read_string(vm, addr)
        msg = msg.replace("{AX}", str(vm.regs[0])).replace("{BX}", str(vm.regs[1])).replace("{CX}", str(vm.regs[2])).replace("{DX}", str(vm.regs[3]))
        print(msg)
    elif ax == 1:
        addr = vm.regs[2]
        msg = read_string(vm, addr)
        msg = msg.replace("{AX}", str(vm.regs[0])).replace("{BX}", str(vm.regs[1])).replace("{CX}", str(vm.regs[2])).replace("{DX}", str(vm.regs[3]))
        print(msg)
    elif ax == 2:
        addr = vm.regs[2]
        while True:
            try:
                val = int(input("> ").strip())
                break
            except ValueError:
                print("  [?] Enter a valid integer.")
        if addr + 4 <= len(vm.ram):
            struct.pack_into('>I', vm.ram, addr, val & 0xFFFFFFFF)
        else:
            raise Exception(f"VM Syscall 2 Error: RAM address {addr} out of bounds")
    elif ax == 3:
        # Syscall 3: Open file
        addr = vm.regs[2]
        mode = vm.regs[3]
        filename = read_string(vm, addr)
        mode_str = 'rb' if mode == 0 else 'wb'
        try:
            f = open(filename, mode_str)
            fd = vm.next_fd
            vm.files[fd] = ('file', f)
            vm.next_fd += 1
            vm.regs[0] = fd
        except Exception as e:
            vm.regs[0] = 0xFFFFFFFF  # -1
    elif ax == 4:
        # Syscall 4: Read file/socket
        fd = vm.regs[1]
        buf_addr = vm.regs[2]
        count = vm.regs[3]
        if fd in vm.files:
            try:
                kind, obj = vm.files[fd]
                if kind == 'socket':
                    data = obj.recv(count)
                else:
                    data = obj.read(count)
                bytes_read = len(data)
                vm.ram[buf_addr : buf_addr + bytes_read] = data
                vm.regs[0] = bytes_read
            except Exception as e:
                vm.regs[0] = 0xFFFFFFFF
        else:
            vm.regs[0] = 0xFFFFFFFF
    elif ax == 5:
        # Syscall 5: Write file/socket
        fd = vm.regs[1]
        buf_addr = vm.regs[2]
        count = vm.regs[3]
        if fd in vm.files:
            try:
                kind, obj = vm.files[fd]
                data = bytes(vm.ram[buf_addr : buf_addr + count])
                if kind == 'socket':
                    obj.sendall(data)
                else:
                    obj.write(data)
                    obj.flush()
                vm.regs[0] = count
            except Exception as e:
                vm.regs[0] = 0xFFFFFFFF
        else:
            vm.regs[0] = 0xFFFFFFFF
    elif ax == 6:
        # Syscall 6: Close file/socket
        fd = vm.regs[1]
        if fd in vm.files:
            try:
                kind, obj = vm.files[fd]
                obj.close()
                del vm.files[fd]
                vm.regs[0] = 0
            except Exception as e:
                vm.regs[0] = 0xFFFFFFFF
        else:
            vm.regs[0] = 0xFFFFFFFF
    elif ax == 25:
        sector_num = vm.regs[1]
        try:
            off_val = sector_num * 512
            sector_data = vm.disk_raw[off_val : off_val + 512]
            vm.disk_buffer = bytearray(sector_data.ljust(512, b'\x00'))
            vm.regs[0] = 0  # success
        except Exception as e:
            print(f"VM Syscall 25 Error: {e}")
            vm.regs[0] = 1
    # ========== GUI syscalls (30-36) ==========
    elif ax == 30:
        # gui_init: BX=width, CX=height, DX=title_addr
        _gui_init(vm, vm.regs[1], vm.regs[2], vm.regs[3])
    elif ax == 31:
        # gui_clear: BX=color (0xRRGGBB)
        _gui_clear(vm, vm.regs[1])
    elif ax == 32:
        # gui_draw_rect: BX=packed(x|y), CX=packed(w|h), DX=color
        # We use a shared buffer at a known address for extra params
        # Convention: push x,y,w,h,color,fill to RAM at address in BX
        _gui_draw_rect(vm, vm.regs[1])
    elif ax == 33:
        # gui_draw_line: BX=params_addr (x1,y1,x2,y2,color each 4B)
        _gui_draw_line(vm, vm.regs[1])
    elif ax == 34:
        # gui_draw_text: BX=params_addr (x,y,color,str_addr each 4B)
        _gui_draw_text(vm, vm.regs[1])
    elif ax == 35:
        # gui_poll_event: BX=event_buf_addr -> AX=1 if event, 0 if none
        _gui_poll_event(vm, vm.regs[1])
    elif ax == 36:
        # gui_present: refresh window
        _gui_present(vm)
    # ========== Network syscall (50) ==========
    elif ax == 50:
        # net_connect: CX=host_addr, DX=port -> AX=fd or -1
        host_addr = vm.regs[2]
        port = vm.regs[3]
        hostname = read_string(vm, host_addr)
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(10)
            s.connect((hostname, port))
            fd = vm.next_fd
            vm.files[fd] = ('socket', s)
            vm.next_fd += 1
            vm.regs[0] = fd
        except Exception as e:
            print(f"VM net_connect error: {e}")
            vm.regs[0] = 0xFFFFFFFF
    elif ax == 60:
        if vm.regs[2] == 1:
            print("\nHALTED")
        vm.running = False
    else:
        raise Exception(f"VM Error: Unknown syscall AX={ax}")

# ========== GUI Helper Functions ==========

def _gui_ensure(vm):
    """Lazily initialize Tkinter GUI subsystem on first use."""
    if not hasattr(vm, '_gui') or vm._gui is None:
        import tkinter as tk
        root = tk.Tk()
        root.title("PC VM")
        root.protocol("WM_DELETE_WINDOW", lambda: _gui_on_close(vm))
        canvas = tk.Canvas(root, width=640, height=480, bg='black', highlightthickness=0)
        canvas.pack()
        vm._gui = {
            'root': root,
            'canvas': canvas,
            'width': 640,
            'height': 480,
            'events': [],
            'closed': False,
        }
        # Bind events
        canvas.bind('<Button-1>', lambda e: vm._gui['events'].append((1, e.x, e.y, 0)))
        canvas.bind('<Button-3>', lambda e: vm._gui['events'].append((2, e.x, e.y, 0)))
        root.bind('<KeyPress>', lambda e: vm._gui['events'].append((3, 0, 0, e.keycode if e.keycode else ord(e.char) if e.char else 0)))
        root.bind('<KeyRelease>', lambda e: vm._gui['events'].append((4, 0, 0, e.keycode if e.keycode else 0)))
        canvas.bind('<Motion>', lambda e: vm._gui['events'].append((5, e.x, e.y, 0)))
        root.update()

def _gui_on_close(vm):
    vm._gui['closed'] = True
    vm.running = False
    try:
        vm._gui['root'].destroy()
    except:
        pass

def _color_hex(val):
    r = (val >> 16) & 0xFF
    g = (val >> 8) & 0xFF
    b = val & 0xFF
    return f'#{r:02x}{g:02x}{b:02x}'

def _gui_init(vm, w, h, title_addr):
    import tkinter as tk
    title = read_string(vm, title_addr) if title_addr else "PC VM"
    if hasattr(vm, '_gui') and vm._gui is not None:
        try:
            vm._gui['root'].destroy()
        except:
            pass
        vm._gui = None
    root = tk.Tk()
    root.title(title)
    root.resizable(False, False)
    root.protocol("WM_DELETE_WINDOW", lambda: _gui_on_close(vm))
    canvas = tk.Canvas(root, width=w, height=h, bg='black', highlightthickness=0)
    canvas.pack()
    vm._gui = {
        'root': root,
        'canvas': canvas,
        'width': w,
        'height': h,
        'events': [],
        'closed': False,
    }
    canvas.bind('<Button-1>', lambda e: vm._gui['events'].append((1, e.x, e.y, 0)))
    canvas.bind('<Button-3>', lambda e: vm._gui['events'].append((2, e.x, e.y, 0)))
    root.bind('<KeyPress>', lambda e: vm._gui['events'].append((3, 0, 0, e.keycode if e.keycode else (ord(e.char) if e.char else 0))))
    root.bind('<KeyRelease>', lambda e: vm._gui['events'].append((4, 0, 0, e.keycode if e.keycode else 0)))
    canvas.bind('<Motion>', lambda e: vm._gui['events'].append((5, e.x, e.y, 0)))
    root.update()
    vm.regs[0] = 0

def _gui_clear(vm, color):
    _gui_ensure(vm)
    if vm._gui['closed']:
        return
    c = vm._gui['canvas']
    c.delete('all')
    c.configure(bg=_color_hex(color))

def _gui_draw_rect(vm, params_addr):
    """Read 6 x uint32 from params_addr: x, y, w, h, color, fill"""
    _gui_ensure(vm)
    if vm._gui['closed']:
        return
    x = struct.unpack_from('>I', vm.ram, params_addr)[0]
    y = struct.unpack_from('>I', vm.ram, params_addr + 4)[0]
    w = struct.unpack_from('>I', vm.ram, params_addr + 8)[0]
    h = struct.unpack_from('>I', vm.ram, params_addr + 12)[0]
    color = struct.unpack_from('>I', vm.ram, params_addr + 16)[0]
    fill = struct.unpack_from('>I', vm.ram, params_addr + 20)[0]
    c = vm._gui['canvas']
    col = _color_hex(color)
    if fill:
        c.create_rectangle(x, y, x + w, y + h, fill=col, outline=col)
    else:
        c.create_rectangle(x, y, x + w, y + h, outline=col)

def _gui_draw_line(vm, params_addr):
    """Read 5 x uint32: x1, y1, x2, y2, color"""
    _gui_ensure(vm)
    if vm._gui['closed']:
        return
    x1 = struct.unpack_from('>I', vm.ram, params_addr)[0]
    y1 = struct.unpack_from('>I', vm.ram, params_addr + 4)[0]
    x2 = struct.unpack_from('>I', vm.ram, params_addr + 8)[0]
    y2 = struct.unpack_from('>I', vm.ram, params_addr + 12)[0]
    color = struct.unpack_from('>I', vm.ram, params_addr + 16)[0]
    c = vm._gui['canvas']
    c.create_line(x1, y1, x2, y2, fill=_color_hex(color), width=2)

def _gui_draw_text(vm, params_addr):
    """Read 4 x uint32: x, y, color, str_addr. Optional 5th: font_size"""
    _gui_ensure(vm)
    if vm._gui['closed']:
        return
    x = struct.unpack_from('>I', vm.ram, params_addr)[0]
    y = struct.unpack_from('>I', vm.ram, params_addr + 4)[0]
    color = struct.unpack_from('>I', vm.ram, params_addr + 8)[0]
    str_addr = struct.unpack_from('>I', vm.ram, params_addr + 12)[0]
    # Optional font size at offset 16
    font_size = 12
    if params_addr + 20 <= len(vm.ram):
        fs = struct.unpack_from('>I', vm.ram, params_addr + 16)[0]
        if 6 <= fs <= 72:
            font_size = fs
    text = read_string(vm, str_addr)
    c = vm._gui['canvas']
    c.create_text(x, y, text=text, fill=_color_hex(color), anchor='nw', font=('Consolas', font_size))

def _gui_poll_event(vm, event_buf_addr):
    """Pop one event from queue and write to buf: type(4B), x(4B), y(4B), key(4B). AX=1 if event, 0 if empty."""
    _gui_ensure(vm)
    if vm._gui['closed']:
        vm.regs[0] = 0
        return
    # Process pending Tkinter events
    try:
        vm._gui['root'].update_idletasks()
        vm._gui['root'].update()
    except:
        vm._gui['closed'] = True
        vm.regs[0] = 0
        return
    if vm._gui['events']:
        ev = vm._gui['events'].pop(0)
        struct.pack_into('>I', vm.ram, event_buf_addr, ev[0])      # type
        struct.pack_into('>I', vm.ram, event_buf_addr + 4, ev[1])   # x
        struct.pack_into('>I', vm.ram, event_buf_addr + 8, ev[2])   # y
        struct.pack_into('>I', vm.ram, event_buf_addr + 12, ev[3])  # key
        vm.regs[0] = 1
    else:
        vm.regs[0] = 0

def _gui_present(vm):
    """Flush all pending draw calls and refresh the window."""
    _gui_ensure(vm)
    if vm._gui['closed']:
        return
    try:
        vm._gui['root'].update_idletasks()
        vm._gui['root'].update()
    except:
        vm._gui['closed'] = True

def exec_sub(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] - val) & 0xFFFFFFFF

def exec_mul(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] * val) & 0xFFFFFFFF

def exec_div(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    if val == 0:
        raise Exception("VM Error: Division by zero")
    vm.regs[dest] = (vm.regs[dest] // val) & 0xFFFFFFFF

def exec_mod(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    if val == 0:
        raise Exception("VM Error: Division by zero (modulo)")
    vm.regs[dest] = (vm.regs[dest] % val) & 0xFFFFFFFF

def exec_and(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] & val) & 0xFFFFFFFF

def exec_or(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] | val) & 0xFFFFFFFF

def exec_xor(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] ^ val) & 0xFFFFFFFF

def exec_shl(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] << (val & 31)) & 0xFFFFFFFF

def exec_shr(vm, offset):
    mode, dest, src, _ = struct.unpack_from('>B H I B', vm.ram, offset)
    val = vm.regs[src] if mode == 1 else src
    vm.regs[dest] = (vm.regs[dest] >> (val & 31)) & 0xFFFFFFFF

def exec_push(vm, offset):
    mode, val = struct.unpack_from('>B I 3x', vm.ram, offset)
    push_val = vm.regs[val] if mode == 1 else val
    vm.regs[4] = (vm.regs[4] - 4) & 0xFFFFFFFF
    sp = vm.regs[4]
    if sp + 4 <= len(vm.ram):
        struct.pack_into('>I', vm.ram, sp, push_val & 0xFFFFFFFF)
    else:
        raise Exception(f"VM Error: Stack overflow / out of memory at SP=0x{sp:X}")

def exec_pop(vm, offset):
    reg = struct.unpack_from('>B 7x', vm.ram, offset)[0]
    sp = vm.regs[4]
    if sp + 4 <= len(vm.ram):
        vm.regs[reg] = struct.unpack_from('>I', vm.ram, sp)[0]
        vm.regs[4] = (vm.regs[4] + 4) & 0xFFFFFFFF
    else:
        raise Exception(f"VM Error: Stack underflow / out of memory at SP=0x{sp:X}")

def exec_call(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    ret_addr = vm.pc + 9
    vm.regs[4] = (vm.regs[4] - 4) & 0xFFFFFFFF
    sp = vm.regs[4]
    if sp + 4 <= len(vm.ram):
        struct.pack_into('>I', vm.ram, sp, ret_addr & 0xFFFFFFFF)
        vm.pc = target - 9
    else:
        raise Exception("VM Error: Stack overflow on CALL")

def exec_ret(vm, offset):
    sp = vm.regs[4]
    if sp + 4 <= len(vm.ram):
        ret_addr = struct.unpack_from('>I', vm.ram, sp)[0]
        vm.regs[4] = (vm.regs[4] + 4) & 0xFFFFFFFF
        vm.pc = ret_addr - 9
    else:
        raise Exception("VM Error: Stack underflow on RET")

def exec_jg(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if not vm.zf and not vm.lf:
        vm.pc = target - 9

def exec_jge(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if not vm.lf:
        vm.pc = target - 9

def exec_jle(vm, offset):
    target = struct.unpack_from('>Q', vm.ram, offset)[0]
    if vm.lf or vm.zf:
        vm.pc = target - 9

def exec_not(vm, offset):
    reg = struct.unpack_from('>B 7x', vm.ram, offset)[0]
    if reg < len(vm.regs):
        vm.regs[reg] = (~vm.regs[reg]) & 0xFFFFFFFF

def exec_neg(vm, offset):
    reg = struct.unpack_from('>B 7x', vm.ram, offset)[0]
    if reg < len(vm.regs):
        vm.regs[reg] = (-vm.regs[reg]) & 0xFFFFFFFF

def exec_inc(vm, offset):
    reg = struct.unpack_from('>B 7x', vm.ram, offset)[0]
    if reg < len(vm.regs):
        vm.regs[reg] = (vm.regs[reg] + 1) & 0xFFFFFFFF

def exec_dec(vm, offset):
    reg = struct.unpack_from('>B 7x', vm.ram, offset)[0]
    if reg < len(vm.regs):
        vm.regs[reg] = (vm.regs[reg] - 1) & 0xFFFFFFFF

# Compilation helper functions

def compile_mov(opcode, cmd, args, labels):
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"{cmd}: Za malo parametrow: {args}")
    
    op1_str = parts[0].upper()
    op2_str = parts[1].upper()
    
    op1_is_reg = op1_str in REG_MAP
    op2_is_reg = op2_str in REG_MAP
    
    if op1_is_reg and op2_is_reg:
        # Register to Register: Mode = 2
        mode = 2
        dest = REG_MAP[op1_str]
        src = REG_MAP[op2_str]
    elif op1_is_reg:
        # Immediate to Register (Intel style): Mode = 0
        mode = 0
        dest = REG_MAP[op1_str]
        src_raw = parts[1]
        if src_raw in labels:
            src = labels[src_raw]
        else:
            try:
                src = int(src_raw, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieznany symbol lub wartosc '{src_raw}'")
    elif op2_is_reg:
        # Immediate to Register (AT&T style / typo fallback): Mode = 0
        mode = 0
        dest = REG_MAP[op2_str]
        src_raw = parts[0]
        if src_raw in labels:
            src = labels[src_raw]
        else:
            try:
                src = int(src_raw, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieznany symbol lub wartosc '{src_raw}'")
    else:
        # Memory destination, Immediate source: Mode = 1
        mode = 1
        dest_str = parts[0]
        if dest_str.isdigit():
            raise Exception(f"{cmd} ERROR: Memory address '{dest_str}' must be in hexadecimal format (e.g. '0x{int(dest_str):04X}') or a named label.")
        try:
            dest = int(dest_str, 0)
        except ValueError:
            raise Exception(f"{cmd}: Nieprawidlowy adres celowy '{dest_str}'")
            
        src_raw = parts[1]
        if src_raw in labels:
            src = labels[src_raw]
        else:
            try:
                src = int(src_raw, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieznany symbol lub wartosc '{src_raw}'")
                
    return struct.pack('>B B H I B', opcode, mode, dest, src, 0)

def compile_bin_op(opcode, cmd, args, labels):
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"{cmd}: Za malo parametrow: {args}")
    dest_str = parts[0].upper()
    src_str = parts[1].upper()
    
    if dest_str not in REG_MAP:
        raise Exception(f"{cmd}: Pierwszy argument musi byc rejestrem: {dest_str}")
    dest = REG_MAP[dest_str]
    
    if src_str in REG_MAP:
        mode = 1
        src = REG_MAP[src_str]
    else:
        mode = 0
        src_raw = parts[1]
        if src_raw in labels:
            src = labels[src_raw]
        else:
            try:
                src = int(src_raw, 0) & 0xFFFFFFFF
            except ValueError:
                raise Exception(f"{cmd}: Nieznana wartosc lub symbol '{src_raw}'")
    return struct.pack('>B B H I B', opcode, mode, dest, src, 0)

def compile_jmp_like(opcode, cmd, args, labels):
    if not args:
        raise Exception(f"{cmd}: Brak parametru adresu/etykiety")
    label = args[0].strip()
    if label in labels:
        addr = labels[label]
    else:
        try:
            addr = int(label, 0)
        except ValueError:
            raise Exception(f"{cmd}: Nieznany symbol lub adres '{label}'")
    return struct.pack('>B Q', opcode, addr)

def compile_no_args(opcode, cmd, args, labels):
    return struct.pack('>B 8x', opcode)

def compile_mem_op(opcode, cmd, args, labels):
    arg_str = " ".join(args).replace(",", " ").strip()
    parts = arg_str.split()
    if len(parts) < 2:
        raise Exception(f"{cmd}: Za malo parametrow: {args}")
    reg_str = parts[0].upper()
    addr_str = "".join(parts[1:])
    
    if reg_str not in REG_MAP:
        raise Exception(f"{cmd}: Nieprawidlowy rejestr '{reg_str}'")
    reg = REG_MAP[reg_str]
    
    if addr_str.startswith('[') and addr_str.endswith(']'):
        content = addr_str[1:-1].strip()
        if '+' in content:
            r_str, off_str = content.split('+', 1)
            r_str = r_str.strip().upper()
            off_str = off_str.strip()
            if r_str not in REG_MAP:
                raise Exception(f"{cmd}: Nieprawidlowy rejestr w adresowaniu posrednim '{r_str}'")
            try:
                offset = int(off_str, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieprawidlowa wartosc przesuniecia '{off_str}'")
            mode = 2
            addr_val = (REG_MAP[r_str] << 24) | (offset & 0xFFFFFF)
        elif '-' in content:
            r_str, off_str = content.split('-', 1)
            r_str = r_str.strip().upper()
            off_str = off_str.strip()
            if r_str not in REG_MAP:
                raise Exception(f"{cmd}: Nieprawidlowy rejestr w adresowaniu posrednim '{r_str}'")
            try:
                offset = -int(off_str, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieprawidlowa wartosc przesuniecia '{off_str}'")
            mode = 2
            addr_val = (REG_MAP[r_str] << 24) | (offset & 0xFFFFFF)
        else:
            r_str = content.upper()
            if r_str not in REG_MAP:
                # If not a register, treat [label] or [0x1000] as absolute addressing (mode 0)
                if content in labels or content.startswith('0x') or content.startswith('0X') or content.isdigit():
                    mode = 0
                    if content in labels:
                        addr_val = labels[content]
                    else:
                        addr_val = int(content, 0)
                else:
                    raise Exception(f"{cmd}: Nieprawidlowy rejestr lub nieznany symbol w adresowaniu posrednim '{content}'")
            else:
                mode = 1
                addr_val = REG_MAP[r_str]
    else:
        mode = 0
        if addr_str in labels:
            addr_val = labels[addr_str]
        else:
            if addr_str.isdigit():
                raise Exception(f"{cmd} ERROR: Memory address '{addr_str}' must be in hexadecimal format (e.g. '0x{int(addr_str):04X}') or a named label.")
            try:
                addr_val = int(addr_str, 0)
            except ValueError:
                raise Exception(f"{cmd}: Nieznany symbol lub adres '{addr_str}'")
                
    return struct.pack('>B B I B 2x', opcode, reg, addr_val, mode)

def compile_push(opcode, cmd, args, labels):
    if not args:
        raise Exception(f"{cmd}: Brak parametru")
    arg_str = " ".join(args).strip()
    val_str = arg_str.upper()
    if val_str in REG_MAP:
        mode = 1
        val = REG_MAP[val_str]
    else:
        mode = 0
        if arg_str in labels:
            val = labels[arg_str]
        else:
            try:
                val = int(arg_str, 0) & 0xFFFFFFFF
            except ValueError:
                raise Exception(f"{cmd}: Nieznana wartosc, rejestr lub symbol '{arg_str}'")
    return struct.pack('>B B I 3x', opcode, mode, val)

def compile_unary_reg(opcode, cmd, args, labels):
    if not args:
        raise Exception(f"{cmd}: Brak rejestru docelowego")
    arg_str = " ".join(args).strip().upper()
    if arg_str not in REG_MAP:
        raise Exception(f"{cmd}: Nieprawidlowy rejestr '{arg_str}'")
    reg = REG_MAP[arg_str]
    return struct.pack('>B B 7x', opcode, reg)

def compile_delay(opcode, cmd, args, labels):
    if not args:
        raise Exception(f"{cmd}: Brak parametru")
    arg_str = " ".join(args).strip().upper()
    if arg_str in REG_MAP:
        mode = 1
        val = REG_MAP[arg_str]
    else:
        mode = 0
        try:
            val = int(arg_str, 0)
        except ValueError:
            raise Exception(f"{cmd}: Nieprawidlowa wartosc czasu '{arg_str}'")
    return struct.pack('>B B I 3x', opcode, mode, val)

INSTRUCTION_SET = {
    'MOV': (1, compile_mov, exec_mov),
    'CMP': (2, compile_bin_op, exec_cmp),
    'JMP': (3, compile_jmp_like, exec_jmp),
    'JZ': (4, compile_jmp_like, exec_jz),
    'JNZ': (5, compile_jmp_like, exec_jnz),
    'SYSCALL': (6, compile_no_args, exec_syscall),
    'STORE': (7, compile_mem_op, exec_store),
    'LOAD': (8, compile_mem_op, exec_load),
    'ADD': (9, compile_bin_op, exec_add),
    'JL': (10, compile_jmp_like, exec_jl),
    'SUB': (11, compile_bin_op, exec_sub),
    'MUL': (12, compile_bin_op, exec_mul),
    'DIV': (13, compile_bin_op, exec_div),
    'AND': (14, compile_bin_op, exec_and),
    'OR': (15, compile_bin_op, exec_or),
    'XOR': (16, compile_bin_op, exec_xor),
    'NOT': (17, compile_unary_reg, exec_not),
    'SHL': (18, compile_bin_op, exec_shl),
    'SHR': (19, compile_bin_op, exec_shr),
    'DELAY': (20, compile_delay, exec_delay),
    'PUSH': (21, compile_push, exec_push),
    'POP': (22, compile_unary_reg, exec_pop),
    'CALL': (23, compile_jmp_like, exec_call),
    'RET': (24, compile_no_args, exec_ret),
    'JG': (25, compile_jmp_like, exec_jg),
    'JGE': (26, compile_jmp_like, exec_jge),
    'JLE': (27, compile_jmp_like, exec_jle),
    'NEG': (28, compile_unary_reg, exec_neg),
    'INC': (29, compile_unary_reg, exec_inc),
    'DEC': (30, compile_unary_reg, exec_dec),
    'MOD': (31, compile_bin_op, exec_mod),
    'LOAD_B': (32, compile_mem_op, exec_load_b),
    'STORE_B': (33, compile_mem_op, exec_store_b),
}