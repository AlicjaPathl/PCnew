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

; --- Function fopen ---
fopen:
    PUSH BP
    MOV BP, SP
    LOAD CX, [BP + 8]
    LOAD DX, [BP + 12]
    MOV AX, 3
    syscall
epilogue_fopen:
    MOV SP, BP
    POP BP
    RET

; --- Function fread ---
fread:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    LOAD CX, [BP + 12]
    LOAD DX, [BP + 16]
    MOV AX, 4
    syscall
epilogue_fread:
    MOV SP, BP
    POP BP
    RET

; --- Function fwrite ---
fwrite:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    LOAD CX, [BP + 12]
    LOAD DX, [BP + 16]
    MOV AX, 5
    syscall
epilogue_fwrite:
    MOV SP, BP
    POP BP
    RET

; --- Function fclose ---
fclose:
    PUSH BP
    MOV BP, SP
    LOAD BX, [BP + 8]
    MOV AX, 6
    syscall
epilogue_fclose:
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

; --- Function main ---
main:
    PUSH BP
    MOV BP, SP
    SUB SP, 144
    MOV AX, str_22
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 1
    PUSH AX
    MOV AX, str_23
    PUSH AX
    CALL fopen
    ADD SP, 8
    STORE AX, [BP - 4]
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JL cmp_true_24
    MOV AX, 0
    JMP cmp_end_25
cmp_true_24:
    MOV AX, 1
cmp_end_25:
    CMP AX, 0
    JZ end_if_27
    MOV AX, str_28
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 1
    JMP epilogue_main
end_if_27:
    MOV AX, str_29
    STORE AX, [BP - 8]
    MOV AX, 38
    PUSH AX
    LOAD AX, [BP - 8]
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    CALL fwrite
    ADD SP, 12
    STORE AX, [BP - 12]
    LOAD AX, [BP - 4]
    PUSH AX
    CALL fclose
    ADD SP, 4
    MOV AX, str_30
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 12]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_31
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV CX, BP
    SUB CX, 140
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
    ADD CX, 1
    MOV AX, 0
    STORE_B AX, [CX]
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
    PUSH AX
    MOV AX, str_32
    PUSH AX
    CALL fopen
    ADD SP, 8
    STORE AX, [BP - 4]
    LOAD AX, [BP - 4]
    PUSH AX
    MOV AX, 0
    POP BX
    CMP BX, AX
    JL cmp_true_33
    MOV AX, 0
    JMP cmp_end_34
cmp_true_33:
    MOV AX, 1
cmp_end_34:
    CMP AX, 0
    JZ end_if_36
    MOV AX, str_37
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, 1
    JMP epilogue_main
end_if_36:
    MOV AX, 127
    PUSH AX
    MOV AX, BP
    SUB AX, 140
    PUSH AX
    LOAD AX, [BP - 4]
    PUSH AX
    CALL fread
    ADD SP, 12
    STORE AX, [BP - 144]
    LOAD AX, [BP - 4]
    PUSH AX
    CALL fclose
    ADD SP, 4
    MOV AX, str_38
    PUSH AX
    CALL print_string
    ADD SP, 4
    LOAD AX, [BP - 144]
    PUSH AX
    CALL print_int
    ADD SP, 4
    MOV AX, str_39
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, BP
    SUB AX, 140
    PUSH AX
    CALL print_string
    ADD SP, 4
    MOV AX, str_40
    PUSH AX
    CALL print_string
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
str_22 db "=== File I/O Test ===\n"
str_23 db "test_output.txt"
str_28 db "ERROR: cannot open file for writing\n"
str_29 db "Hello from VM fileio!\nLine 2 of test.\n"
str_30 db "Written bytes: "
str_31 db "\n"
str_32 db "test_output.txt"
str_37 db "ERROR: cannot open file for reading\n"
str_38 db "Read bytes: "
str_39 db "\nContent:\n"
str_40 db "\nFile I/O OK!\n"