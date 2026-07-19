import os
import sys
import subprocess
import shutil

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
SKETCH       = os.path.join(SCRIPT_DIR, "ard", "main")
DEFAULT_BOARD        = "arduino:avr:uno"
DEFAULT_PORT         = "COM3"

def find_arduino_cli():
    """Find arduino-cli executable in PATH or common install locations."""
    # Try PATH first
    cli = shutil.which("arduino-cli")
    if cli:
        return cli
    # Common Windows install locations
    candidates = [
        r"C:\Users\neon\AppData\Local\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe",
        r"C:\Program Files\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe",
        r"C:\Program Files (x86)\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe",
        os.path.expanduser(r"~\AppData\Local\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"),
        # arduino-cli standalone
        r"C:\Program Files\arduino-cli\arduino-cli.exe",
        os.path.expanduser(r"~\scoop\shims\arduino-cli.exe"),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return "arduino-cli"  # fallback, will fail with a useful error

ARDUINO_CLI = find_arduino_cli()

def run(cmd):
    print(">", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("[ERROR] Command failed")
        sys.exit(1)

def upload(ds_path, port=None, board=None):
    if not port:
        port = DEFAULT_PORT
    if not board:
        board = DEFAULT_BOARD
        
    disk_h_path  = os.path.join(SKETCH, "disk.h")
    
    if not os.path.exists(ds_path):
        print(f"[ERROR] {ds_path} not found.")
        sys.exit(1)

    print(f"[1] Reading {ds_path}...")
    with open(ds_path, 'r', encoding='utf-8') as f:
        content = f.read().strip()

    # Convert binary bits string (0s and 1s) to bytes
    disk_bytes_list = []
    for i in range(0, len(content), 8):
        byte_str = content[i:i+8]
        if len(byte_str) == 8:
            disk_bytes_list.append(int(byte_str, 2))
    disk_bytes = bytes(disk_bytes_list)
    print(f"    {len(disk_bytes)} bytes")

    # Generate disk.h
    print(f"[2] Writing {disk_h_path}...")
    os.makedirs(SKETCH, exist_ok=True)
    with open(disk_h_path, 'w', encoding='utf-8') as f:
        f.write("#ifndef DISK_H\n#define DISK_H\n\n#include <avr/pgmspace.h>\n\n")
        f.write(f"// Generated from {os.path.basename(ds_path)} ({len(disk_bytes)} bytes)\n")
        f.write("const uint8_t disk_image[] PROGMEM = {\n")
        for i in range(0, len(disk_bytes), 16):
            chunk = disk_bytes[i:i+16]
            f.write("    " + ", ".join(f"0x{b:02X}" for b in chunk) + ",\n")
        f.write("};\n\n#endif // DISK_H\n")
    print("    disk.h ready")

    # Compile sketch
    print("\n[3] Compiling sketch...")
    run([ARDUINO_CLI, "compile", "--fqbn", board, SKETCH])

    # Upload sketch
    print("\n[4] Uploading sketch...")
    run([ARDUINO_CLI, "upload", "--fqbn", board, "--port", port, SKETCH])

    print("\n[OK] Done!")
