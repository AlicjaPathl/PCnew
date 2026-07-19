#ifndef HTTP_H
#define HTTP_H

// Connect to a TCP host. Returns socket file descriptor or -1.
// Syscall AX=50, CX=host_addr, DX=port -> AX=fd
int net_connect(char *host, int port);

// Send raw data over socket fd. Uses fwrite internally.
int net_send(int fd, char *data, int len);

// Receive raw data from socket fd. Uses fread internally.
int net_recv(int fd, char *buf, int max_len);

// Close socket. Uses fclose internally.
int net_close(int fd);

// High-level: perform HTTP GET and return response length.
// Builds "GET path HTTP/1.0\r\nHost: host\r\n\r\n", sends it,
// and reads the full response into response_buf.
int http_get(char *host, int port, char *path, char *response_buf, int max_len);

#endif
