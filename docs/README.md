# Dokumentacja PC VM

Kompletny przewodnik po ekosystemie **PC VM** — maszynie wirtualnej, kompilatorze C, asemblerze, interpreterze Pythona i narzędziach Arduino.

## Spis treści

### Podstawy

1. **[Przewodnik szybkiego startu](getting_started.md)** — pierwszy program w C, ASM i Pythonie
2. **[Architektura VM](architecture.md)** — RAM, rejestry, format instrukcji, syscalle
3. **[Rozwiązywanie problemów](troubleshooting.md)** — Windows, encoding, typowe błędy

### Programowanie

4. **[Asembler (.s)](assembly.md)** — składnia, instrukcje, konwencje wywołań
5. **[Kompilacja C (cc.py)](c_programming.md)** — obsługiwana składnia, ograniczenia
6. **[Biblioteka standardowa (std/)](stdlib.md)** — stdio, string, fileio, gui, http
7. **[Interpreter Pythona (pyt.py)](pyt_interpreter.md)** — własny interpreter AST-walker

### Platformy i narzędzia

8. **[Arduino VM](arduino_vm.md)** — LCD, GPIO, wgrywanie na mikrokontroler
9. **[Narzędzia CLI](tools.md)** — vm.py, comp.py, build_exe.py, ardpy.py i inne
10. **[Testy](testing.md)** — jak uruchomić i rozszerzyć testy

## Przykłady (`docs/examples/`)

| Plik | Opis |
|------|------|
| [hello.s](examples/hello.s) | Minimalny program w asemblerze |
| [pyt_demo.py](examples/pyt_demo.py) | Fibonacci + klasy dla `pyt.py` |

Programy testowe w katalogu głównym projektu:

| Plik | Opis |
|------|------|
| `test.c` | Arytmetyka, rekurencja, stringi |
| `test_fileio.c` | Zapis i odczyt pliku |
| `test_gui.c` | Okno GUI (wymaga Tkinter) |
| `test_http.c` | HTTP GET (wymaga sieci) |
| `main.s` | Pełny test suite instrukcji ASM |
| `ard_hello.c` | Hello World na Arduino |

## Szybka ściągawka

```powershell
# C → dysk → VM
py cc.py program.c
py vm.py program.ds

# ASM → dysk → VM
py comp.py program.s program.ds
py vm.py program.ds

# Python (własny interpreter)
py pyt.py script.py

# Testy dokumentacji
py docs/test_all.py
```

## Toolchain

```
 .c  ──cc.py──►  .s  ──comp.py──►  .ds  ──vm.py──►  wynik
 .s  ──────────comp.py──────────►  .ds  ──vm.py──►  wynik
 .py ──pyt.py──────────────────────────────────────►  wynik
```

## Konfiguracja

Plik [`conf_vm.toml`](../conf_vm.toml) kontroluje rozmiar RAM, stack pointer i adres boot stringa.
