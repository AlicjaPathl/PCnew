# Rozwiązywanie problemów

Typowe problemy i ich rozwiązania przy pracy z PC VM.

---

## `python` nie jest rozpoznawane (Windows)

**Objaw:**
```
The term 'python' is not recognized...
```

**Rozwiązanie:** użyj Python Launchera:

```powershell
py --version
py cc.py test.c
py vm.py test.ds
```

Alternatywnie dodaj Python do PATH lub użyj pełnej ścieżki do `python.exe`.

---

## UnicodeEncodeError przy uruchamianiu VM

**Objaw:**
```
UnicodeEncodeError: 'charmap' codec can't encode character ...
```

**Przyczyna:** konsola Windows (cp1250/cp1252) nie obsługuje niektórych znaków drukowanych przez program.

**Rozwiązania:**

```powershell
# Opcja 1: włącz UTF-8 dla Pythona
$env:PYTHONUTF8 = "1"
py vm.py program.ds

# Opcja 2: zmień kodowanie konsoli na UTF-8 (Windows Terminal)
chcp 65001

# Opcja 3: używaj ASCII w stringach programu
```

Testy automatyczne (`docs/test_all.py`) ustawiają `PYTHONUTF8=1` automatycznie.

---

## BOOT ERROR przy kompilacji .s

**Objaw:**
```
BOOT ERROR: '_global' label missing or not at address 0
BOOT ERROR: 'MOV 0xF000, ...' missing
BOOT ERROR: String for boot label must contain 'BOOT'
```

**Rozwiązanie:** każdy plik `.s` musi zaczynać się od:

```asm
_global:
    MOV 0xF000, n_boot
    MOV AX, 0
    syscall
    JMP _start

_start:
    ; ... kod programu ...

n_boot db "BOOT"
```

Adres `0xF000` musi odpowiadać `boot_string_addr` w `conf_vm.toml`.

---

## Etykieta numeryczna w asemblerze

**Objaw:**
```
COMPILE ERROR: Label '42' is a plain number. Use a name like 'n_42' instead.
```

**Rozwiązanie:** etykiety nie mogą być samymi liczbami. Użyj prefiksu:

```asm
n_42:
    MOV AX, 42
```

---

## Brak modułu pyserial / pyinstaller

```powershell
pip install pyserial      # ardpy.py, livemonitor.py
pip install pyinstaller   # build_exe.py
```

---

## Arduino — brak połączenia serial

**Objaw:** `ardpy.py` nie odbiera pakietów.

**Sprawdź:**
1. Poprawny port COM: `py ardpy.py --port COM5`
2. Zainstalowany sterownik USB Arduino
3. Inny program (Arduino IDE Serial Monitor) nie blokuje portu
4. Zgodna prędkość: `--baud 9600` (domyślnie) lub `--baud 115200`

Lista portów (z pyserial):

```powershell
py -c "import serial.tools.list_ports; print([p.device for p in serial.tools.list_ports.comports()])"
```

---

## GUI nie otwiera okna

**Przyczyna:** brak Tkinter w instalacji Pythona.

**Rozwiązanie:** zainstaluj Python z opcją „tcl/tk” lub:

```powershell
# Windows — reinstalacja Python z python.org z zaznaczonym Tcl/Tk
py cc.py test_gui.c
py vm.py test_gui.ds
```

---

## HTTP test nie działa

**Przyczyny:**
- Brak połączenia internetowego
- Firewall blokuje socket TCP
- Serwer docelowy niedostępny

Test HTTP (`test_http.c`) nie jest częścią `docs/test_all.py` — uruchamiaj go ręcznie.

---

## Kompilator C — nieobsługiwana składnia

Pełna lista ograniczeń: [c_programming.md](c_programming.md#ograniczenia-w-stosunku-do-gcc)

Najczęstsze:
- Brak `for` → użyj `while`
- Brak `struct`/`enum`/`typedef`
- Brak `printf` → użyj `print_string`, `print_int`
- Brak `malloc`/`free`

---

## pyt.py — błąd przy klasach

Jeśli interpreter zgłasza błąd przy `class`, upewnij się że używasz aktualnej wersji `pyt.py` (naprawiono obsługę `_globals = None`).

Test:

```powershell
py pyt.py docs/examples/pyt_demo.py
# Oczekiwane: Fib(10) = 55 + Counter(5)
```

---

## comp.py pyta o sektory interaktywnie

**Przyczyna:** uruchomiono `py comp.py` bez argumentów — tryb multi-sektor.

**Rozwiązanie:** podaj plik wejściowy:

```powershell
py comp.py program.s program.ds
```

---

## Plik .ds wygląda jak ciąg zer i jedynek

To prawidłowy format — obraz dysku jest zapisany jako ciąg bitów (8 bitów na bajt). VM i kompilatory czytają go poprawnie; nie edytuj ręcznie.
