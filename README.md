# PC VM

Kompletny ekosystem programowania: własna maszyna wirtualna 32-bit, kompilator C, asembler, interpreter Pythona i wsparcie Arduino.

## Szybki start

```powershell
# Windows — użyj `py` zamiast `python`, jeśli python nie jest w PATH
py cc.py test.c
py vm.py test.ds
```

```bash
# Linux / macOS
python cc.py test.c
python vm.py test.ds
```

## Dokumentacja

Pełna dokumentacja znajduje się w katalogu [`docs/`](docs/README.md):

| Temat | Plik |
|-------|------|
| Indeks i mapa dokumentacji | [docs/README.md](docs/README.md) |
| Pierwsze kroki | [docs/getting_started.md](docs/getting_started.md) |
| Architektura VM | [docs/architecture.md](docs/architecture.md) |
| Asembler (.s) | [docs/assembly.md](docs/assembly.md) |
| Kompilator C (cc.py) | [docs/c_programming.md](docs/c_programming.md) |
| Biblioteka standardowa | [docs/stdlib.md](docs/stdlib.md) |
| Interpreter Pythona | [docs/pyt_interpreter.md](docs/pyt_interpreter.md) |
| Arduino VM | [docs/arduino_vm.md](docs/arduino_vm.md) |
| Narzędzia CLI | [docs/tools.md](docs/tools.md) |
| Testy | [docs/testing.md](docs/testing.md) |
| Rozwiązywanie problemów | [docs/troubleshooting.md](docs/troubleshooting.md) |

## Testy

```powershell
py docs/test_all.py
```

## Struktura projektu

```
PCnew/
├── vm.py           # maszyna wirtualna
├── cc.py           # kompilator C → .s → .ds
├── comp.py         # asembler .s → .ds
├── pyt.py          # interpreter Pythona
├── build_exe.py    # pakowanie do .exe
├── ardc.py         # kompilator C dla Arduino
├── ards.py         # asembler dla Arduino
├── ardpy.py        # monitor serial Arduino
├── livemonitor.py  # edytor LCD na żywo
├── conf_vm.toml    # konfiguracja VM
├── std/            # biblioteka standardowa C
├── ard/            # nagłówki Arduino
└── docs/           # dokumentacja + testy
```
