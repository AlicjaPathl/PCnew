// ard_hello.c — Hello World for Arduino VM (Optimized for small size)
// Kompiluj: python ardc.py ard_hello.c --upload
// Monitor:  python ardpy.py --port COM3

#include <display.h>
#include <ard.h>

int main() {
    // Wyswietl na LCD
    lcd_print(0, "Hello World!");
    lcd_print(1, "from VM :)");
    
    // Wyslij na Serial
    serial_println("VM started!");

    // Blink LED i licznik
    int i = 0;
    pin_mode(13, 1);   // LED_BUILTIN = OUTPUT

    while (i < 5) {
        pin_write(13, 1);
        delay_ms(500);
        pin_write(13, 0);
        delay_ms(500);
        i = i + 1;
    }

    // Wyzwól koniec
    lcd_clear();
    lcd_print(0, "Done! Blinks: 5");
    serial_println("Finished!");
    
    return 0;
}
