; hello.s — minimalny program z dokumentacji (docs/assembly.md)
_global:
    MOV 0xF000, n_boot
    MOV AX, 0
    syscall
    JMP _start

_start:
    MOV AX, 1
    MOV CX, msg
    SYSCALL
    MOV AX, 60
    MOV CX, 0
    SYSCALL

msg db "Hello from ASM!"
n_boot db "BOOT"
