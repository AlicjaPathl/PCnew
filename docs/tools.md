# Narzędzia CLI

Przegląd wszystkich narzędzi w projekcie PC VM.

> **Windows:** jeśli polecenie `python` nie działa, użyj `py` (Python Launcher).

---

## vm.py — Maszyna wirtualna

Uruchamia obraz dysku `.ds`.

```powershell
py vm.py                    # domyślnie disk.ds
py vm.py program.ds         # wskazany obraz
py vm.py program.ds arg1 arg2   # argumenty CLI (argc/argv)
```

**Rejestry przy starcie `main`:**
- `AX` = liczba argumentów (`argc`)
- `BX` = wskaźnik tablicy `argv`

---

## cc.py — Kompilator C

Kompiluje Vanilla-C → assembler `.s` → obraz `.ds`.

```powershell
py cc.py program.c                  # → program.s + program.ds
py cc.py program.c output.s         # własna nazwa pliku ASM
```

Automatycznie dołącza biblioteki z `std/` na podstawie `#include`.

Szczegóły składni: [c_programming.md](c_programming.md)

---

## comp.py — Asembler

### Tryb szybki (pojedynczy plik)

```powershell
py comp.py hello.s              # → hello.ds
py comp.py hello.s out.ds       # własna nazwa wyjścia
```

Wymaga poprawnego bootloadera w pliku `.s`:
- etykieta `_global` na adresie 0
- `MOV 0xF000, n_boot` + `syscall` + skok do `_start`
- `n_boot db "BOOT"`

Przykład: [examples/hello.s](examples/hello.s)

### Tryb interaktywny (multi-sektor)

```powershell
py comp.py
```

Kompiluje `main.s` do sektora 0, a następnie pyta o pozostałe pliki `.s` w katalogu projektu.

---

## pyt.py — Interpreter Pythona

Własny interpreter (AST-walker), bez `exec()`/`eval()`.

```powershell
py pyt.py script.py
py pyt.py script.py arg1 arg2
```

Szczegóły: [pyt_interpreter.md](pyt_interpreter.md)

---

## build_exe.py — Builder .exe

Pakuje VM + obraz dysku w jeden plik `.exe` (wymaga PyInstaller).

```powershell
pip install pyinstaller
py build_exe.py                     # pakuje disk.ds
py build_exe.py program.ds          # wskazany obraz
py build_exe.py program.ds MyApp    # własna nazwa exe
```

---

## write.py — Wgrywanie na Arduino

Konwertuje `.ds` → `disk.h` i wgrywa szkic Arduino.

```powershell
py write.py                         # disk.ds → COM3, arduino:avr:uno
py write.py program.ds COM5         # własny port
py write.py program.ds COM3 arduino:avr:mega
```

---

## ardc.py — Kompilator C dla Arduino

Kompiluje C z nagłówkami `ard.h` / `display.h`.

```powershell
py ardc.py program.c                        # → program.s + program.ds
py ardc.py program.c --upload               # + wgrywanie
py ardc.py program.c --upload --port COM5   # własny port
```

Przykład: `ard_hello.c`

Szczegóły API: [arduino_vm.md](arduino_vm.md)

---

## ards.py — Asembler dla Arduino

```powershell
py ards.py program.s
py ards.py program.s --upload --port COM3
```

---

## ardpy.py — Monitor Serial Arduino

Odbiera pakiety `@LCD0|`, `@BOOT|`, `@HALT|` i emuluje LCD w terminalu.

```powershell
pip install pyserial
py ardpy.py                         # COM3, 9600 baud
py ardpy.py --port COM5
py ardpy.py --port COM3 --baud 115200
py ardpy.py --port COM3 --cmd "@RESET"
py ardpy.py --no-lcd                # bez rysowania LCD
```

---

## livemonitor.py — Edytor LCD na żywo

Kompiluje `live_editor.c`, wgrywa na Arduino i umożliwia pisanie na LCD z klawiatury PC.

```powershell
pip install pyserial
py livemonitor.py
py livemonitor.py --port COM5
py livemonitor.py --no-upload       # tylko monitor (bez wgrywania)
```

Wymaga Arduino CLI (`arduino-cli`) do wgrywania.

---

## docs/test_all.py — Testy automatyczne

```powershell
py docs/test_all.py
```

Sprawdza kompilację, uruchomienie VM, `pyt.py` i kompletność dokumentacji.

Szczegóły: [testing.md](testing.md)

---

## Inne pliki

| Plik | Opis |
|------|------|
| `op.py` | Opcodes VM — używany przez `vm.py` i `comp.py` |
| `conf_vm.toml` | Konfiguracja RAM/SP/boot |
| `live_editor.c` | Program edytora LCD dla `livemonitor.py` |
| `up.py` | Pomocniczy skrypt aktualizacji |
