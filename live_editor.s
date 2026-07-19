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

; --- Function clear_buffers ---
clear_buffers:
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    MOV AX, 0
    STORE AX, [BP - 4]
while_start_1:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 16
    POP BX
    CMP BX, AX
    JL cmp_true_3
    MOV AX, 0
    JMP cmp_end_4
cmp_true_3:
    MOV AX, 1
cmp_end_4:
    CMP AX, 0
    JZ while_end_2
    MOV AX, 32
    PUSH AX
    MOV AX, line0
    PUSH AX
    LOAD AX, [BP - 4]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    MOV AX, 32
    PUSH AX
    MOV AX, line1
    PUSH AX
    LOAD AX, [BP - 4]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 4]
    JMP while_start_1
while_end_2:
    MOV AX, 0
    PUSH AX
    MOV AX, line0
    PUSH AX
    MOV AX, 16
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    MOV AX, 0
    PUSH AX
    MOV AX, line1
    PUSH AX
    MOV AX, 16
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
epilogue_clear_buffers:
    MOV SP, BP
    POP BP
    RET

; --- Function draw_editor ---
draw_editor:
    PUSH BP
    MOV BP, SP
    SUB SP, 44
    MOV CX, BP
    SUB CX, 20
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    MOV CX, BP
    SUB CX, 40
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    MOV AX, 0
    STORE AX, [BP - 44]
while_start_5:
    LOAD AX, [BP - 44]
    PUSH AX
    MOV AX, 16
    POP BX
    CMP BX, AX
    JL cmp_true_7
    MOV AX, 0
    JMP cmp_end_8
cmp_true_7:
    MOV AX, 1
cmp_end_8:
    CMP AX, 0
    JZ while_end_6
    MOV AX, line0
    PUSH AX
    LOAD AX, [BP - 44]
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    PUSH AX
    MOV AX, BP
    SUB AX, 20
    PUSH AX
    LOAD AX, [BP - 44]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    MOV AX, line1
    PUSH AX
    LOAD AX, [BP - 44]
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    PUSH AX
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    LOAD AX, [BP - 44]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [BP - 44]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 44]
    JMP while_start_5
while_end_6:
    MOV AX, 0
    PUSH AX
    MOV AX, BP
    SUB AX, 20
    PUSH AX
    MOV AX, 16
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    MOV AX, 0
    PUSH AX
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    MOV AX, 16
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [cur_row]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JZ cmp_true_9
    MOV AX, 0
    JMP cmp_end_10
cmp_true_9:
    MOV AX, 1
cmp_end_10:
    CMP AX, 0
    JZ else_11
    MOV AX, 255
    PUSH AX
    MOV AX, BP
    SUB AX, 20
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    JMP end_if_12
else_11:
    MOV AX, 255
    PUSH AX
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
end_if_12:
    MOV AX, BP
    SUB AX, 20
    PUSH AX
    MOV AX, 0
    PUSH AX
    CALL lcd_print
    ADD SP, 8
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    MOV AX, 1
    PUSH AX
    CALL lcd_print
    ADD SP, 8
epilogue_draw_editor:
    MOV SP, BP
    POP BP
    RET

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    MOV AX, 0
    STORE AX, [cur_row]
    MOV AX, 0
    STORE AX, [cur_col]
    CALL clear_buffers
    CALL lcd_clear
    CALL draw_editor
while_start_13:
    MOV AX, 1
    CMP AX, 0
    JZ while_end_14
    CALL serial_avail
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_15
    MOV AX, 0
    JMP cmp_end_16
cmp_true_15:
    MOV AX, 1
cmp_end_16:
    CMP AX, 0
    JZ end_if_18
    CALL serial_readbyte
    STORE AX, [BP - 4]
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 128
    POP BX
    CMP BX, AX
    JZ cmp_true_19
    MOV AX, 0
    JMP cmp_end_20
cmp_true_19:
    MOV AX, 1
cmp_end_20:
    CMP AX, 0
    JZ else_21
    MOV AX, 0
    STORE AX, [cur_row]
    JMP end_if_22
else_21:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 129
    POP BX
    CMP BX, AX
    JZ cmp_true_23
    MOV AX, 0
    JMP cmp_end_24
cmp_true_23:
    MOV AX, 1
cmp_end_24:
    CMP AX, 0
    JZ else_25
    MOV AX, 1
    STORE AX, [cur_row]
    JMP end_if_26
else_25:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 130
    POP BX
    CMP BX, AX
    JZ cmp_true_27
    MOV AX, 0
    JMP cmp_end_28
cmp_true_27:
    MOV AX, 1
cmp_end_28:
    CMP AX, 0
    JZ else_29
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_31
    MOV AX, 0
    JMP cmp_end_32
cmp_true_31:
    MOV AX, 1
cmp_end_32:
    CMP AX, 0
    JZ end_if_34
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 1
    POP BX
    SUB BX, AX
    MOV AX, BX
    STORE AX, [cur_col]
end_if_34:
    JMP end_if_30
else_29:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 131
    POP BX
    CMP BX, AX
    JZ cmp_true_35
    MOV AX, 0
    JMP cmp_end_36
cmp_true_35:
    MOV AX, 1
cmp_end_36:
    CMP AX, 0
    JZ else_37
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 15
    POP BX
    CMP BX, AX
    JL cmp_true_39
    MOV AX, 0
    JMP cmp_end_40
cmp_true_39:
    MOV AX, 1
cmp_end_40:
    CMP AX, 0
    JZ end_if_42
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [cur_col]
end_if_42:
    JMP end_if_38
else_37:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 8
    POP BX
    CMP BX, AX
    JZ cmp_true_43
    MOV AX, 0
    JMP cmp_end_44
cmp_true_43:
    MOV AX, 1
cmp_end_44:
    CMP AX, 0
    JZ else_45
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_47
    MOV AX, 0
    JMP cmp_end_48
cmp_true_47:
    MOV AX, 1
cmp_end_48:
    CMP AX, 0
    JZ end_if_50
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 1
    POP BX
    SUB BX, AX
    MOV AX, BX
    STORE AX, [cur_col]
    LOAD AX, [cur_row]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JZ cmp_true_51
    MOV AX, 0
    JMP cmp_end_52
cmp_true_51:
    MOV AX, 1
cmp_end_52:
    CMP AX, 0
    JZ else_53
    MOV AX, 32
    PUSH AX
    MOV AX, line0
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    JMP end_if_54
else_53:
    MOV AX, 32
    PUSH AX
    MOV AX, line1
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
end_if_54:
end_if_50:
    JMP end_if_46
else_45:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 32
    POP BX
    CMP BX, AX
    JGE cmp_true_55
    MOV AX, 0
    JMP cmp_end_56
cmp_true_55:
    MOV AX, 1
cmp_end_56:
    CMP AX, 0
    JZ end_if_58
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 127
    POP BX
    CMP BX, AX
    JL cmp_true_59
    MOV AX, 0
    JMP cmp_end_60
cmp_true_59:
    MOV AX, 1
cmp_end_60:
    CMP AX, 0
    JZ end_if_62
    LOAD AX, [cur_row]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JZ cmp_true_63
    MOV AX, 0
    JMP cmp_end_64
cmp_true_63:
    MOV AX, 1
cmp_end_64:
    CMP AX, 0
    JZ else_65
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, line0
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    JMP end_if_66
else_65:
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, line1
    PUSH AX
    LOAD AX, [cur_col]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
end_if_66:
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 15
    POP BX
    CMP BX, AX
    JL cmp_true_67
    MOV AX, 0
    JMP cmp_end_68
cmp_true_67:
    MOV AX, 1
cmp_end_68:
    CMP AX, 0
    JZ end_if_70
    LOAD AX, [cur_col]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [cur_col]
end_if_70:
end_if_62:
end_if_58:
end_if_46:
end_if_38:
end_if_30:
end_if_26:
end_if_22:
    CALL draw_editor
end_if_18:
    MOV AX, 20
    PUSH AX
    CALL delay_ms
    ADD SP, 4
    JMP while_start_13
while_end_14:
    MOV AX, 0
    JMP epilogue_main
epilogue_main:
    MOV SP, BP
    POP BP
    RET


; --- Data Section ---
n_boot db "BOOT"
line0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
line1 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
cur_row db 0, 0, 0, 0
cur_col db 0, 0, 0, 0

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
