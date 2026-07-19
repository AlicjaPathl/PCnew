#!/usr/bin/env python3
"""
ardpy.py — Python host for PC-VM Arduino
Komunikuje się z Arduino przez Serial.
Wyświetla output VM, relayuje LCD pakiety, i umożliwia wysyłanie komend.

Protokół pakietów od Arduino:
  @LCD0|text        → wiersz 0 LCD (wyświetl w terminalu)
  @LCD1|text        → wiersz 1 LCD
  @CLR|             → wyczyść LCD
  @BOOT|text        → komunikat bootowania
  @BLON|            → backlight włączony
  @BLOFF|           → backlight wyłączony
  @PRINT|text       → zwykły print (bez LCD)
  @HALT|code        → VM zatrzymane
  @PONG|            → odpowiedź na @PING

Komendy do wysłania na Arduino (stdin lub --cmd):
  @RESET            → restart VM
  @PING             → test połączenia

Użycie:
  python ardpy.py                         # monitor (domyślny port COM3, 9600)
  python ardpy.py --port COM5             # inny port
  python ardpy.py --port COM3 --baud 115200
  python ardpy.py --port COM3 --cmd "@RESET"
  python ardpy.py --port COM3 --no-lcd   # bez rysowania LCD w terminalu
"""

import sys
import os
import time
import threading
import argparse

try:
    import serial
    import serial.tools.list_ports
    HAS_SERIAL = True
except ImportError:
    HAS_SERIAL = False


# ─── ANSI colors ──────────────────────────────────────────────────────────────

RESET  = '\033[0m'
BOLD   = '\033[1m'
GREEN  = '\033[32m'
CYAN   = '\033[36m'
YELLOW = '\033[33m'
RED    = '\033[31m'
BLUE   = '\033[34m'
MAGENTA = '\033[35m'
DIM    = '\033[2m'


def supports_ansi():
    """Check if terminal supports ANSI colors."""
    return sys.platform != 'win32' or os.environ.get('TERM') or os.environ.get('WT_SESSION')


USE_COLOR = supports_ansi()

def c(color, text):
    return f"{color}{text}{RESET}" if USE_COLOR else text


# ─── LCD Emulator in terminal ──────────────────────────────────────────────────

class LCDEmulator:
    """Renders a 16x2 LCD display in the terminal."""
    
    def __init__(self, cols=16, rows=2):
        self.cols = cols
        self.rows = rows
        self.lines = [''] * rows
        self._last_render = None
    
    def set_line(self, row, text):
        if 0 <= row < self.rows:
            self.lines[row] = text[:self.cols]
    
    def clear(self):
        self.lines = [''] * self.rows
    
    def render(self):
        """Render LCD to terminal string."""
        top    = '+' + '-' * self.cols + '+'
        bottom = '+' + '-' * self.cols + '+'
        rows = []
        for line in self.lines:
            padded = (line + ' ' * self.cols)[:self.cols]
            rows.append('|' + padded + '|')
        
        rendered = f"\n  {top}\n"
        for r in rows:
            rendered += f"  {r}\n"
        rendered += f"  {bottom}\n"
        return rendered
    
    def print(self):
        """Print LCD to terminal (only if changed)."""
        rendered = self.render()
        if rendered != self._last_render:
            print(c(CYAN, rendered), end='')
            self._last_render = rendered


# ─── Packet parser ─────────────────────────────────────────────────────────────

class PacketHandler:
    """Parses and handles @CMD|data packets from Arduino."""
    
    def __init__(self, lcd: LCDEmulator, show_lcd=True):
        self.lcd = lcd
        self.show_lcd = show_lcd
        self.halted = False
        self.halt_code = 0
    
    def handle(self, line: str):
        """Process one line from Arduino serial."""
        line = line.strip()
        
        if not line:
            return
        
        # Packet format: @CMD|data
        if line.startswith('@'):
            sep = line.find('|')
            if sep == -1:
                cmd = line[1:]
                data = ''
            else:
                cmd = line[1:sep]
                data = line[sep+1:]
            self._dispatch(cmd, data)
        else:
            # Raw debug output (not a packet)
            print(c(DIM, f"  [raw] {line}"))
    
    def _dispatch(self, cmd, data):
        if cmd == 'LCD0':
            self.lcd.set_line(0, data)
            if self.show_lcd:
                self.lcd.print()
            print(c(GREEN, f"  LCD[0]: {data}"))
        
        elif cmd == 'LCD1':
            self.lcd.set_line(1, data)
            if self.show_lcd:
                self.lcd.print()
            print(c(GREEN, f"  LCD[1]: {data}"))
        
        elif cmd == 'CLR':
            self.lcd.clear()
            if self.show_lcd:
                self.lcd.print()
            print(c(YELLOW, "  LCD: cleared"))
        
        elif cmd == 'BOOT':
            self.lcd.set_line(0, data)
            self.lcd.set_line(1, '')
            if self.show_lcd:
                self.lcd.print()
            print(c(BLUE, f"  BOOT: {data}"))
        
        elif cmd == 'BLON':
            print(c(YELLOW, "  LCD: backlight ON"))
        
        elif cmd == 'BLOFF':
            print(c(YELLOW, "  LCD: backlight OFF"))
        
        elif cmd == 'CURSOR':
            print(c(DIM, f"  LCD cursor: {data}"))
        
        elif cmd == 'CHAR':
            print(c(DIM, f"  LCD char: '{data}'"))
        
        elif cmd == 'SCRL':
            print(c(DIM, f"  LCD scroll: {data}"))
        
        elif cmd == 'PRINT':
            print(c(RESET, f"  {data}"))
        
        elif cmd == 'HALT':
            self.halted = True
            try:
                self.halt_code = int(data)
            except:
                self.halt_code = 0
            print(c(RED if self.halt_code else GREEN,
                    f"\n  {'*** VM HALTED (error)' if self.halt_code else '✓ VM finished'}"
                    f" (exit code {self.halt_code})\n"))
        
        elif cmd == 'PONG':
            print(c(GREEN, "  Arduino: PONG (connection OK)"))
        
        else:
            print(c(DIM, f"  [{cmd}] {data}"))


# ─── Serial monitor ────────────────────────────────────────────────────────────

class ArduinoMonitor:
    """Reads from Arduino serial, handles packets, allows sending commands."""
    
    def __init__(self, port, baud=9600, show_lcd=True, timeout=None):
        self.port = port
        self.baud = baud
        self.show_lcd = show_lcd
        self.timeout = timeout
        self.ser = None
        self.lcd = LCDEmulator()
        self.handler = PacketHandler(self.lcd, show_lcd)
        self._stop = threading.Event()
    
    def connect(self):
        if not HAS_SERIAL:
            print(c(RED, "ERROR: pyserial not installed. Run: pip install pyserial"))
            sys.exit(1)
        
        print(c(BOLD, f"\n  ardpy.py — Arduino Serial Monitor"))
        print(c(DIM,  f"  Port: {self.port}  Baud: {self.baud}"))
        print(c(DIM,  f"  Press Ctrl+C to exit\n"))
        
        try:
            self.ser = serial.Serial(self.port, self.baud, timeout=0.1)
            time.sleep(2)  # Arduino resets on serial connect
            print(c(GREEN, f"  Connected to {self.port}"))
        except serial.SerialException as e:
            print(c(RED, f"  ERROR: Cannot open {self.port}: {e}"))
            self._suggest_ports()
            sys.exit(1)
    
    def _suggest_ports(self):
        ports = list(serial.tools.list_ports.comports())
        if ports:
            print(c(YELLOW, "  Available ports:"))
            for p in ports:
                print(c(YELLOW, f"    {p.device} - {p.description}"))
        else:
            print(c(YELLOW, "  No serial ports found."))
    
    def send(self, cmd):
        """Send a command string to Arduino."""
        if self.ser and self.ser.is_open:
            self.ser.write((cmd + '\n').encode('utf-8'))
            print(c(BLUE, f"  -> Sent: {cmd}"))
    
    def _read_loop(self):
        """Background thread: read and process serial lines."""
        buf = b''
        while not self._stop.is_set():
            if self.ser and self.ser.is_open:
                try:
                    data = self.ser.read(128)
                    if data:
                        buf += data
                        while b'\n' in buf:
                            line, buf = buf.split(b'\n', 1)
                            try:
                                decoded = line.decode('utf-8', errors='replace').strip()
                                if decoded:
                                    self.handler.handle(decoded)
                            except Exception:
                                pass
                except serial.SerialException:
                    break
            else:
                time.sleep(0.1)
    
    def run(self, commands=None, wait_halt=False):
        """Start monitoring. Optionally send commands and wait for HALT."""
        self.connect()
        
        # Start reader thread
        reader = threading.Thread(target=self._read_loop, daemon=True)
        reader.start()
        
        # Send initial commands if any
        if commands:
            time.sleep(0.5)
            for cmd in commands:
                self.send(cmd)
                time.sleep(0.1)
        
        try:
            if wait_halt:
                # Wait until VM halts or timeout
                start = time.time()
                while not self.handler.halted:
                    if self.timeout and (time.time() - start) > self.timeout:
                        print(c(YELLOW, "\n  Timeout waiting for VM halt."))
                        break
                    time.sleep(0.1)
            else:
                # Interactive mode: allow sending commands via stdin
                print(c(DIM, "  Type commands to send to Arduino (e.g. @PING, @RESET):"))
                while True:
                    try:
                        line = input()
                        if line.strip():
                            self.send(line.strip())
                    except EOFError:
                        break
        
        except KeyboardInterrupt:
            print(c(YELLOW, "\n\n  Interrupted."))
        
        finally:
            self._stop.set()
            if self.ser:
                self.ser.close()
            print(c(DIM, "  Connection closed."))


# ─── List ports helper ─────────────────────────────────────────────────────────

def list_ports():
    if not HAS_SERIAL:
        print("pyserial not installed. Run: pip install pyserial")
        return
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("No serial ports found.")
        return
    print("Available ports:")
    for p in ports:
        print(f"  {p.device:10}  {p.description}")


# ─── Simulate mode (no Arduino, just show what packets would look like) ────────

def simulate_demo():
    """Demo mode: simulate an Arduino session without real hardware."""
    print(c(BOLD, "\n  ardpy.py — Simulation Mode (no Arduino connected)\n"))
    lcd = LCDEmulator()
    handler = PacketHandler(lcd, show_lcd=True)
    
    demo_packets = [
        "@BOOT|Python VM",
        "@LCD0|Hello World!",
        "@LCD1|from VM :)",
        "@PRINT|Result: 42",
        "@LCD0|Counter: 001",
        "@LCD1|Loop running",
        "@LCD0|Counter: 002",
        "@LCD0|Done!",
        "@LCD1|               ",
        "@HALT|0",
    ]
    
    print(c(DIM, "  Simulating Arduino output...\n"))
    for pkt in demo_packets:
        handler.handle(pkt)
        time.sleep(0.4)
    
    print(c(GREEN, "\n  Demo complete!"))


# ─── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='ardpy.py — Python host for PC-VM Arduino',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ardpy.py                       # connect to COM3 (default)
  python ardpy.py --port COM5           # custom port
  python ardpy.py --list                # list available ports
  python ardpy.py --simulate            # demo without Arduino
  python ardpy.py --port COM3 --cmd @PING   # send ping
  python ardpy.py --port COM3 --no-lcd      # no LCD display
        """
    )
    parser.add_argument('--port', default='COM3', help='Serial port (default: COM3)')
    parser.add_argument('--baud', type=int, default=9600, help='Baud rate (default: 9600)')
    parser.add_argument('--list', '-l', action='store_true', help='List available serial ports')
    parser.add_argument('--simulate', '-s', action='store_true', help='Simulate mode (no hardware)')
    parser.add_argument('--no-lcd', action='store_true', help="Don't render LCD in terminal")
    parser.add_argument('--cmd', action='append', metavar='CMD',
                        help='Send command to Arduino (can be repeated)')
    parser.add_argument('--wait', '-w', action='store_true',
                        help='Wait for VM HALT then exit')
    parser.add_argument('--timeout', type=float, default=None,
                        help='Timeout in seconds when using --wait')
    
    args = parser.parse_args()
    
    if args.list:
        list_ports()
        return
    
    if args.simulate:
        simulate_demo()
        return
    
    monitor = ArduinoMonitor(
        port=args.port,
        baud=args.baud,
        show_lcd=not args.no_lcd,
        timeout=args.timeout,
    )
    monitor.run(
        commands=args.cmd,
        wait_halt=args.wait,
    )


if __name__ == '__main__':
    main()
