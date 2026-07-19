_global:
    MOV 0xF000, n_boot
    syscall
    jmp _start

_start:
    ; ===========================================
    ; TEST 1: SUB / MUL / DIV
    ; (10 - 4) * 3 / 2 = 9
    ; ===========================================
    mov ax, 10
    sub ax, 4
    mul ax, 3
    div ax, 2
    cmp ax, 9
    jnz t1_fail

    ; ===========================================
    ; TEST 2: MOD — 17 mod 5 = 2
    ; ===========================================
    mov ax, 17
    mod ax, 5
    cmp ax, 2
    jnz t2_fail

    ; ===========================================
    ; TEST 3: INC / DEC / NEG
    ; start 5, inc=6, dec=5, dec=4, neg=-4, neg=4
    ; ===========================================
    mov ax, 5
    inc ax
    dec ax
    dec ax
    neg ax
    neg ax
    cmp ax, 4
    jnz t3_fail

    ; ===========================================
    ; TEST 4: AND / OR / XOR
    ; 0xAA AND 0x0F = 0x0A, OR 0xF0 = 0xFA, XOR 0x50 = 0xAA
    ; ===========================================
    mov ax, 0xAA
    and ax, 0x0F
    or  ax, 0xF0
    xor ax, 0x50
    cmp ax, 0xAA
    jnz t4_fail

    ; ===========================================
    ; TEST 5: SHL / SHR
    ; 1 << 4 = 16, >> 2 = 4
    ; ===========================================
    mov ax, 1
    shl ax, 4
    shr ax, 2
    cmp ax, 4
    jnz t5_fail

    ; ===========================================
    ; TEST 6: NOT — NOT(0xFF) AND 0xFF = 0
    ; ===========================================
    mov ax, 0xFF
    not ax
    and ax, 0xFF
    cmp ax, 0
    jnz t6_fail

    ; ===========================================
    ; TEST 7: PUSH / POP — round-trip 0xAB
    ; ===========================================
    mov ax, 0xAB
    push ax
    mov ax, 0
    pop ax
    cmp ax, 0xAB
    jnz t7_fail

    ; ===========================================
    ; TEST 8: JG / JGE / JLE
    ; ===========================================
    mov ax, 10
    cmp ax, 5
    jg  t8a
    jmp t8_fail
t8a:
    mov ax, 10
    cmp ax, 10
    jge t8b
    jmp t8_fail
t8b:
    mov ax, 3
    cmp ax, 9
    jle t8c
    jmp t8_fail
t8c:

    ; ===========================================
    ; TEST 9: CALL / RET — factorial(5) = 120
    ; ===========================================
    mov ax, 5
    call fact
    cmp ax, 120
    jnz t9_fail

    ; ===========================================
    ; WSZYSTKIE TESTY ZALICZONE
    ; ===========================================
    MOV ax, 1
    mov bx, 0
    mov cx, n_ok
    syscall
    jmp end

; --- bloki bledu ---
t1_fail:
    mov cx, n_t1
    jmp fail_print

t2_fail:
    mov cx, n_t2
    jmp fail_print

t3_fail:
    mov cx, n_t3
    jmp fail_print

t4_fail:
    mov cx, n_t4
    jmp fail_print

t5_fail:
    mov cx, n_t5
    jmp fail_print

t6_fail:
    mov cx, n_t6
    jmp fail_print

t7_fail:
    mov cx, n_t7
    jmp fail_print

t8_fail:
    mov cx, n_t8
    jmp fail_print

t9_fail:
    mov cx, n_t9
    jmp fail_print

fail_print:
    MOV ax, 1
    syscall
    jmp end

end:
    MOV ax, 60
    mov bx, 0
    syscall

; ===========================================
; Subroutine: fact — silnia rekurencyjna
; Wejscie:  AX = n
; Wyjscie:  AX = n!
; ===========================================
fact:
    cmp ax, 1
    jle fact_base
    push ax
    sub ax, 1
    call fact
    pop bx
    mul ax, bx
    ret
fact_base:
    mov ax, 1
    ret

n_boot db "BOOT"
n_ok   db "OK: WSZYSTKO"
n_t1   db "FAIL: ARYTM"
n_t2   db "FAIL: MOD"
n_t3   db "FAIL: INC/DEC"
n_t4   db "FAIL: BITWISE"
n_t5   db "FAIL: SHIFT"
n_t6   db "FAIL: NOT"
n_t7   db "FAIL: STOS"
n_t8   db "FAIL: SKOKI"
n_t9   db "FAIL: CALL/RET"
