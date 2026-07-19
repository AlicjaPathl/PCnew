# Testy

Projekt zawiera testy automatyczne weryfikujące dokumentację i podstawowy toolchain.

## Uruchomienie wszystkich testów

```powershell
py docs/test_all.py
```

Oczekiwany wynik:

```
PC VM — testy dokumentacji
========================================
  [OK] komplet plikow docs/
  [OK] cc.py + vm.py (test.c)
  [OK] fileio (test_fileio.c)
  [OK] comp.py CLI + vm.py (main.s)
  [OK] hello.s przyklad z dokumentacji
  [OK] pyt.py (docs/examples/pyt_demo.py)
========================================
Wszystkie testy przeszly pomyslnie.
```

## Co jest testowane

| Test | Pliki | Weryfikacja |
|------|-------|-------------|
| Kompilator C | `test.c` | rekurencja, stringi, operatory logiczne |
| File I/O | `test_fileio.c` | `fopen`/`fread`/`fwrite`/`fclose` |
| Asembler CLI | `main.s` | wszystkie instrukcje, skoki, CALL/RET |
| Przykład hello.s | `docs/examples/hello.s` | minimalny program z docs |
| Interpreter | `docs/examples/pyt_demo.py` | fib, klasy |
| Dokumentacja | `docs/*.md` | kompletność plików |

## Testy manualne (opcjonalne)

### GUI — wymaga Tkinter

```powershell
py cc.py test_gui.c
py vm.py test_gui.ds
```

Otwiera okno 400×300 z przyciskami. Zamknij przyciskiem „Exit” lub ESC.

### HTTP — wymaga sieci

```powershell
py cc.py test_http.c
py vm.py test_http.ds
```

Wysyła HTTP GET do `httpbin.org`. Wymaga aktywnego połączenia internetowego.

### Arduino — wymaga sprzętu

```powershell
py ardc.py ard_hello.c --upload --port COM3
py ardpy.py --port COM3
```

Wymaga podłączonego Arduino, `pyserial` i `arduino-cli`.

### Builder .exe — wymaga PyInstaller

```powershell
pip install pyinstaller
py build_exe.py test.ds test_app
.\test_app.exe
```

## Dodawanie własnych testów

1. Dodaj funkcję `test_*()` w `docs/test_all.py`
2. Wywołaj ją w `main()`
3. Użyj helperów `run()`, `expect_in()`, `ok()`, `fail()`

Przykład:

```python
def test_my_feature() -> None:
    r = run([PY, "cc.py", "my_test.c"])
    if r.returncode != 0:
        fail("my_test.c compile", r.stderr or r.stdout)
    r = run([PY, "vm.py", "my_test.ds"])
    expect_in(r.stdout, "EXPECTED OUTPUT")
    ok("my feature")
```

## Test suite asemblera (main.s)

Plik `main.s` zawiera wbudowane testy wszystkich instrukcji:

```powershell
py comp.py main.s main.ds
py vm.py main.ds
# Oczekiwany wynik: BOOT + OK: WSZYSTKO
```

Testowane operacje: SUB/MUL/DIV, MOD, INC/DEC/NEG, AND/OR/XOR, SHL/SHR, NOT, PUSH/POP, JG/JGE/JLE, CALL/RET (silnia).
