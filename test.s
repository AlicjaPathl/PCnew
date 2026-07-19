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

; --- Function factorial ---
factorial:
    PUSH BP
    MOV BP, SP
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 1
    POP BX
    CMP BX, AX
    JLE cmp_true_22
    MOV AX, 0
    JMP cmp_end_23
cmp_true_22:
    MOV AX, 1
cmp_end_23:
    CMP AX, 0
    JZ end_if_25
    MOV AX, 1
    JMP epilogue_factorial
end_if_25:
    LOAD AX, [BP + 8]
    PUSH AX
    LOAD AX, [BP + 8]
    PUSH AX
    MOV AX, 1
    POP BX
    SUB BX, AX
    MOV AX, BX
    PUSH AX
    CALL factorial
    ADD SP, 4
    POP BX
    MUL BX, AX
    MOV AX, BX
    JMP epilogue_factorial
epilogue_factorial:
    MOV SP, BP
    POP BP
    RET

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 64
    MOV AX, str_26
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 5
    STORE AX, [BP - 4]
    MOV AX, 10
    STORE AX, [BP - 8]
    LOAD AX, [BP - 4]
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    MOV AX, 2
    POP BX
    MUL BX, AX
    MOV AX, BX
    POP BX
    ADD BX, AX
    MOV AX, BX
    STORE AX, [BP - 12]
    MOV AX, str_27
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 12]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_28
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 5
    PUSH AX
    CALL factorial
    ADD SP, 4
    STORE AX, [BP - 16]
    MOV AX, str_29
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 16]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_30
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV CX, BP
    SUB CX, 48
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    MOV AX, str_31
    STORE AX, [BP - 52]
    LOAD AX, [BP - 52]
    PUSH AX
    MOV AX, BP
    SUB AX, 48
    PUSH AX
    CALL strcpy
    ADD SP, 8
    MOV AX, str_32
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, BP
    SUB AX, 48
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_33
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, BP
    SUB AX, 48
    PUSH AX
    CALL strlen
    ADD SP, 4
    STORE AX, [BP - 56]
    MOV AX, str_34
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 56]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_35
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 5
    STORE AX, [BP - 60]
    MOV AX, 10
    STORE AX, [BP - 64]
    LOAD AX, [BP - 60]
    PUSH AX
    LOAD AX, [BP - 64]
    POP BX
    CMP BX, AX
    JL cmp_true_36
    MOV AX, 0
    JMP cmp_end_37
cmp_true_36:
    MOV AX, 1
cmp_end_37:
    PUSH AX
    LOAD AX, [BP - 64]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JG cmp_true_38
    MOV AX, 0
    JMP cmp_end_39
cmp_true_38:
    MOV AX, 1
cmp_end_39:
    POP BX
    CMP BX, 0
    JZ and_false_40
    CMP AX, 0
    JZ and_false_40
    MOV AX, 1
    JMP and_end_41
and_false_40:
    MOV AX, 0
and_end_41:
    CMP AX, 0
    JZ end_if_43
    MOV AX, str_44
    PUSH AX
    CALL print_string
    ADD SP, 4
end_if_43:
    MOV AX, str_45
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
str_26 db "Hello from C program!\n"
str_27 db "Result 5 + 10*2 = "
str_28 db "\n"
str_29 db "Factorial(5) = "
str_30 db "\n"
str_31 db "Antigravity"
str_32 db "Copied string: "
str_33 db "\n"
str_34 db "Length: "
str_35 db "\n"
str_44 db "Logical AND: OK\n"
str_45 db "Done.\n"