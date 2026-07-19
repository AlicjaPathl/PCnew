#!/usr/bin/env python3
import os
import sys
import write_helper

def main():
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    disk_ds_path = os.path.join(SCRIPT_DIR, "disk.ds")
    
    port = "COM3"
    board = "arduino:avr:uno"
    
    # Parse arguments if passed
    if len(sys.argv) > 1:
        disk_ds_path = sys.argv[1]
    if len(sys.argv) > 2:
        port = sys.argv[2]
    if len(sys.argv) > 3:
        board = sys.argv[3]
        
    write_helper.upload(disk_ds_path, port=port, board=board)

if __name__ == '__main__':
    main()