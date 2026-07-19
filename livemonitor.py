#!/usr/bin/env python3
"""
livemonitor.py — Live Interactive LCD Monitor for Arduino VM
Automatycznie kompiluje live_editor.c, wgrywa na Arduino
i uruchamia interaktywny terminal z obsługą klawiatury na żywo (msvcrt).

Obsługa klawiszy:
  - Wpisywane litery pojawiają się na LCD w czasie rzeczywistym
  - Strzałki GÓRA/DÓŁ: nawigacja między liniami 0 i 1
  - Strzałki LEWO/PRAWO: przesunięcie kursora w linii
  - Backspace: usuwanie znaku
  - Kursor to biały prostokąt (0xFF) generowany przez VM
"""

import os
import sys
import time
import subprocess
import threading

try:
    import serial
except ImportError:
    print("[ERROR] pyserial not installed. Run: pip install pyserial")
    sys.exit(1)

try:
    import msvcrt
    HAS_MSVCRT = True
except ImportError:
    HAS_MSVCRT = False

# Konfiguracja domyślna
PORT = "COM3"
BOARD = "arduino:avr:uno"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIVE_EDITOR_C = os.path.join(SCRIPT_DIR, "live_editor.c")
LIVE_EDITOR_DS = os.path.join(SCRIPT_DIR, "live_editor.ds")

# Parse --port and --board from args
import argparse
parser = argparse.ArgumentParser(description='livemonitor.py - live LCD editor')
parser.add_argument('--port', default='COM3', help='Serial port (default: COM3)')
parser.add_argument('--board', default='arduino:avr:uno', help='Arduino FQBN')
parser.add_argument('--no-upload', action='store_true', help='Skip compile & upload')
CLI_ARGS, _ = parser.parse_known_args()
PORT = CLI_ARGS.port
BOARD = CLI_ARGS.board

# Kolory ANSI
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RED = "\033[31m"
BLUE = "\033[34m"

def log(color, msg):
    print(f"{color}{msg}{RESET}")

def compile_and_upload():
    log(BOLD, "\n=== 1. KOMPILACJA I WGRYWANIE KODU ===")
    log(CYAN, f"Kompilowanie i wgrywanie {LIVE_EDITOR_C}...")
    
    compile_cmd = [
        sys.executable, "ardc.py",
        LIVE_EDITOR_C,
        "--upload",
        "--port", PORT,
        "--board", BOARD,
    ]
    res = subprocess.run(compile_cmd)
    if res.returncode != 0:
        log(RED, "Blad kompilacji lub wgrywania!")
        sys.exit(1)
    log(GREEN, "VM z edytorem gotowa na Arduino!\n")

def read_serial_loop(ser, stop_event):
    """Odczytuje pakiety z Arduino i wyświetla je w terminalu."""
    buf = b""
    while not stop_event.is_set():
        if ser.in_waiting > 0:
            try:
                data = ser.read(ser.in_waiting)
                buf += data
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    decoded = line.decode('utf-8', errors='replace').strip()
                    if decoded.startswith("@LCD0|"):
                        print(f"\r  Line 0: [{decoded[6:]:16}]", end="", flush=True)
                    elif decoded.startswith("@LCD1|"):
                        print(f"\r  Line 1: [{decoded[6:]:16}]", end="", flush=True)
                    elif decoded.startswith("@PRINT|"):
                        print(f"\n  [Serial] {decoded[7:]}")
                    elif decoded.startswith("@HALT|"):
                        print(f"\n  [VM] Zakończono edycję (Exit: {decoded[6:]})")
            except Exception as e:
                pass
        time.sleep(0.01)

def run_interactive_monitor():
    log(BOLD, "=== 2. INTERAKTYWNY LIVE MONITOR ===")
    log(YELLOW, "Otwieranie portu COM...")
    
    try:
        ser = serial.Serial(PORT, 9600, timeout=0.1)
        time.sleep(2) # restart Arduino po nawiązaniu połączenia
        ser.reset_input_buffer()
        log(GREEN, "Połączono! Zaczynamy wpisywanie na żywo.")
        log(CYAN, "Sterowanie:\n  - Pisz normalnie na klawiaturze\n  - Strzałki: nawigacja\n  - Backspace: usuwanie\n  - Ctrl+C lub Esc: Wyjście\n")
    except Exception as e:
        log(RED, f"Błąd połączenia z portem {PORT}: {e}")
        sys.exit(1)

    stop_event = threading.Event()
    reader_thread = threading.Thread(target=read_serial_loop, args=(ser, stop_event), daemon=True)
    reader_thread.start()

    # Drukowanie początkowego wyglądu LCD
    print("\n  LCD Emulator (w terminalu):")
    print("  Line 0: [                ]")
    print("  Line 1: [                ]\n")

    try:
        if not HAS_MSVCRT:
            log(RED, "MSVCRT niedostępny na tej platformie. Live input wymaga systemu Windows.")
            return

        while True:
            if msvcrt.kbhit():
                ch = msvcrt.getch()
                
                # Obsługa klawiszy specjalnych (strzałki wysyłają sekwencje dwubajtowe)
                if ch in (b'\xe0', b'\x00'):
                    ch2 = msvcrt.getch()
                    # Strzałki
                    if ch2 == b'H':   # UP
                        ser.write(bytes([128]))
                    elif ch2 == b'P': # DOWN
                        ser.write(bytes([129]))
                    elif ch2 == b'K': # LEFT
                        ser.write(bytes([130]))
                    elif ch2 == b'M': # RIGHT
                        ser.write(bytes([131]))
                
                elif ch == b'\x1b': # Esc
                    break
                    
                elif ch == b'\x08': # Backspace
                    ser.write(bytes([8]))
                    
                elif ch == b'\r': # Enter -> nowa linia
                    # Przejdź do drugiej linii lub wyczyść
                    ser.write(bytes([13]))
                    
                else:
                    # Zwykłe znaki ASCII
                    try:
                        ascii_val = ord(ch.decode('ascii'))
                        if 32 <= ascii_val < 127:
                            ser.write(bytes([ascii_val]))
                    except UnicodeDecodeError:
                        pass
            time.sleep(0.01)

    except KeyboardInterrupt:
        pass
    finally:
        stop_event.set()
        ser.close()
        log(YELLOW, "\nPołączenie zamknięte. Koniec monitora.")

if __name__ == "__main__":
    if not CLI_ARGS.no_upload:
        compile_and_upload()
    run_interactive_monitor()
