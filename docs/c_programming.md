# Kompilacja C — cc.py

## Wprowadzenie

`cc.py` kompiluje programy C do assemblera `.s` a następnie do obrazu dysku `.ds`. Składnia jest maksymalnie zgodna z GCC/ANSI C dla prostych programów.

## Użycie

```powershell
# Kompiluje program.c -> program.s -> program.ds
py cc.py program.c

# Podaj własną nazwę pliku .s (opcjonalnie)
py cc.py program.c moj_asm.s
```

## Obsługiwana składnia C

### Typy danych

| Typ C     | Rozmiar na stosie | Opis |
|-----------|-------------------|------|
| `int`     | 4 bajty           | 32-bitowa liczba całkowita ze znakiem |
| `char`    | 1 bajt (w arr)    | Znak (liczba 8-bitowa) |
| `void`    | —                 | Typ zwracany "nic" |
| `int *`   | 4 bajty           | Wskaźnik 32-bitowy |
| `char *`  | 4 bajty           | Wskaźnik na string |
| `int arr[N]`  | N × 4 B      | Statyczna tablica całkowitoliczbowa |
| `char buf[N]` | N bajtów     | Statyczny bufor bajtowy |

### Zmienne globalne

```c
int global_x = 10;
char *msg = "Hello!";
```

### Zmienne lokalne i tablice

```c
int x = 5;
char buf[64];        // tablica na stosie — automatycznie zerowana
int arr[10];
```

### Operatory

```c
+ - * / %          // arytmetyczne
== != < <= > >=    // porównania (zwracają 0 lub 1)
&& ||              // logiczne AND/OR
<< >>              // przesunięcia bitowe
& (prefix)         // adres zmiennej: &x
* (prefix)         // dereferencja wskaźnika: *ptr
```

### Instrukcje sterujące

```c
if (warunek) { ... }
if (warunek) { ... } else { ... }
while (warunek) { ... }
return expr;
break;
```

### Wywołania funkcji

```c
int wynik = factorial(5);
print_string("Hello\n");
```

### Inline assembler

```c
asm("MOV AX, 42");
asm("LOAD CX, [BP + 8]");
```

Instrukcja `asm(...)` wstawia surowy kod assemblera bezpośrednio do wygenerowanego pliku `.s`.

## Biblioteka standardowa

### stdio.h

```c
#include <stdio.h>

void print_string(char *s);   // drukuje string (syscall 1)
void print_int(int val);       // drukuje liczbę całkowitą
void putchar(char c);          // drukuje jeden znak
int  getchar();                // wczytuje liczbę (syscall 2)
```

### stdlib.h

```c
#include <stdlib.h>

void delay(int ms);    // czeka ms milisekund
void exit(int code);   // kończy program (syscall 60)
```

### string.h

```c
#include <string.h>

int  strlen(char *s);                  // długość stringa
void strcpy(char *dest, char *src);    // kopiuje string
int  strcmp(char *s1, char *s2);       // porównuje stringi
```

### fileio.h

```c
#include <fileio.h>

int fopen(char *filename, int mode);        // 0=read, 1=write -> fd
int fread(int fd, char *buf, int count);    // czyta bytes -> ile przeczytano
int fwrite(int fd, char *buf, int count);   // zapisuje -> ile zapisano
int fclose(int fd);                         // zamyka -> 0 lub -1
```

## Argumenty wiersza poleceń

```c
int main() {
    // AX = argc (liczba argumentów) — przy wejściu do main
    // BX = argv (adres tablicy wskaźników do stringów)
    asm("LOAD AX, [BP + 8]");   // argc
    asm("LOAD BX, [BP + 12]");  // argv
    ...
}
```

Z poziomu VM:
```powershell
py vm.py program.ds arg1 arg2 arg3
```

## Przykładowy program C

```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int suma(int a, int b) {
    return a + b;
}

int main() {
    print_string("Kalkulator startuje!\n");

    int x = 15;
    int y = 27;
    int wynik = suma(x, y);

    print_string("Wynik: ");
    print_int(wynik);
    print_string("\n");

    char buf[32];
    strcpy(buf, "Skopiowano!");
    print_string(buf);
    print_string("\n");

    exit(0);
    return 0;
}
```

Kompilacja i uruchomienie:
```powershell
py cc.py kalkulator.c    # -> kalkulator.s + kalkulator.ds
py vm.py kalkulator.ds   # -> wynik na konsoli
```

## Ograniczenia (w stosunku do GCC)

- Brak `for` (użyj `while`)
- Brak `struct` / `union` / `enum`
- Brak `typedef`
- Brak operatora `?:` (ternary)
- Brak globalnych tablic (tylko lokalne przez wskaźnik)
- Brak `printf` / `scanf` — użyj `print_string`, `print_int`, `getchar`
- Brak `malloc` / `free` — alokacja przez wskaźnik do adresu RAM

## Wygenerowany assembler

Każde wywołanie `cc.py` produkuje dwa pliki:
- **`program.s`** — czytelny kod assemblera z etykietami
- **`program.ds`** — binarny obraz dysku gotowy do `vm.py`
