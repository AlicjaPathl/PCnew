
// --- Include stdio.h ---


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


// --- Include stdlib.h ---


void delay(int ms) {
    asm("LOAD AX, [BP + 8]");
    asm("DELAY AX");
}

void exit(int code) {
    asm("LOAD CX, [BP + 8]");
    asm("MOV AX, 60");
    asm("syscall");
}


// --- Include string.h ---


int strlen(char *s) {
    int len = 0;
    while (*s != 0) {
        len = len + 1;
        s = s + 1;
    }
    return len;
}

void strcpy(char *dest, char *src) {
    while (*src != 0) {
        *dest = *src;
        dest = dest + 1;
        src = src + 1;
    }
    *dest = 0;
}

int strcmp(char *s1, char *s2) {
    while (*s1 != 0 && *s2 != 0) {
        if (*s1 != *s2) {
            break;
        }
        s1 = s1 + 1;
        s2 = s2 + 1;
    }
    return *s1 - *s2;
}


// --- Main Program ---




int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int main() {
    print_string("Hello from C program!\n");
    
    // Test 1: Arithmetic & variables
    int a = 5;
    int b = 10;
    int c = a + b * 2; // 5 + 20 = 25
    
    print_string("Result 5 + 10 * 2 = ");
    print_int(c);
    print_string("\n");
    
    // Test 2: Recursion
    int fact = factorial(5); // 120
    print_string("Factorial(5) = ");
    print_int(fact);
    print_string("\n");
    
    // Test 3: String manipulation & Pointers
    char *src = "Antigravity";
    // char dest[20];
    // Wait, in standard C we do, but to be safe and compatible with our simplified cc.py,
    // let's pass a pointer to a global array, or allocate a pointer address directly.
    // Address 0x2000 is safe to write dest string to!
    char *dst = 0x2000;
    
    strcpy(dst, src);
    print_string("Copied string: ");
    print_string(dst);
    print_string("\n");
    
    int len = strlen(dst);
    print_string("Length: ");
    print_int(len);
    print_string("\n");
    
    // Test 4: exit
    print_string("Exiting C program...\n");
    exit(0);
    return 0;
}
