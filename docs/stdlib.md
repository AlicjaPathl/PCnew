# Biblioteka Standardowa (std/)

Katalog `std/` zawiera implementacje bibliotek standardowych dostępnych podczas kompilacji przez `cc.py`.
Każda biblioteka to para pliku `.h` (deklaracje) i `.c` (implementacja syscallami VM).

---

## stdio.h — Wejście/Wyjście

```c
#include <stdio.h>
```

| Funkcja | Opis |
|---------|------|
| `void print_string(char *s)` | Drukuje string na stdout |
| `void print_int(int n)` | Drukuje liczbę całkowitą |
| `void putchar(int c)` | Drukuje jeden znak |
| `int getchar()` | Czyta jeden znak ze stdin |

**Przykład:**
```c
#include <stdio.h>

int main() {
    print_string("Hello, World!\n");
    print_int(42);
    print_string("\n");
    return 0;
}
```

---

## stdlib.h — Narzędzia ogólne

```c
#include <stdlib.h>
```

| Funkcja | Opis |
|---------|------|
| `void exit(int code)` | Kończy program z kodem wyjścia |
| `void delay(int ms)` | Czeka podaną liczbę milisekund |

---

## string.h — Operacje na stringach

```c
#include <string.h>
```

| Funkcja | Opis |
|---------|------|
| `int strlen(char *s)` | Długość stringu |
| `void strcpy(char *dst, char *src)` | Kopiowanie stringu |
| `int strcmp(char *a, char *b)` | Porównanie stringów (0 = równe) |

**Przykład:**
```c
#include <string.h>
#include <stdio.h>

int main() {
    char *src = "Hello";
    char dst[16];
    strcpy(dst, src);
    print_int(strlen(dst));
    return 0;
}
```

---

## fileio.h — Operacje na plikach

```c
#include <fileio.h>
```

| Funkcja | Opis |
|---------|------|
| `int fopen(char *name, int mode)` | Otwiera plik (mode: 0=read, 1=write) → fd |
| `int fread(int fd, char *buf, int n)` | Czyta `n` bajtów z pliku → liczba bajtów |
| `int fwrite(int fd, char *buf, int n)` | Zapisuje `n` bajtów do pliku → liczba bajtów |
| `int fclose(int fd)` | Zamyka plik → 0 lub -1 |

**Przykład:**
```c
#include <fileio.h>
#include <stdio.h>

int main() {
    // Zapis
    int fd = fopen("hello.txt", 1);
    char *msg = "Hello from VM!";
    fwrite(fd, msg, 14);
    fclose(fd);

    // Odczyt
    char buf[64];
    fd = fopen("hello.txt", 0);
    int n = fread(fd, buf, 63);
    fclose(fd);
    print_string(buf);
    return 0;
}
```

---

## gui.h — Graficzny interfejs użytkownika (Mini-Qt)

```c
#include <gui.h>
```

### Stałe kolorów

```c
#define COLOR_BLACK   0x000000
#define COLOR_WHITE   0xFFFFFF
#define COLOR_RED     0xFF0000
#define COLOR_GREEN   0x00FF00
#define COLOR_BLUE    0x0000FF
#define COLOR_YELLOW  0xFFFF00
#define COLOR_CYAN    0x00FFFF
#define COLOR_ORANGE  0xFF8800
#define COLOR_DARK    0x1A1A2E
#define COLOR_ACCENT  0x16213E
#define COLOR_PURPLE  0x533483
#define COLOR_TEAL    0x0F3460
```

### Typy zdarzeń

```c
#define EVT_NONE         0
#define EVT_MOUSE_LEFT   1
#define EVT_MOUSE_RIGHT  2
#define EVT_KEY_DOWN     3
#define EVT_KEY_UP       4
#define EVT_MOUSE_MOVE   5
```

### Funkcje

| Funkcja | Opis |
|---------|------|
| `void gui_init(int w, int h, char *title)` | Tworzy okno |
| `void gui_clear(int color)` | Czyści ekran kolorem |
| `void gui_draw_rect(int x, int y, int w, int h, int color, int fill)` | Prostokąt (fill=1 wypełniony) |
| `void gui_draw_line(int x1, int y1, int x2, int y2, int color)` | Linia |
| `void gui_draw_text(int x, int y, int color, char *text, int font_size)` | Tekst |
| `int gui_poll_event(int *event_buf)` | Zdarzenie → 1 jeśli zdarzenie, 0 jeśli brak |
| `void gui_present()` | Odśwież okno |

### Widget helpers (ImGui-style)

| Funkcja | Opis |
|---------|------|
| `void gui_panel(int x,y,w,h, int bg, int border)` | Panel z obwódką |
| `void gui_header(int x,y,w,h, char *title, int bg, int fg)` | Pasek tytułu |
| `void gui_label(int x, int y, char *text, int color, int font_size)` | Etykieta |
| `int gui_button(int x,y,w,h, char *text, int mx,my, int evt_type)` | Przycisk → 1 jeśli kliknięty |

### Przykład — okno z przyciskami

```c
#include <stdio.h>
#include <gui.h>

int main() {
    gui_init(400, 300, "Moje Okno");
    int ev[4];
    int running = 1;
    int mx = 0, my = 0, evt = 0;

    while (running) {
        evt = EVT_NONE;
        if (gui_poll_event(ev)) {
            evt = *(ev);
            mx  = *(ev + 1);
            my  = *(ev + 2);
        }

        gui_clear(COLOR_DARK);
        gui_panel(20, 20, 360, 260, COLOR_ACCENT, COLOR_WHITE);
        gui_header(20, 20, 360, 30, "Panel", COLOR_PURPLE, COLOR_WHITE);
        gui_label(40, 70, "Kliknij przycisk:", COLOR_CYAN, 12);

        if (gui_button(40, 110, 120, 36, "OK", mx, my, evt)) {
            print_string("OK kliknieto!\n");
        }
        if (gui_button(180, 110, 120, 36, "Wyjdz", mx, my, evt)) {
            running = 0;
        }

        gui_present();
        delay(16);
    }
    return 0;
}
```

---

## http.h — Sieć i HTTP

```c
#include <http.h>
```

| Funkcja | Opis |
|---------|------|
| `int net_connect(char *host, int port)` | Otwiera socket TCP → fd lub -1 |
| `int net_send(int fd, char *data, int len)` | Wysyła dane przez socket |
| `int net_recv(int fd, char *buf, int max)` | Odbiera dane z socketu |
| `int net_close(int fd)` | Zamyka socket |
| `int http_get(char *host, int port, char *path, char *buf, int max)` | Wysyła HTTP GET → liczba bajtów |

> **Uwaga:** Socket fd jest kompatybilny z `fread`/`fwrite`/`fclose` (są to te same syscalle).

### Przykład — HTTP GET

```c
#include <stdio.h>
#include <http.h>

int main() {
    char response[2048];
    int n = http_get("httpbin.org", 80, "/ip", response, 2000);
    if (n < 0) {
        print_string("Blad polaczenia!\n");
        return 1;
    }
    print_string(response);
    return 0;
}
```

### Przykład — raw TCP socket

```c
#include <stdio.h>
#include <http.h>

int main() {
    int fd = net_connect("example.com", 80);
    if (fd < 0) { print_string("Brak polaczenia\n"); return 1; }

    char *req = "GET / HTTP/1.0\r\nHost: example.com\r\n\r\n";
    net_send(fd, req, 40);

    char buf[1024];
    int n = net_recv(fd, buf, 1023);
    *(buf + n) = 0;
    print_string(buf);
    net_close(fd);
    return 0;
}
```
