# Przewodnik Szybkiego Startu

## Co to jest PC VM?

**PC VM** to kompletny ekosystem programowania składający się z:

| Komponent | Plik | Opis |
|-----------|------|------|
| 🖥️ **Maszyna wirtualna** | `vm.py` | 32-bit big-endian VM z RAMem 64 KB |
| ⚙️ **Kompilator C** | `cc.py` | Kompiluje Vanilla-C → ASM → obraz dysku `.ds` |
| 🔧 **Asembler** | `comp.py` | Kompiluje ASM `.s` → obraz dysku `.ds` |
| 🐍 **Interpreter Python** | `pyt.py` | Własny interpreter Pythona (AST-walker) |
| 📦 **Builder .exe** | `build_exe.py` | Pakuje VM + program do pliku `.exe` |

---

## Pierwsze kroki

> **Windows:** jeśli `python` nie działa, użyj `py` zamiast `python`.

### 1. Napisz program w C

```c
// hello.c
#include <stdio.h>

int main() {
    print_string("Hello, World!\n");
    return 0;
}
```

### 2. Skompiluj

```bash
py cc.py hello.c
# → hello.s  (asembler)
# → hello.ds (obraz dysku)
```

### 3. Uruchom na VM

```bash
py vm.py hello.ds
# BOOT
# Hello, World!
```

---

## Napisz program w ASM

```asm
; hello.s
_global:
    MOV 0xF000, n_boot
    MOV AX, 0
    syscall
    JMP _start

_start:
    MOV AX, 1
    MOV CX, msg
    SYSCALL
    MOV AX, 60
    MOV CX, 0
    SYSCALL

msg db "Hello from ASM!"
n_boot db "BOOT"
```

```bash
py comp.py hello.s hello.ds
py vm.py hello.ds
```

---

## Użyj interpretera Pythona

```python
# script.py
def fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

print("Fib(10) =", fib(10))

class Counter:
    def __init__(self):
        self.count = 0
    def inc(self):
        self.count += 1
    def __repr__(self):
        return f"Counter({self.count})"

c = Counter()
for _ in range(5):
    c.inc()
print(c)
```

```bash
py pyt.py script.py
# Fib(10) = 55
# Counter(5)
```

---

## Toolchain — schemat

```
        ┌──────────┐   cc.py   ┌─────────┐   comp.py  ┌────────┐
 .c ───►│ C source │──────────►│  .s ASM │───────────►│  .ds   │
        └──────────┘           └─────────┘            └────┬───┘
                                                           │
        ┌──────────┐  comp.py                         ┌────▼───┐
 .s ───►│ ASM src  │─────────────────────────────────►│ vm.py  │
        └──────────┘                                  └────────┘

        ┌──────────┐  pyt.py
 .py ──►│ Python   │──────────► własny interpreter (AST-walker)
        └──────────┘
```

---

## Funkcje języka C obsługiwane przez cc.py

- ✅ `int`, `char`, `void`, wskaźniki (`int*`, `char*`)
- ✅ Tablice lokalne (`int arr[16]`, `char buf[256]`)
- ✅ Funkcje z argumentami i zwracaniem wartości
- ✅ Rekurencja
- ✅ `if`/`else`, `while`, `for`
- ✅ Operatory: `+`, `-`, `*`, `/`, `%`, `&&`, `||`, `!`, `<`, `>`, `==`, `!=`, `<=`, `>=`
- ✅ Bitowe: `&`, `|`, `^`, `~`, `<<`, `>>`
- ✅ Preprocesor: `#include`, `#define`
- ✅ `asm("instrukcja")` — wbudowany asembler
- ✅ Argumenty CLI: `main(int argc, char *argv[])`
- ✅ Wskaźnikowa arytmetyka (`ptr + i`, `*(ptr + i)`)

---

## Argumenty CLI do programu

```c
#include <stdio.h>

int main(int argc, char *argv[]) {
    print_string("Argumenty: ");
    print_int(argc);
    print_string("\n");
    return 0;
}
```

```bash
py vm.py program.ds arg1 arg2
```

---

## Zbuduj .exe

```bash
pip install pyinstaller
py build_exe.py hello.ds hello.exe
./hello.exe
```

---

## Testy

```bash
py docs/test_all.py
```

---

## Konfiguracja VM (`conf_vm.toml`)

```toml
[vm]
ram_size         = 65536    # RAM w bajtach (max 65536)
sp_start         = 65536    # startowy Stack Pointer
boot_string_addr = 61440    # adres napisu startowego (0xF000)
```

---

## Pliki projektu

```
PCnew/
├── vm.py          ← maszyna wirtualna
├── cc.py          ← kompilator C
├── comp.py        ← asembler
├── pyt.py         ← interpreter Pythona (od zera)
├── build_exe.py   ← builder .exe
├── conf_vm.toml   ← konfiguracja VM
├── std/           ← biblioteka standardowa
│   ├── stdio.h/c      I/O: print_string, getchar, ...
│   ├── stdlib.h/c     exit, delay
│   ├── string.h/c     strlen, strcpy, strcmp
│   ├── fileio.h/c     fopen, fread, fwrite, fclose
│   ├── gui.h/c        GUI: okna, przyciski, zdarzenia
│   └── http.h/c       sieć: TCP socket, HTTP GET
├── docs/          ← dokumentacja
│   ├── README.md           ← spis treści
│   ├── getting_started.md  ← ten plik
│   ├── architecture.md     ← VM, rejestry, syscalle
│   ├── assembly.md         ← lista instrukcji ASM
│   ├── c_programming.md    ← programowanie w C
│   ├── stdlib.md           ← biblioteka standardowa
│   ├── pyt_interpreter.md  ← interpreter Pythona
│   ├── arduino_vm.md       ← Arduino VM
│   ├── tools.md            ← narzędzia CLI
│   ├── testing.md          ← testy automatyczne
│   ├── troubleshooting.md  ← rozwiązywanie problemów
│   ├── test_all.py         ← skrypt testów
│   └── examples/           ← przykłady (hello.s, pyt_demo.py)
└── main.s         ← test suite instrukcji ASM
```
