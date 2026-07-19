# Assembler (.s) — Instrukcja

## Wprowadzenie

Pliki `.s` to kod assemblera dla VM. Kompiluje je `comp.py` do binarnych obrazów `.ds`.

## Składnia pliku .s

```asm
; komentarz liniowy

_etykieta:
    INSTRUKCJA arg1, arg2
    
dane db "tekst", 0
liczba db 0, 0, 0, 5     ; 4 bajty big-endian = 5
```

## Rejestry

`AX`, `BX`, `CX`, `DX`, `SP`, `BP`

## Instrukcje

### MOV — ładowanie wartości
```asm
MOV AX, 42          ; AX = 42
MOV AX, BX          ; AX = BX
MOV SP, 65536       ; SP = 65536
```

### LOAD / STORE — dostęp do pamięci
```asm
LOAD  AX, [0x1000]      ; AX = RAM[0x1000]    (adres bezpośredni)
LOAD  AX, [BX]          ; AX = RAM[BX]         (pośredni przez rejestr)
LOAD  AX, [BP + 8]      ; AX = RAM[BP + 8]     (BP + offset)
LOAD  AX, [BP - 4]      ; AX = RAM[BP - 4]     (BP - offset)
STORE AX, [0x1000]      ; RAM[0x1000] = AX
STORE AX, [BX]
STORE AX, [BP + 8]

; Operacje bajtowe (dla char *)
LOAD_B  AX, [BX]        ; AX = RAM[BX] (1 bajt)
STORE_B AX, [BX]        ; RAM[BX] = AX & 0xFF (1 bajt)
```

### Arytmetyka
```asm
ADD AX, BX       ; AX += BX
ADD AX, 10       ; AX += 10
SUB AX, BX       ; AX -= BX
MUL AX, BX       ; AX *= BX
DIV AX, BX       ; AX /= BX
MOD AX, BX       ; AX %= BX
NEG AX           ; AX = -AX
INC AX           ; AX++
DEC AX           ; AX--
```

### Bitowe
```asm
AND AX, BX       ; AX &= BX
OR  AX, BX       ; AX |= BX
XOR AX, BX       ; AX ^= BX
NOT AX           ; AX = ~AX
SHL AX, BX       ; AX <<= BX
SHR AX, BX       ; AX >>= BX
```

### Porównania i skoki
```asm
CMP AX, BX       ; porównuje AX z BX, ustawia ZF i LF
JMP etykieta     ; bezwarunkowy skok
JZ  etykieta     ; skok jeśli ZF=1 (AX == BX)
JNZ etykieta     ; skok jeśli ZF=0 (AX != BX)
JL  etykieta     ; skok jeśli LF=1 (AX < BX)
JLE etykieta     ; skok jeśli LF=1 lub ZF=1 (AX <= BX)
JG  etykieta     ; skok jeśli LF=0 i ZF=0 (AX > BX)
JGE etykieta     ; skok jeśli LF=0 (AX >= BX)
```

### Stos i wywołania funkcji
```asm
PUSH AX          ; odkłada AX na stos, SP -= 4
PUSH 42          ; odkłada wartość 42 na stos
POP  AX          ; ściąga ze stosu do AX, SP += 4
CALL etykieta    ; odkłada adres powrotu, skacze do etykiety
RET              ; ściąga adres powrotu, wraca
```

### Inne
```asm
syscall          ; wywołanie systemowe (AX = numer)
DELAY 500        ; czeka 500 ms
```

## Dyrektywa db — dane

```asm
napis  db "Hello, World!"        ; string zakończony bajtem 0
napis2 db "Linia\n"              ; \n = newline (ASCII 10)
liczba db 0, 0, 0, 42            ; uint32 big-endian = 42
n_boot db "BOOT"                 ; wymagany boot marker
```

> **Uwaga:** Każdy `db` tworzy dane w kodzie. Etykieta przed `db` daje adres tych danych.

## Konwencja wywoływania funkcji

Styl x86/cdecl:

```asm
; Wywołanie: push argumenty od prawej do lewej
PUSH arg2
PUSH arg1
CALL funkcja
ADD SP, 8        ; sprzątamy stos (2 × 4B)

; Prolog funkcji
funkcja:
    PUSH BP
    MOV BP, SP
    SUB SP, N    ; N = bajty dla zmiennych lokalnych (wielokrotność 4)

; Dostęp do parametrów z wnętrza funkcji
;   [BP + 8]  = arg1  (pierwszy)
;   [BP + 12] = arg2  (drugi)
; Zmienne lokalne:
;   [BP - 4]  = pierwsza zmienna lokalna

; Epilog
epilog_funkcja:
    MOV SP, BP
    POP BP
    RET
```

## Bootloader

Każdy program musi zaczynać się od sekcji `_global`, która:
1. Zapisuje wskaźnik stringa boot do `0xF000` w RAM
2. Wywołuje syscall 0 (drukuje ten string — "BOOT")
3. Skacze do `_start`

```asm
_global:
    MOV 0xF000, n_boot
    MOV AX, 0
    syscall
    jmp _start
```

## Kompilacja

```powershell
# Pojedynczy plik .s → .ds
py comp.py hello.s hello.ds
py vm.py hello.ds

# Tryb multi-sektor (interaktywny, main.s + inne pliki .s)
py comp.py

# Uruchomienie z argumentami CLI
py vm.py moj.ds arg1 arg2   # argc w AX, argv ptr w BX
```

Pełna lista narzędzi: [tools.md](tools.md)
