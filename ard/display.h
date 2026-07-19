// display.h — LCD 16x2 I2C display header dla ardc.py
// Obsługuje wyświetlacz przez pakiety @CMD|data przez Serial

#ifndef DISPLAY_H
#define DISPLAY_H

// ─── LCD 16x2 I2C ────────────────────────────────────────────────────────────

// lcd_init()  — inicjalizuje wyświetlacz (wywoływana automatycznie przy boot)
void lcd_init();

// lcd_clear()  — czyści oba wiersze
void lcd_clear();

// lcd_print(row, text)  — wyświetla tekst na wierszu 0 lub 1 (max 16 znaków)
void lcd_print(int row, char *text);

// lcd_print0(text)  — skrót: wiersz 0
void lcd_print0(char *text);

// lcd_print1(text)  — skrót: wiersz 1
void lcd_print1(char *text);

// lcd_cursor(row, col)  — ustawia pozycję kursora (nie rysuje nic)
void lcd_cursor(int row, int col);

// lcd_char(c)  — wyświetla jeden znak na bieżącej pozycji kursora
void lcd_char(int c);

// lcd_backlight(on)  — 1=włącz podświetlenie, 0=wyłącz
void lcd_backlight(int on);

// lcd_scroll_left()  — przesuń zawartość w lewo (hardware scroll)
void lcd_scroll_left();

// lcd_scroll_right()  — przesuń zawartość w prawo
void lcd_scroll_right();

#endif // DISPLAY_H
