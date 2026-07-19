#!/usr/bin/env python3
"""
ards.py — Arduino ASM Compiler & Uploader
Wykorzystuje comp.py do kompilacji pliku .s do .ds,
a następnie write_helper.py do wgrania na Arduino.

Użycie:
  python ards.py <plik.s>
  python ards.py <plik.s> --port COM3
"""

import sys
import os
import argparse
import comp as comp_module
import write_helper

def main():
    parser = argparse.ArgumentParser(
        description='ards.py — Arduino Assembly Compiler & Uploader',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ards.py main.s                  # compiles and uploads via COM3 (default)
  python ards.py main.s --port COM5      # custom port
  python ards.py main.s --board arduino:avr:mega
        """
    )
    parser.add_argument('source', help='.s assembly file')
    parser.add_argument('--port', default=None, help='COM port for upload')
    parser.add_argument('--board', default=None, help='FQBN for Arduino board')
    parser.add_argument('--output', '-o', default=None, help='Output .ds file')
    args = parser.parse_args()

    source = args.source
    if not os.path.exists(source):
        print(f"ards.py: ERROR: File '{source}' not found.")
        sys.exit(1)

    base = os.path.splitext(source)[0]
    output_ds = args.output or (base + '.ds')

    print(f"ards.py — Arduino ASM Compiler")
    print(f"Source: {source} -> {output_ds}")
    print()

    # Compile Assembly to Disk string
    try:
        disk_string = comp_module.compile_to_disk_string(source)
        with open(output_ds, 'w', encoding='utf-8') as f:
            f.write(disk_string + '\n')
        print(f"[OK] ASM successfully compiled to {output_ds}!")
    except Exception as e:
        print(f"[ERROR] Assembly compilation failed: {e}")
        sys.exit(1)

    print()
    print("[ards] Uploading compiled assembly to Arduino...")
    write_helper.upload(
        ds_path=output_ds,
        port=args.port,
        board=args.board
    )

if __name__ == '__main__':
    main()
