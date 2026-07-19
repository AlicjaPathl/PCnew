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

; --- Function net_connect ---
net_connect:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP + 8]
    LOAD DX, [BP + 12]
    MOV AX, 50
    syscall
epilogue_net_connect:
    MOV SP, BP
    POP BP
    RET

; --- Function net_send ---
net_send:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    LOAD CX, [BP + 12]
    LOAD DX, [BP + 16]
    MOV AX, 5
    syscall
epilogue_net_send:
    MOV SP, BP
    POP BP
    RET

; --- Function net_recv ---
net_recv:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    LOAD CX, [BP + 12]
    LOAD DX, [BP + 16]
    MOV AX, 4
    syscall
epilogue_net_recv:
    MOV SP, BP
    POP BP
    RET

; --- Function net_close ---
net_close:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    MOV AX, 6
    syscall
epilogue_net_close:
    MOV SP, BP
    POP BP
    RET

; --- Function http_get ---
http_get:
    PUSH BP
    MOV BP, SP
    SUB SP, 48
    LOAD AX, [BP + 12]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    CALL net_connect
    ADD SP, 8
    STORE AX, [BP - 4]
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JL cmp_true_22
    MOV AX, 0
    JMP cmp_end_23
cmp_true_22:
    MOV AX, 1
cmp_end_23:
    CMP AX, 0
    JZ end_if_25
    LOAD AX, [BP - 4]
    JMP epilogue_http_get
end_if_25:
    MOV AX, 53248
    STORE AX, [BP - 8]
    LOAD AX, [BP - 8]
    STORE AX, [BP - 12]
    MOV AX, str_26
    STORE AX, [BP - 16]
while_start_27:
    LOAD AX, [BP - 16]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_29
    MOV AX, 0
    JMP cmp_end_30
cmp_true_29:
    MOV AX, 1
cmp_end_30:
    CMP AX, 0
    JZ while_end_28
    LOAD AX, [BP - 16]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    LOAD AX, [BP - 16]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 16]
    JMP while_start_27
while_end_28:
    LOAD AX, [BP + 16]
    STORE AX, [BP - 20]
while_start_31:
    LOAD AX, [BP - 20]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_33
    MOV AX, 0
    JMP cmp_end_34
cmp_true_33:
    MOV AX, 1
cmp_end_34:
    CMP AX, 0
    JZ while_end_32
    LOAD AX, [BP - 20]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    LOAD AX, [BP - 20]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 20]
    JMP while_start_31
while_end_32:
    MOV AX, str_35
    STORE AX, [BP - 24]
while_start_36:
    LOAD AX, [BP - 24]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_38
    MOV AX, 0
    JMP cmp_end_39
cmp_true_38:
    MOV AX, 1
cmp_end_39:
    CMP AX, 0
    JZ while_end_37
    LOAD AX, [BP - 24]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    LOAD AX, [BP - 24]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 24]
    JMP while_start_36
while_end_37:
    LOAD AX, [BP + 8]
    STORE AX, [BP - 28]
while_start_40:
    LOAD AX, [BP - 28]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_42
    MOV AX, 0
    JMP cmp_end_43
cmp_true_42:
    MOV AX, 1
cmp_end_43:
    CMP AX, 0
    JZ while_end_41
    LOAD AX, [BP - 28]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    LOAD AX, [BP - 28]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 28]
    JMP while_start_40
while_end_41:
    MOV AX, str_44
    STORE AX, [BP - 32]
while_start_45:
    LOAD AX, [BP - 32]
    LOAD_B AX, [AX]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JNZ cmp_true_47
    MOV AX, 0
    JMP cmp_end_48
cmp_true_47:
    MOV AX, 1
cmp_end_48:
    CMP AX, 0
    JZ while_end_46
    LOAD AX, [BP - 32]
    LOAD_B AX, [AX]
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    LOAD AX, [BP - 32]
    PUSH AX
    MOV AX, 1
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 32]
    JMP while_start_45
while_end_46:
    MOV AX, 0
    PUSH AX
    LOAD AX, [BP - 12]
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 12]
    PUSH AX
    LOAD AX, [BP - 8]
    POP BX
    SUB BX, AX
    MOV AX, BX
    STORE AX, [BP - 36]
    LOAD AX, [BP - 36]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    CALL net_send
    ADD SP, 12
    MOV AX, 0
    STORE AX, [BP - 40]
    MOV AX, 1
    STORE AX, [BP - 44]
while_start_49:
    LOAD AX, [BP - 44]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_51
    MOV AX, 0
    JMP cmp_end_52
cmp_true_51:
    MOV AX, 1
cmp_end_52:
    PUSH AX
    LOAD AX, [BP - 40]
    PUSH AX
    LOAD AX, [BP + 24]
    POP BX
    CMP BX, AX
    JL cmp_true_53
    MOV AX, 0
    JMP cmp_end_54
cmp_true_53:
    MOV AX, 1
cmp_end_54:
    POP BX
    CMP BX, 0
    JZ and_false_55
    CMP AX, 0
    JZ and_false_55
    MOV AX, 1
    JMP and_end_56
and_false_55:
    MOV AX, 0
and_end_56:
    CMP AX, 0
    JZ while_end_50
    LOAD AX, [BP + 24]
    PUSH AX
    LOAD AX, [BP - 40]
    POP BX
    SUB BX, AX
    MOV AX, BX
    STORE AX, [BP - 48]
    LOAD AX, [BP - 48]
    PUSH AX
    MOV AX, 512
    POP BX
    CMP BX, AX
    JG cmp_true_57
    MOV AX, 0
    JMP cmp_end_58
cmp_true_57:
    MOV AX, 1
cmp_end_58:
    CMP AX, 0
    JZ end_if_60
    MOV AX, 512
    STORE AX, [BP - 48]
end_if_60:
    LOAD AX, [BP - 48]
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP - 40]
    POP BX
    ADD BX, AX
    MOV AX, BX
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    CALL net_recv
    ADD SP, 12
    STORE AX, [BP - 44]
    LOAD AX, [BP - 44]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_61
    MOV AX, 0
    JMP cmp_end_62
cmp_true_61:
    MOV AX, 1
cmp_end_62:
    CMP AX, 0
    JZ end_if_64
    LOAD AX, [BP - 40]
    PUSH AX
    LOAD AX, [BP - 44]
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 40]
end_if_64:
    JMP while_start_49
while_end_50:
    MOV AX, 0
    PUSH AX
    LOAD AX, [BP + 20]
    PUSH AX
    LOAD AX, [BP - 40]
    POP BX
    ADD BX, AX
    MOV AX, BX
    POP BX
    STORE_B BX, [AX]
    LOAD AX, [BP - 4]
    PUSH AX
    CALL net_close
    ADD SP, 4
    LOAD AX, [BP - 40]
    JMP epilogue_http_get
epilogue_http_get:
    MOV SP, BP
    POP BP
    RET

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 1040
    MOV AX, str_65
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_66
    STORE AX, [BP - 4]
    MOV AX, 80
    STORE AX, [BP - 8]
    MOV AX, str_67
    STORE AX, [BP - 12]
    MOV CX, BP
    SUB CX, 1036
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
    MOV AX, str_68
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 1000
    PUSH AX
    MOV AX, BP
    SUB AX, 1036
    PUSH AX
    LOAD AX, [BP - 12]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    CALL http_get
    ADD SP, 20
    STORE AX, [BP - 1040]
    LOAD AX, [BP - 1040]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JL cmp_true_69
    MOV AX, 0
    JMP cmp_end_70
cmp_true_69:
    MOV AX, 1
cmp_end_70:
    CMP AX, 0
    JZ end_if_72
    MOV AX, str_73
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 1
    PUSH AX
    CALL exit
    ADD SP, 4
end_if_72:
    MOV AX, str_74
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_75
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 1040]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_76
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, BP
    SUB AX, 1036
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_77
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_78
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
str_26 db "GET "
str_35 db " HTTP/1.0\r\nHost: "
str_44 db "\r\nConnection: close\r\n\r\n"
str_65 db "HTTP Client Test starting...\n"
str_66 db "httpbin.org"
str_67 db "/ip"
str_68 db "Connecting to httpbin.org:80 and requesting /ip...\n"
str_73 db "HTTP Request Failed!\n"
str_74 db "HTTP Request Successful!\n"
str_75 db "Bytes received: "
str_76 db "\n\n--- Response Content ---\n"
str_77 db "\n------------------------\n"
str_78 db "HTTP Client test finished.\n"