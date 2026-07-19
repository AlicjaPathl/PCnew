// test_fileio.c — test zapisu i odczytu pliku
#include <stdio.h>
#include <fileio.h>
#include <string.h>

int main() {
    print_string("=== File I/O Test ===\n");

    // Zapis do pliku
    int fd = fopen("test_output.txt", 1);
    if (fd < 0) {
        print_string("ERROR: cannot open file for writing\n");
        return 1;
    }
    char *msg = "Hello from VM fileio!\nLine 2 of test.\n";
    int written = fwrite(fd, msg, 38);
    fclose(fd);

    print_string("Written bytes: ");
    print_int(written);
    print_string("\n");

    // Odczyt z pliku
    char buf[128];
    fd = fopen("test_output.txt", 0);
    if (fd < 0) {
        print_string("ERROR: cannot open file for reading\n");
        return 1;
    }
    int n = fread(fd, buf, 127);
    fclose(fd);

    print_string("Read bytes: ");
    print_int(n);
    print_string("\nContent:\n");
    print_string(buf);
    print_string("\nFile I/O OK!\n");
    return 0;
}
