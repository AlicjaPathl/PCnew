#include "stdlib.h"

void delay(int ms) {
    asm("LOAD AX, [BP + 8]");
    asm("DELAY AX");
}

void exit(int code) {
    asm("LOAD CX, [BP + 8]");
    asm("MOV AX, 60");
    asm("syscall");
}
