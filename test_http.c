#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <http.h>

int main() {
    print_string("HTTP Client Test starting...\n");

    // We'll perform an HTTP GET request to httpbin.org/ip
    char *host = "httpbin.org";
    int port = 80;
    char *path = "/ip";

    // Pre-allocate response buffer in RAM
    // Address 0x2000 is safe to write standard response data to.
    // Or we can use a stack-allocated buffer! Let's use a 1024-byte stack buffer.
    char response[1024];

    print_string("Connecting to httpbin.org:80 and requesting /ip...\n");
    int bytes_received = http_get(host, port, path, response, 1000);

    if (bytes_received < 0) {
        print_string("HTTP Request Failed!\n");
        exit(1);
    }

    print_string("HTTP Request Successful!\n");
    print_string("Bytes received: ");
    print_int(bytes_received);
    print_string("\n\n--- Response Content ---\n");
    print_string(response);
    print_string("\n------------------------\n");

    print_string("HTTP Client test finished.\n");
    exit(0);
    return 0;
}
