#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
    int c = a + b * 2;  // 5 + 20 = 25

    print_string("Result 5 + 10*2 = ");
    print_int(c);
    print_string("\n");

    // Test 2: Recursion
    int fact = factorial(5);  // 120
    print_string("Factorial(5) = ");
    print_int(fact);
    print_string("\n");

    // Test 3: Static array on stack
    char dst[32];
    char *src = "Antigravity";
    strcpy(dst, src);
    print_string("Copied string: ");
    print_string(dst);
    print_string("\n");

    int len = strlen(dst);
    print_string("Length: ");
    print_int(len);
    print_string("\n");

    // Test 4: Logical operators
    int x = 5;
    int y = 10;
    if (x < y && y > 0) {
        print_string("Logical AND: OK\n");
    }

    // Test 5: exit
    print_string("Done.\n");
    exit(0);
    return 0;
}
