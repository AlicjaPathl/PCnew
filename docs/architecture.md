# Architektura VM (Maszyna Wirtualna)

## Przegląd

VM jest 32-bitową, big-endian maszyną wirtualną z architekturą stosową, kompilowaną w Pythonie. Każda instrukcja zajmuje dokładnie **9 bajtów**.

```
┌────────────────────────────────────────────┐
│               RAM (65 536 B)               │
│  0x0000 ─ kod programu (ładowany z .ds)    │
│  0x????  ─ dane (stringi, zmienne globalne)│
│  0xD000  ─ bufor HTTP request (http_get)   │
│  0xE000  ─ bufor parametrów GUI (24 B)     │
│  0xF000  ─ boot string pointer             │
│  0xFFFF  ─ szczyt stosu (SP start)         │
└────────────────────────────────────────────┘
```

## Rejestry

| Rejestr | Nr | Opis |
|---------|-----|------|
| `AX`    | 0   | Rejestr akumulatora / wynik syscall / argc |
| `BX`    | 1   | Rejestr ogólny / argv ptr |
| `CX`    | 2   | Rejestr ogólny / adres stringu syscall |
| `DX`    | 3   | Rejestr ogólny / tryb file I/O / port sieciowy |
| `SP`    | 4   | Stack Pointer — wskazuje na szczyt stosu |
| `BP`    | 5   | Base Pointer — wskazuje na ramkę stosu funkcji |

## Flagi

| Flaga | Opis |
|-------|------|
| `ZF`  | Zero Flag — ustawiona gdy wynik CMP = 0 |
| `LF`  | Less Flag — ustawiana gdy lewy operand CMP < prawy |

## Pamięć i stos

- RAM: **65 536 bajtów** (konfigurowalny w `conf_vm.toml`)
- Stos rośnie **w dół** (SP maleje przy PUSH)
- `SP` start: `65536` (za ostatnim bajtem)
- Każdy element stosu = **4 bajty** (big-endian uint32)

## Format instrukcji

Każda instrukcja = 9 bajtów:

```
[OPCODE 1B] [MODE 1B] [DEST 2B] [SRC/ADDR 4B] [PAD 1B]
```

lub dla skoków:

```
[OPCODE 1B] [TARGET_ADDR 8B]
```

## Syscalle

### I/O (AX 0–2)

| AX | Syscall | Opis |
|----|---------|------|
| 0  | `print_boot` | Drukuje string z adresu boot_string_ptr w RAM |
| 1  | `print_string` | Drukuje string z adresu w CX |
| 2  | `read_int` | Wczytuje liczbę całkowitą do adresu w CX |

### Pliki (AX 3–6)

| AX | Syscall | Opis |
|----|---------|------|
| 3  | `fopen`  | Otwiera plik: CX=nazwa, DX=0(read)/1(write) → AX=fd |
| 4  | `fread`  | Czyta z fd/socket: BX=fd, CX=buf, DX=count → AX=bytes |
| 5  | `fwrite` | Zapisuje do fd/socket: BX=fd, CX=buf, DX=count → AX=bytes |
| 6  | `fclose` | Zamyka fd/socket: BX=fd → AX=0/−1 |

### Dysk (AX 25)

| AX | Syscall | Opis |
|----|---------|------|
| 25 | `disk_read` | Czyta sektor nr BX z dysku do bufora disk_buffer |

### GUI — Mini-Qt (AX 30–36)

| AX | Syscall | Opis |
|----|---------|------|
| 30 | `gui_init`       | Tworzy okno: BX=w, CX=h, DX=title_addr |
| 31 | `gui_clear`      | Czyści ekran: BX=kolor (0xRRGGBB) |
| 32 | `gui_draw_rect`  | Rysuje prostokąt: BX=params_addr (6×uint32: x,y,w,h,color,fill) |
| 33 | `gui_draw_line`  | Rysuje linię: BX=params_addr (5×uint32: x1,y1,x2,y2,color) |
| 34 | `gui_draw_text`  | Rysuje tekst: BX=params_addr (5×uint32: x,y,color,str_addr,font_sz) |
| 35 | `gui_poll_event` | Pobiera zdarzenie: BX=buf(16B) → AX=1/0 |
| 36 | `gui_present`    | Odświeża okno (flush) |

**Typy zdarzeń (gui_poll_event):**

| Wartość | Zdarzenie |
|---------|-----------|
| 1 | Kliknięcie lewym przyciskiem myszy |
| 2 | Kliknięcie prawym przyciskiem myszy |
| 3 | Wciśnięcie klawisza |
| 4 | Zwolnienie klawisza |
| 5 | Ruch myszy |

### Sieć (AX 50)

| AX | Syscall | Opis |
|----|---------|------|
| 50 | `net_connect` | Otwiera socket TCP: CX=host_addr, DX=port → AX=fd lub 0xFFFFFFFF |

> Socket fd jest kompatybilny z `fread`/`fwrite`/`fclose` (AX 4,5,6).

### Kontrola (AX 60)

| AX | Syscall | Opis |
|----|---------|------|
| 60 | `exit` | Kończy program; CX=1 drukuje "HALTED" |

## Sektory dysku

Obraz `.ds` składa się z **512-bajtowych sektorów**. 4-bajtowy nagłówek zawiera adres entry point. Sektor 0 zawiera zawsze bootloader/entry (`_global`).

## Konfiguracja (`conf_vm.toml`)

```toml
[vm]
ram_size          = 65536   # rozmiar RAM w bajtach
sp_start          = 65536   # adres startowy SP
boot_string_addr  = 61440   # 0xF000 — wskaźnik boot stringa
```
