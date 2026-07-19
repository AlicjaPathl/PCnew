#include "string.h"

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
