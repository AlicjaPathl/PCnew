# Dokumentacja Arduino VM & Edytora Live

Ten dokument opisuje rozszerzenia wirtualnej maszyny (PC VM) oraz narzędzia dedykowane dla platformy **Arduino (Uno/Mega/ESP)**.

---

## 1. Wyświetlacz LCD 16x2 (I2C)

Wyświetlacz I2C (standardowo pod adresem `0x27`) jest obsługiwany bezpośrednio przez syscalle maszyny wirtualnej. Linia 0 i linia 1 są kontrolowane niezależnie.

### Pakietowy Protokół Szeregowy
Arduino wysyła do hosta (Python) status wyświetlacza za pomocą specjalnych pakietów:
- `@LCD0|tekst` — zaktualizowano górną linię.
- `@LCD1|tekst` — zaktualizowano dolną linię.
- `@CLR|` — wyczyszczono ekran.
- `@BOOT|tekst` — status rozruchu VM.
- `@BLON|` / `@BLOFF|` — zmiana stanu podświetlenia.
- `@HALT|kod` — zatrzymanie programu VM.

---

## 2. API C dla Arduino (`display.h` oraz `ard.h`)

Biblioteki w `std/` oraz specjalne nagłówki w `ard/` udostępniają pełną obsługę sprzętową mikrokontrolera.

### `display.h` — Kontrola LCD
- `void lcd_init()` — Inicjalizuje ekran.
- `void lcd_clear()` — Czyści ekran (górną i dolną linię).
- `void lcd_print(int row, char *text)` — Drukuje tekst na wybranym wierszu (0 lub 1).
- `void lcd_print0(char *text)` — Skrót do wiersza 0.
- `void lcd_print1(char *text)` — Skrót do wiersza 1.
- `void lcd_cursor(int row, int col)` — Ustawia pozycję kursora LCD.
- `void lcd_char(int c)` — Drukuje pojedynczy znak na pozycji kursora.
- `void lcd_backlight(int on)` — Włącza (1) lub wyłącza (0) podświetlenie ekranu.
- `void lcd_scroll_left()` / `lcd_scroll_right()` — Przewijanie ekranu.

### `ard.h` — GPIO i Timing
- `void pin_mode(int pin, int mode)` — Ustawia tryb pinu (0 = INPUT, 1 = OUTPUT, 2 = INPUT_PULLUP).
- `void pin_write(int pin, int val)` — Stan pinu (0 = LOW, 1 = HIGH).
- `int pin_read(int pin)` — Odczyt stanu cyfrowego (0 lub 1).
- `int analog_read(int pin)` — Odczyt ADC (0..1023).
- `void analog_write(int pin, int val)` — PWM (0..255).
- `void delay_ms(int ms)` — Pauza w milisekundach.
- `int millis_now()` — Czas od uruchomienia w ms.
- `void serial_println(char *s)` — Wysyła tekst przez Serial z nową linią.
- `int serial_avail()` — Zwraca liczbę bajtów w buforze odbiorczym Serial.
- `int serial_readbyte()` — Odczytuje 1 bajt (lub -1).
- `void eeprom_write(int addr, int val)` — Zapisuje bajt do EEPROM.
- `int eeprom_read(int addr)` — Odczytuje bajt z EEPROM.

---

## 3. Kompilacja i Monitorowanie

### Kompilacja i Wgrywanie Programów C (`ardc.py`)
```bash
py ardc.py nazwa_programu.c --upload
```
Kompilator wygeneruje pliki `nazwa_programu.s` oraz `nazwa_programu.ds`, a następnie automatycznie zaktualizuje obraz `disk.h` w szkicu Arduino i wgra go na urządzenie.

### Kompilacja i Wgrywanie Asemblera (`ards.py`)
```bash
python ards.py nazwa_programu.s --upload
```

### Uruchomienie Monitora Serial (`ardpy.py`)
```bash
python ardpy.py --port COM3
```
Pozwala monitorować stan urządzenia oraz emulować ekran LCD w oknie terminala.

### Interaktywny Terminal na Żywo (`livemonitor.py`)
```bash
python livemonitor.py
```
Kompiluje i wgrywa edytor na żywo, a następnie umożliwia bezpośrednie pisanie na ekranie LCD za pomocą klawiatury komputera w czasie rzeczywistym. Strzałki nawigują kursor, a backspace kasuje znaki.
