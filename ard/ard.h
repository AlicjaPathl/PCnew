// ard.h — Arduino-specific header dla ardc.py
// Syscalle mapowane na Arduino hardware

#ifndef ARD_H
#define ARD_H

// ─── GPIO ───────────────────────────────────────────────────────────────────
// pin_mode(pin, mode)  mode: 0=INPUT, 1=OUTPUT, 2=INPUT_PULLUP
void pin_mode(int pin, int mode);

// pin_write(pin, val)  val: 0=LOW, 1=HIGH
void pin_write(int pin, int val);

// int pin_read(pin) → 0 or 1
int pin_read(int pin);

// int analog_read(pin) → 0..1023
int analog_read(int pin);

// analog_write(pin, val)  val: 0..255 (PWM)
void analog_write(int pin, int val);

// ─── Timing ─────────────────────────────────────────────────────────────────
// delay_ms(ms)
void delay_ms(int ms);

// int millis_now() → ms since boot (lower 32 bits)
int millis_now();

// ─── Serial ─────────────────────────────────────────────────────────────────
// Already provided by stdio.h: print_string(), print_int()
// serial_println(str)  — same as print_string but adds newline
void serial_println(char *s);

// serial_avail() → bytes available in Serial buffer
int serial_avail();

// serial_readbyte() → char or -1
int serial_readbyte();

// ─── EEPROM ─────────────────────────────────────────────────────────────────
// eeprom_write(addr, val)  addr: 0..1023, val: 0..255
void eeprom_write(int addr, int val);

// int eeprom_read(addr) → 0..255
int eeprom_read(int addr);

// ─── Constants ──────────────────────────────────────────────────────────────
#define INPUT         0
#define OUTPUT        1
#define INPUT_PULLUP  2
#define LOW           0
#define HIGH          1
#define A0            14
#define A1            15
#define A2            16
#define A3            17
#define A4            18
#define A5            19
#define LED_BUILTIN   13

#endif // ARD_H
