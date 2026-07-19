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

; --- Function print_string ---
print_string:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP + 8]
    MOV AX, 1
    MOV BX, 0
    syscall
epilogue_print_string:
    MOV SP, BP
    POP BP
    RET

; --- Function print_int ---
print_int:
    PUSH BP
    MOV BP, SP
    LOAD DX, [BP + 8]
    MOV AX, str_1
    PUSH AX
    CALL print_string
    ADD SP, 4
epilogue_print_int:
    MOV SP, BP
    POP BP
    RET

; --- Function putchar ---
putchar:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 0
    PUSH AX
    MOV CX, SP
    ADD CX, 4
    MOV AX, 1
    MOV BX, 0
    syscall
    ADD SP, 8
epilogue_putchar:
    MOV SP, BP
    POP BP
    RET

; --- Function getchar ---
getchar:
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    MOV CX, BP
    SUB CX, 4
    MOV AX, 2
    syscall
    LOAD AX, [BP - 4]
epilogue_getchar:
    MOV SP, BP
    POP BP
    RET

; --- Function delay ---
delay:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    DELAY AX
epilogue_delay:
    MOV SP, BP
    POP BP
    RET

; --- Function exit ---
exit:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP + 8]
    MOV AX, 60
    syscall
epilogue_exit:
    MOV SP, BP
    POP BP
    RET

; --- Function strlen ---
strlen:
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    MOV AX, 0
    STORE AX, [BP - 4]
while_start_2:
    LOAD AX, [BP + 8]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_4
    MOV AX, 0
    JMP cmp_end_5
cmp_true_4:
    MOV AX, 1
cmp_end_5:
    CMP AX, 0
    JZ while_end_3
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 4]
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP + 8]
    JMP while_start_2
while_end_3:
    LOAD AX, [BP - 4]
    JMP epilogue_strlen
epilogue_strlen:
    MOV SP, BP
    POP BP
    RET

; --- Function strcpy ---
strcpy:
    PUSH BP
    MOV BP, SP
while_start_6:
    LOAD AX, [BP + 12]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_8
    MOV AX, 0
    JMP cmp_end_9
cmp_true_8:
    MOV AX, 1
cmp_end_9:
    CMP AX, 0
    JZ while_end_7
    LOAD AX, [BP + 12]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP + 8]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP + 8]
    LOAD AX, [BP + 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP + 12]
    JMP while_start_6
while_end_7:
    MOV AX, 0
    PUSH AX
    LOAD AX, [BP + 8]
    POP BX
    STORE_B BX, [AX]
epilogue_strcpy:
    MOV SP, BP
    POP BP
    RET

; --- Function strcmp ---
strcmp:
    PUSH BP
    MOV BP, SP
while_start_10:
    LOAD AX, [BP + 8]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_12
    MOV AX, 0
    JMP cmp_end_13
cmp_true_12:
    MOV AX, 1
cmp_end_13:
    PUSH AX
    LOAD AX, [BP + 12]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_14
    MOV AX, 0
    JMP cmp_end_15
cmp_true_14:
    MOV AX, 1
cmp_end_15:
    POP BX
    CMP BX, 0
    JZ and_false_16
    CMP AX, 0
    JZ and_false_16
    MOV AX, 1
    JMP and_end_17
and_false_16:
    MOV AX, 0
and_end_17:
    CMP AX, 0
    JZ while_end_11
    LOAD AX, [BP + 8]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP + 12]
    LOAD_B AX, [AX]
    POP BX
    CMP BX, AX
    JNZ cmp_true_18
    MOV AX, 0
    JMP cmp_end_19
cmp_true_18:
    MOV AX, 1
cmp_end_19:
    CMP AX, 0
    JZ end_if_21
    JMP while_end_11
end_if_21:
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP + 8]
    LOAD AX, [BP + 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP + 12]
    JMP while_start_10
while_end_11:
    LOAD AX, [BP + 8]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP + 12]
    LOAD_B AX, [AX]
    POP BX
    SUB BX, AX
    MOV AX, BX
    JMP epilogue_strcmp
epilogue_strcmp:
    MOV SP, BP
    POP BP
    RET

; --- Function _gui_write_param ---
_gui_write_param:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    LOAD BX, [BP + 12]
    STORE BX, [AX]
epilogue__gui_write_param:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_init ---
gui_init:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    LOAD CX, [BP + 12]
    LOAD DX, [BP + 16]
    MOV AX, 30
    syscall
epilogue_gui_init:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_clear ---
gui_clear:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    MOV AX, 31
    syscall
epilogue_gui_clear:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_draw_rect ---
gui_draw_rect:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 57344
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 12]
    PUSH AX
    MOV AX, 57348
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 16]
    PUSH AX
    MOV AX, 57352
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 20]
    PUSH AX
    MOV AX, 57356
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 24]
    PUSH AX
    MOV AX, 57360
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 28]
    PUSH AX
    MOV AX, 57364
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    MOV BX, 0xE000
    MOV AX, 32
    syscall
epilogue_gui_draw_rect:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_draw_line ---
gui_draw_line:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 57344
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 12]
    PUSH AX
    MOV AX, 57348
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 16]
    PUSH AX
    MOV AX, 57352
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 20]
    PUSH AX
    MOV AX, 57356
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 24]
    PUSH AX
    MOV AX, 57360
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    MOV BX, 0xE000
    MOV AX, 33
    syscall
epilogue_gui_draw_line:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_draw_text ---
gui_draw_text:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 57344
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 12]
    PUSH AX
    MOV AX, 57348
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 16]
    PUSH AX
    MOV AX, 57352
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 20]
    PUSH AX
    MOV AX, 57356
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    LOAD AX, [BP + 24]
    PUSH AX
    MOV AX, 57360
    PUSH AX
    CALL _gui_write_param
    ADD SP, 8
    MOV BX, 0xE000
    MOV AX, 34
    syscall
epilogue_gui_draw_text:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_poll_event ---
gui_poll_event:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    MOV AX, 35
    syscall
epilogue_gui_poll_event:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_present ---
gui_present:
    PUSH BP
    MOV BP, SP
    MOV AX, 36
    syscall
epilogue_gui_present:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_panel ---
gui_panel:
    PUSH BP
    MOV BP, SP
    MOV AX, 1
    PUSH AX
    LOAD AX, [BP + 24]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_rect
    ADD SP, 24
    MOV AX, 0
    PUSH AX
    LOAD AX, [BP + 28]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_rect
    ADD SP, 24
epilogue_gui_panel:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_header ---
gui_header:
    PUSH BP
    MOV BP, SP
    MOV AX, 1
    PUSH AX
    LOAD AX, [BP + 28]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_rect
    ADD SP, 24
    MOV AX, 12
    PUSH AX
    LOAD AX, [BP + 24]
    PUSH AX
    LOAD AX, [BP + 32]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    MOV AX, 16
    POP BX
    SUB BX, AX
    MOV AX, BX
    PUSH AX
    MOV AX, 2
    POP BX
    DIV BX, AX
    MOV AX, BX
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 10
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    CALL gui_draw_text
    ADD SP, 20
epilogue_gui_header:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_label ---
gui_label:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 24]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_text
    ADD SP, 20
epilogue_gui_label:
    MOV SP, BP
    POP BP
    RET

; --- Function gui_button ---
gui_button:
    PUSH BP
    MOV BP, SP
    SUB SP, 8
    MOV AX, 0
    STORE AX, [BP - 4]
    LOAD AX, [BP + 28]
    PUSH AX
    LOAD AX, [BP + 8]
    POP BX
    CMP BX, AX
    JGE cmp_true_22
    MOV AX, 0
    JMP cmp_end_23
cmp_true_22:
    MOV AX, 1
cmp_end_23:
    PUSH AX
    LOAD AX, [BP + 28]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    LOAD AX, [BP + 16]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    CMP BX, AX
    JLE cmp_true_24
    MOV AX, 0
    JMP cmp_end_25
cmp_true_24:
    MOV AX, 1
cmp_end_25:
    POP BX
    CMP BX, 0
    JZ and_false_26
    CMP AX, 0
    JZ and_false_26
    MOV AX, 1
    JMP and_end_27
and_false_26:
    MOV AX, 0
and_end_27:
    PUSH AX
    LOAD AX, [BP + 32]
    PUSH AX
    LOAD AX, [BP + 12]
    POP BX
    CMP BX, AX
    JGE cmp_true_28
    MOV AX, 0
    JMP cmp_end_29
cmp_true_28:
    MOV AX, 1
cmp_end_29:
    POP BX
    CMP BX, 0
    JZ and_false_30
    CMP AX, 0
    JZ and_false_30
    MOV AX, 1
    JMP and_end_31
and_false_30:
    MOV AX, 0
and_end_31:
    PUSH AX
    LOAD AX, [BP + 32]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 20]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    CMP BX, AX
    JLE cmp_true_32
    MOV AX, 0
    JMP cmp_end_33
cmp_true_32:
    MOV AX, 1
cmp_end_33:
    POP BX
    CMP BX, 0
    JZ and_false_34
    CMP AX, 0
    JZ and_false_34
    MOV AX, 1
    JMP and_end_35
and_false_34:
    MOV AX, 0
and_end_35:
    CMP AX, 0
    JZ end_if_37
    MOV AX, 1
    STORE AX, [BP - 4]
end_if_37:
    MOV AX, 4144974
    STORE AX, [BP - 8]
    LOAD AX, [BP - 4]
    CMP AX, 0
    JZ end_if_39
    MOV AX, 6250366
    STORE AX, [BP - 8]
end_if_39:
    MOV AX, 1
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_rect
    ADD SP, 24
    MOV AX, 0
    PUSH AX
    MOV AX, 16777215
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP + 16]
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL gui_draw_rect
    ADD SP, 24
    MOV AX, 12
    PUSH AX
    LOAD AX, [BP + 24]
    PUSH AX
    MOV AX, 16777215
    PUSH AX
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    MOV AX, 16
    POP BX
    SUB BX, AX
    MOV AX, BX
    PUSH AX
    MOV AX, 2
    POP BX
    DIV BX, AX
    MOV AX, BX
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 10
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    CALL gui_draw_text
    ADD SP, 20
    LOAD AX, [BP - 4]
    PUSH AX
    LOAD AX, [BP + 36]
    PUSH AX
    MOV AX, 1
    POP BX
    CMP BX, AX
    JZ cmp_true_40
    MOV AX, 0
    JMP cmp_end_41
cmp_true_40:
    MOV AX, 1
cmp_end_41:
    POP BX
    CMP BX, 0
    JZ and_false_42
    CMP AX, 0
    JZ and_false_42
    MOV AX, 1
    JMP and_end_43
and_false_42:
    MOV AX, 0
and_end_43:
    CMP AX, 0
    JZ end_if_45
    MOV AX, 1
    JMP epilogue_gui_button
end_if_45:
    MOV AX, 0
    JMP epilogue_gui_button
epilogue_gui_button:
    MOV SP, BP
    POP BP
    RET

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 88
    MOV AX, str_46
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_47
    PUSH AX
    MOV AX, 300
    PUSH AX
    MOV AX, 400
    PUSH AX
    CALL gui_init
    ADD SP, 12
    MOV AX, 0
    STORE AX, [BP - 4]
    MOV AX, 0
    STORE AX, [BP - 8]
    MOV AX, 0
    STORE AX, [BP - 12]
    MOV AX, 0
    STORE AX, [BP - 16]
    MOV AX, 0
    STORE AX, [BP - 20]
    MOV AX, 1
    STORE AX, [BP - 24]
    MOV CX, BP
    SUB CX, 40
    MOV AX, 0
    STORE AX, [CX]
    ADD CX, 4
    MOV AX, 0
    STORE AX, [CX]
    ADD CX, 4
    MOV AX, 0
    STORE AX, [CX]
    ADD CX, 4
    MOV AX, 0
    STORE AX, [CX]
while_start_48:
    LOAD AX, [BP - 24]
    CMP AX, 0
    JZ while_end_49
    MOV AX, 0
    STORE AX, [BP - 12]
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    CALL gui_poll_event
    ADD SP, 4
    CMP AX, 0
    JZ end_if_51
    MOV AX, BP
    SUB AX, 40
    LOAD AX, [AX]
    STORE AX, [BP - 12]
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    STORE AX, [BP - 4]
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    MOV AX, 2
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    STORE AX, [BP - 8]
    MOV AX, BP
    SUB AX, 40
    PUSH AX
    MOV AX, 3
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    STORE AX, [BP - 16]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 3
    POP BX
    CMP BX, AX
    JZ cmp_true_52
    MOV AX, 0
    JMP cmp_end_53
cmp_true_52:
    MOV AX, 1
cmp_end_53:
    PUSH AX
    LOAD AX, [BP - 16]
    PUSH AX
    MOV AX, 27
    POP BX
    CMP BX, AX
    JZ cmp_true_54
    MOV AX, 0
    JMP cmp_end_55
cmp_true_54:
    MOV AX, 1
cmp_end_55:
    POP BX
    CMP BX, 0
    JZ and_false_56
    CMP AX, 0
    JZ and_false_56
    MOV AX, 1
    JMP and_end_57
and_false_56:
    MOV AX, 0
and_end_57:
    CMP AX, 0
    JZ end_if_59
    MOV AX, 0
    STORE AX, [BP - 24]
end_if_59:
end_if_51:
    MOV AX, 1710638
    PUSH AX
    CALL gui_clear
    ADD SP, 4
    MOV AX, 16777215
    PUSH AX
    MOV AX, 1450302
    PUSH AX
    MOV AX, 260
    PUSH AX
    MOV AX, 360
    PUSH AX
    MOV AX, 20
    PUSH AX
    MOV AX, 20
    PUSH AX
    CALL gui_panel
    ADD SP, 24
    MOV AX, 16777215
    PUSH AX
    MOV AX, 5452931
    PUSH AX
    MOV AX, str_60
    PUSH AX
    MOV AX, 30
    PUSH AX
    MOV AX, 360
    PUSH AX
    MOV AX, 20
    PUSH AX
    MOV AX, 20
    PUSH AX
    CALL gui_header
    ADD SP, 28
    MOV AX, 14
    PUSH AX
    MOV AX, 65535
    PUSH AX
    MOV AX, str_61
    PUSH AX
    MOV AX, 70
    PUSH AX
    MOV AX, 40
    PUSH AX
    CALL gui_label
    ADD SP, 20
    MOV AX, str_62
    STORE AX, [BP - 44]
    MOV AX, 20
    PUSH AX
    MOV AX, 16776960
    PUSH AX
    LOAD AX, [BP - 44]
    PUSH AX
    MOV AX, 100
    PUSH AX
    MOV AX, 40
    PUSH AX
    CALL gui_label
    ADD SP, 20
    MOV CX, BP
    SUB CX, 60
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
    LOAD AX, [BP - 20]
    STORE AX, [BP - 64]
    MOV AX, 0
    STORE AX, [BP - 68]
    LOAD AX, [BP - 64]
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
    MOV AX, 48
    PUSH AX
    MOV AX, BP
    SUB AX, 60
    PUSH AX
    LOAD AX, [BP - 68]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [BP - 68]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 68]
    JMP end_if_66
else_65:
    MOV CX, BP
    SUB CX, 84
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
    STORE AX, [BP - 88]
while_start_67:
    LOAD AX, [BP - 64]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_69
    MOV AX, 0
    JMP cmp_end_70
cmp_true_69:
    MOV AX, 1
cmp_end_70:
    CMP AX, 0
    JZ while_end_68
    MOV AX, 48
    PUSH AX
    LOAD AX, [BP - 64]
    PUSH AX
    MOV AX, 10
    POP BX
    MOD BX, AX
    MOV AX, BX
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    MOV AX, BP
    SUB AX, 84
    PUSH AX
    LOAD AX, [BP - 88]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [BP - 64]
    PUSH AX
    MOV AX, 10
    POP BX
    DIV BX, AX
    MOV AX, BX
    STORE AX, [BP - 64]
    LOAD AX, [BP - 88]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 88]
    JMP while_start_67
while_end_68:
while_start_71:
    LOAD AX, [BP - 88]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_73
    MOV AX, 0
    JMP cmp_end_74
cmp_true_73:
    MOV AX, 1
cmp_end_74:
    CMP AX, 0
    JZ while_end_72
    LOAD AX, [BP - 88]
    PUSH AX
    MOV AX, 1
    POP BX
    SUB BX, AX
    MOV AX, BX
    STORE AX, [BP - 88]
    MOV AX, BP
    SUB AX, 84
    PUSH AX
    LOAD AX, [BP - 88]
    POP BX
    ADD BX, AX
    MOV AX, BX
    LOAD AX, [AX]
    PUSH AX
    MOV AX, BP
    SUB AX, 60
    PUSH AX
    LOAD AX, [BP - 68]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    LOAD AX, [BP - 68]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 68]
    JMP while_start_71
while_end_72:
end_if_66:
    MOV AX, 0
    PUSH AX
    MOV AX, BP
    SUB AX, 60
    PUSH AX
    LOAD AX, [BP - 68]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE BX, [AX]
    MOV AX, 20
    PUSH AX
    MOV AX, 16776960
    PUSH AX
    MOV AX, BP
    SUB AX, 60
    PUSH AX
    MOV AX, 100
    PUSH AX
    MOV AX, 150
    PUSH AX
    CALL gui_label
    ADD SP, 20
    LOAD AX, [BP - 12]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, str_75
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, 120
    PUSH AX
    MOV AX, 150
    PUSH AX
    MOV AX, 40
    PUSH AX
    CALL gui_button
    ADD SP, 32
    CMP AX, 0
    JZ end_if_77
    LOAD AX, [BP - 20]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 20]
    MOV AX, str_78
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 20]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_79
    PUSH AX
    CALL print_string
    ADD SP, 4
end_if_77:
    LOAD AX, [BP - 12]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, str_80
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, 120
    PUSH AX
    MOV AX, 150
    PUSH AX
    MOV AX, 180
    PUSH AX
    CALL gui_button
    ADD SP, 32
    CMP AX, 0
    JZ end_if_82
    MOV AX, 0
    STORE AX, [BP - 20]
    MOV AX, str_83
    PUSH AX
    CALL print_string
    ADD SP, 4
end_if_82:
    LOAD AX, [BP - 12]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, str_84
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, 260
    PUSH AX
    MOV AX, 210
    PUSH AX
    MOV AX, 40
    PUSH AX
    CALL gui_button
    ADD SP, 32
    CMP AX, 0
    JZ end_if_86
    MOV AX, 0
    STORE AX, [BP - 24]
end_if_86:
    CALL gui_present
    MOV AX, 16
    PUSH AX
    CALL delay
    ADD SP, 4
    JMP while_start_48
while_end_49:
    MOV AX, str_87
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 0
    PUSH AX
    CALL exit
    ADD SP, 4
    MOV AX, 0
    JMP epilogue_main
epilogue_main:
    MOV SP, BP
    POP BP
    RET


; --- Data Section ---
n_boot db "BOOT"
str_1 db "{DX}"
str_46 db "GUI Test starting...\n"
str_47 db "PC VM Mini-Qt Demo"
str_60 db "Widget Dashboard"
str_61 db "Clicks Counter:"
str_62 db "Clicks: "
str_75 db "Click Me!"
str_78 db "Button 'Click Me!' clicked! Counter: "
str_79 db "\n"
str_80 db "Reset"
str_83 db "Button 'Reset' clicked!\n"
str_84 db "Exit Application"
str_87 db "GUI program finished successfully.\n"