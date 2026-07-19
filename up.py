import os
import subprocess
import sys

ARDUINO_CLI = r"C:\Users\neon\AppData\Local\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"

SKETCH_DIR = os.path.join(os.path.dirname(__file__), "ard", "main")

BOARD = "arduino:avr:uno"
PORT = "COM3"


def run(cmd):
    print("> ", " ".join(cmd))
    result = subprocess.run(cmd)

    if result.returncode != 0:
        print("❌ Błąd")
        sys.exit(1)


def main():

    if not os.path.exists("ard/main.c"):
        print("❌ Brak ard/main.c")
        return

    print("📂 Znaleziono ard/main.c")

    # kompilacja
    run([
        ARDUINO_CLI,
        "compile",
        "--fqbn",
        BOARD,
        SKETCH_DIR
    ])

    # wgrywanie
    run([
        ARDUINO_CLI,
        "upload",
        "--fqbn",
        BOARD,
        "--port",
        PORT,
        SKETCH_DIR
    ])

    print("✅ Program wgrany na Arduino")


if __name__ == "__main__":
    main()