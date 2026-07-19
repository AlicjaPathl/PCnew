; --- Bootloader wrap ---
_global:
    PUSH BX
    PUSH AX
    MOV AX, 0
    MOV 0xF000, n_boot
    syscall
    POP AX
    POP BX
    jmp _start

_start:
    MOV SP, 65536
    PUSH BX
    PUSH AX
    CALL main
    MOV AX, 60
    MOV BX, 0
    syscall

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    MOV AX, str_1
    PUSH AX
    MOV AX, 0
    PUSH AX
    CALL lcd_print
    ADD SP, 8
    MOV AX, str_2
    PUSH AX
    MOV AX, 1
    PUSH AX
    CALL lcd_print
    ADD SP, 8
    MOV AX, str_3
    PUSH AX
    CALL serial_println
    ADD SP, 4
    MOV AX, 0
    STORE AX, [BP - 4]
    MOV AX, 1
    PUSH AX
    MOV AX, 13
    PUSH AX
    CALL pin_mode
    ADD SP, 8
while_start_4:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 5
    POP BX
    CMP BX, AX
    JL cmp_true_6
    MOV AX, 0
    JMP cmp_end_7
cmp_true_6:
    MOV AX, 1
cmp_end_7:
    CMP AX, 0
    JZ while_end_5
    MOV AX, 1
    PUSH AX
    MOV AX, 13
    PUSH AX
    CALL pin_write
    ADD SP, 8
    MOV AX, 500
    PUSH AX
    CALL delay_ms
    ADD SP, 4
    MOV AX, 0
    PUSH AX
    MOV AX, 13
    PUSH AX
    CALL pin_write
    ADD SP, 8
    MOV AX, 500
    PUSH AX
    CALL delay_ms
    ADD SP, 4
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 4]
    JMP while_start_4
while_end_5:
    CALL lcd_clear
    MOV AX, str_8
    PUSH AX
    MOV AX, 0
    PUSH AX
    CALL lcd_print
    ADD SP, 8
    MOV AX, str_9
    PUSH AX
    CALL serial_println
    ADD SP, 4
    MOV AX, 0
    JMP epilogue_main
epilogue_main:
    MOV SP, BP
    POP BP
    RET


; --- Data Section ---
n_boot db "BOOT"
str_1 db "Hello World!"
str_2 db "from VM :)"
str_3 db "VM started!"
str_8 db "Done! Blinks: 5"
str_9 db "Finished!"

; === Arduino stdlib ===
lcd_print:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 40
    SYSCALL
epilogue_lcd_print:
    MOV SP, BP
    POP BP
    RET

lcd_print0:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP+8]
    MOV BX, 0
    MOV AX, 40
    SYSCALL
epilogue_lcd_print0:
    MOV SP, BP
    POP BP
    RET

lcd_print1:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP+8]
    MOV BX, 1
    MOV AX, 40
    SYSCALL
epilogue_lcd_print1:
    MOV SP, BP
    POP BP
    RET

lcd_clear:
    PUSH BP
    MOV BP, SP
    MOV AX, 41
    SYSCALL
epilogue_lcd_clear:
    MOV SP, BP
    POP BP
    RET

lcd_backlight:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    MOV AX, 42
    SYSCALL
epilogue_lcd_backlight:
    MOV SP, BP
    POP BP
    RET

lcd_cursor:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 43
    SYSCALL
epilogue_lcd_cursor:
    MOV SP, BP
    POP BP
    RET

lcd_char:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP+8]
    MOV BX, 255
    MOV AX, 44
    SYSCALL
epilogue_lcd_char:
    MOV SP, BP
    POP BP
    RET

lcd_init:
    PUSH BP
    MOV BP, SP
    MOV AX, 41
    SYSCALL
epilogue_lcd_init:
    MOV SP, BP
    POP BP
    RET

lcd_scroll_left:
    PUSH BP
    MOV BP, SP
    MOV BX, 0
    MOV AX, 45
    SYSCALL
epilogue_lcd_scroll_left:
    MOV SP, BP
    POP BP
    RET

lcd_scroll_right:
    PUSH BP
    MOV BP, SP
    MOV BX, 1
    MOV AX, 45
    SYSCALL
epilogue_lcd_scroll_right:
    MOV SP, BP
    POP BP
    RET

pin_mode:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 46
    SYSCALL
epilogue_pin_mode:
    MOV SP, BP
    POP BP
    RET

pin_write:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 47
    SYSCALL
epilogue_pin_write:
    MOV SP, BP
    POP BP
    RET

pin_read:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    MOV AX, 48
    SYSCALL
epilogue_pin_read:
    MOV SP, BP
    POP BP
    RET

analog_read:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    MOV AX, 49
    SYSCALL
epilogue_analog_read:
    MOV SP, BP
    POP BP
    RET

analog_write:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 50
    SYSCALL
epilogue_analog_write:
    MOV SP, BP
    POP BP
    RET

delay_ms:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    MOV AX, 51
    SYSCALL
epilogue_delay_ms:
    MOV SP, BP
    POP BP
    RET

millis_now:
    PUSH BP
    MOV BP, SP
    MOV AX, 52
    SYSCALL
epilogue_millis_now:
    MOV SP, BP
    POP BP
    RET

serial_println:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP+8]
    MOV BX, 2
    MOV AX, 1
    SYSCALL
epilogue_serial_println:
    MOV SP, BP
    POP BP
    RET

serial_avail:
    PUSH BP
    MOV BP, SP
    MOV AX, 53
    SYSCALL
epilogue_serial_avail:
    MOV SP, BP
    POP BP
    RET

serial_readbyte:
    PUSH BP
    MOV BP, SP
    MOV AX, 54
    SYSCALL
epilogue_serial_readbyte:
    MOV SP, BP
    POP BP
    RET

eeprom_write:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    LOAD CX, [BP+12]
    MOV AX, 55
    SYSCALL
epilogue_eeprom_write:
    MOV SP, BP
    POP BP
    RET

eeprom_read:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP+8]
    MOV AX, 56
    SYSCALL
epilogue_eeprom_read:
    MOV SP, BP
    POP BP
    RET
