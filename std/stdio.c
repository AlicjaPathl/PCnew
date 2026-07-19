#include "stdio.h"

void print_string(char *s) {
    asm("LOAD CX, [BP + 8]");
    asm("MOV AX, 1");
    asm("MOV BX, 0");
    asm("syscall");
}

void print_int(int val) {
    asm("LOAD DX, [BP + 8]");
    print_string("{DX}");
}

void putchar(char c) {
    asm("LOAD AX, [BP + 8]");
    asm("PUSH AX");
    asm("MOV AX, 0");
    asm("PUSH AX");
    asm("MOV CX, SP");
    asm("ADD CX, 4");
    asm("MOV AX, 1");
    asm("MOV BX, 0");
    asm("syscall");
    asm("ADD SP, 8");
}

int getchar() {
    int val;
    asm("MOV CX, BP");
    asm("SUB CX, 4");
    asm("MOV AX, 2");
    asm("syscall");
    asm("LOAD AX, [BP - 4]");
}
