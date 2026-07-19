#ifndef FILEIO_H
#define FILEIO_H

// File open modes
#define FILE_READ  0
#define FILE_WRITE 1

// Open a file. Returns file descriptor (>= 3) or -1 on error.
// Syscall AX=3: CX=filename_addr, DX=mode (0=read, 1=write) -> AX=fd
int fopen(char *filename, int mode);

// Read count bytes from fd into buffer. Returns bytes read or -1.
// Syscall AX=4: BX=fd, CX=buf_addr, DX=count -> AX=bytes_read
int fread(int fd, char *buf, int count);

// Write count bytes from buffer to fd. Returns bytes written or -1.
// Syscall AX=5: BX=fd, CX=buf_addr, DX=count -> AX=bytes_written
int fwrite(int fd, char *buf, int count);

// Close file descriptor. Returns 0 on success or -1 on error.
// Syscall AX=6: BX=fd -> AX=result
int fclose(int fd);

#endif
