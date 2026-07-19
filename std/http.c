#include "http.h"

int net_connect(char *host, int port) {
    // Syscall 50: CX=host_addr, DX=port -> AX=fd
    asm("LOAD CX, [BP + 8]");
    asm("LOAD DX, [BP + 12]");
    asm("MOV AX, 50");
    asm("syscall");
}

int net_send(int fd, char *data, int len) {
    // Use fwrite syscall (AX=5): BX=fd, CX=buf, DX=count
    asm("LOAD BX, [BP + 8]");
    asm("LOAD CX, [BP + 12]");
    asm("LOAD DX, [BP + 16]");
    asm("MOV AX, 5");
    asm("syscall");
}

int net_recv(int fd, char *buf, int max_len) {
    // Use fread syscall (AX=4): BX=fd, CX=buf, DX=count
    asm("LOAD BX, [BP + 8]");
    asm("LOAD CX, [BP + 12]");
    asm("LOAD DX, [BP + 16]");
    asm("MOV AX, 4");
    asm("syscall");
}

int net_close(int fd) {
    // Use fclose syscall (AX=6): BX=fd
    asm("LOAD BX, [BP + 8]");
    asm("MOV AX, 6");
    asm("syscall");
}

int http_get(char *host, int port, char *path, char *response_buf, int max_len) {
    int fd = net_connect(host, port);
    if (fd < 0) {
        return fd;
    }

    // Build HTTP request in a buffer at 0xD000
    // "GET <path> HTTP/1.0\r\nHost: <host>\r\nConnection: close\r\n\r\n"
    char *req = 0xD000;
    char *p = req;

    // Copy "GET "
    char *g = "GET ";
    while (*g != 0) {
        *p = *g;
        p = p + 1;
        g = g + 1;
    }
    // Copy path
    char *pp = path;
    while (*pp != 0) {
        *p = *pp;
        p = p + 1;
        pp = pp + 1;
    }
    // Copy " HTTP/1.0\r\nHost: "
    char *h1 = " HTTP/1.0\r\nHost: ";
    while (*h1 != 0) {
        *p = *h1;
        p = p + 1;
        h1 = h1 + 1;
    }
    // Copy host
    char *hh = host;
    while (*hh != 0) {
        *p = *hh;
        p = p + 1;
        hh = hh + 1;
    }
    // Copy "\r\nConnection: close\r\n\r\n"
    char *h2 = "\r\nConnection: close\r\n\r\n";
    while (*h2 != 0) {
        *p = *h2;
        p = p + 1;
        h2 = h2 + 1;
    }
    *p = 0;

    // Calculate request length
    int req_len = p - req;

    // Send request
    net_send(fd, req, req_len);

    // Read response in chunks
    int total = 0;
    int chunk = 1;
    while (chunk > 0 && total < max_len) {
        int remain = max_len - total;
        if (remain > 512) {
            remain = 512;
        }
        chunk = net_recv(fd, response_buf + total, remain);
        if (chunk > 0) {
            total = total + chunk;
        }
    }

    // Null-terminate
    *(response_buf + total) = 0;

    net_close(fd);
    return total;
}
