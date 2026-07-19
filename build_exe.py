"""
build_exe.py — pakuje vm.py + obraz dysku (.ds) w jeden plik .exe
Wymaga: pip install pyinstaller

Użycie:
    python build_exe.py                     # pakuje disk.ds (domyślny)
    python build_exe.py moj_program.ds      # pakuje wskazany obraz
    python build_exe.py moj_program.ds MyApp # własna nazwa exe
"""

import sys
import os
import subprocess
import struct
import shutil
import tempfile

def main():
    # ---- argumenty ----
    ds_file = sys.argv[1] if len(sys.argv) > 1 else "disk.ds"
    if not os.path.exists(ds_file):
        print(f"[ERROR] Nie znaleziono pliku dysku: {ds_file}")
        sys.exit(1)

    app_name = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(ds_file)[0]

    print(f"===========================")
    print(f"  PC Build to .exe")
    print(f"===========================")
    print(f"  Disk image : {ds_file}")
    print(f"  Output exe : {app_name}.exe")
    print()

    # ---- odczytaj obraz dysku ----
    with open(ds_file, 'rb') as f:
        disk_data = f.read()

    print(f"  Disk size  : {len(disk_data)} bytes ({len(disk_data) // 512} sectors)")

    # ---- katalog roboczy ----
    build_dir = tempfile.mkdtemp(prefix="pcvm_build_")
    print(f"  Build dir  : {build_dir}")

    # ---- skopiuj vm.py i op.py do katalogu roboczego ----
    base_dir = os.path.dirname(os.path.abspath(__file__))
    for fname in ['vm.py', 'op.py', 'conf_vm.toml']:
        src = os.path.join(base_dir, fname)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(build_dir, fname))

    # ---- wbuduj dane dysku jako moduł Python ----
    disk_hex = disk_data.hex()
    embedded_vm = f'''"""
Wbudowany runner VM — wygenerowany automatycznie przez build_exe.py
Disk image: {ds_file}
"""
import sys
import os
import struct
import tempfile

# Wbudowany obraz dysku (hex)
_DISK_HEX = "{disk_hex}"

def get_disk_bytes():
    return bytes.fromhex(_DISK_HEX)

# ---- uruchom VM z wbudowanym dyskiem ----
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import op
    import vm as vm_module
except ImportError as e:
    print(f"[ERROR] Brak modulu VM: {{e}}")
    sys.exit(1)

class EmbeddedVM(vm_module.VM):
    def __init__(self, cli_args):
        self._cli_args = cli_args
        self._init_from_bytes(get_disk_bytes())

    def _init_from_bytes(self, raw):
        import op
        config = op.load_config()
        ram_size     = config.get('vm', {{}}).get('ram_size', 65536)
        sp_start     = config.get('vm', {{}}).get('sp_start', 65536)

        self.disk_file = "<embedded>"
        self.ram = bytearray(ram_size)
        self.regs = [0] * 6
        self.regs[4] = sp_start   # SP

        self.pc = struct.unpack('>I', raw[0:4])[0]
        binary_data = raw[4:]
        self.ram[:len(binary_data)] = binary_data
        self.disk_raw = raw[4:]

        self.running = True
        self.zf = False
        self.lf = False
        self.disk_buffer = bytearray(512)

        self.files = {{}}
        self.next_fd = 3

        # Wpisz argumenty CLI do RAM
        binary_end = len(binary_data)
        arg_start = (binary_end + 255) & ~255
        argc = len(self._cli_args)
        argv_ptrs = []
        curr_addr = arg_start + (argc * 4) + 4

        for arg in self._cli_args:
            arg_bytes = arg.encode('utf-8') + b'\\x00'
            if curr_addr + len(arg_bytes) <= len(self.ram):
                self.ram[curr_addr : curr_addr + len(arg_bytes)] = arg_bytes
                argv_ptrs.append(curr_addr)
                curr_addr += len(arg_bytes)

        for idx, ptr in enumerate(argv_ptrs):
            struct.pack_into('>I', self.ram, arg_start + idx * 4, ptr)
        struct.pack_into('>I', self.ram, arg_start + argc * 4, 0)

        self.regs[0] = argc
        self.regs[1] = arg_start

        self.dispatch = {{info[0]: info[2] for info in op.INSTRUCTION_SET.values()}}

if __name__ == "__main__":
    cli_args = sys.argv[1:]
    v = EmbeddedVM(cli_args)
    v.run()
'''

    runner_path = os.path.join(build_dir, 'runner.py')
    with open(runner_path, 'w', encoding='utf-8') as f:
        f.write(embedded_vm)

    print("  Runner script created.")

    # ---- PyInstaller ----
    pyinstaller_cmd = [
        sys.executable, '-m', 'PyInstaller',
        '--onefile',
        '--name', app_name,
        '--distpath', os.path.join(base_dir, 'dist'),
        '--workpath', os.path.join(build_dir, 'work'),
        '--specpath', os.path.join(build_dir, 'spec'),
        '--noconfirm',
        '--add-data', f'{os.path.join(build_dir, "op.py")}{os.pathsep}.',
        '--add-data', f'{os.path.join(build_dir, "vm.py")}{os.pathsep}.',
        '--add-data', f'{os.path.join(build_dir, "conf_vm.toml")}{os.pathsep}.',
        runner_path,
    ]

    print(f"  Running PyInstaller...")
    print()

    result = subprocess.run(pyinstaller_cmd, capture_output=False)

    if result.returncode == 0:
        exe_path = os.path.join(base_dir, 'dist', f'{app_name}.exe')
        if os.path.exists(exe_path):
            size_mb = os.path.getsize(exe_path) / (1024 * 1024)
            print()
            print(f"  [OK] Zbudowano: {exe_path}")
            print(f"       Rozmiar  : {size_mb:.1f} MB")
            print()
            print(f"  Uruchomienie:")
            print(f"    {exe_path}")
            print(f"    {exe_path} arg1 arg2   (z argumentami)")
        else:
            print(f"  [WARN] PyInstaller zakończył się sukcesem, ale exe nie znaleziono w dist/")
    else:
        print(f"  [ERROR] PyInstaller zakończył się błędem (code {result.returncode})")
        print(f"          Sprawdź logi powyżej.")

    # ---- sprzątanie ----
    shutil.rmtree(build_dir, ignore_errors=True)

if __name__ == "__main__":
    main()
