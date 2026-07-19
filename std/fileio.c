#include "fileio.h"

int fopen(char *filename, int mode) {
    asm("LOAD CX, [BP + 8]");
    asm("LOAD DX, [BP + 12]");
    asm("MOV AX, 3");
    asm("syscall");
}

int fread(int fd, char *buf, int count) {
    asm("LOAD BX, [BP + 8]");
    asm("LOAD CX, [BP + 12]");
    asm("LOAD DX, [BP + 16]");
    asm("MOV AX, 4");
    asm("syscall");
}

int fwrite(int fd, char *buf, int count) {
    asm("LOAD BX, [BP + 8]");
    asm("LOAD CX, [BP + 12]");
    asm("LOAD DX, [BP + 16]");
    asm("MOV AX, 5");
    asm("syscall");
}

int fclose(int fd) {
    asm("LOAD BX, [BP + 8]");
    asm("MOV AX, 6");
    asm("syscall");
}
