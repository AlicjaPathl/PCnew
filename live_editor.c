// live_editor.c — Interactive LCD Text Editor running on Arduino VM
#include <display.h>
#include <ard.h>

char line0[17];
char line1[17];
int cur_row;
int cur_col;

// Clear line buffer with spaces
void clear_buffers() {
    int i;
    i = 0;
    while (i < 16) {
        *(line0 + i) = ' ';
        *(line1 + i) = ' ';
        i = i + 1;
    }
    *(line0 + 16) = 0;
    *(line1 + 16) = 0;
}

// Redraw LCD including the solid block cursor at (cur_row, cur_col)
void draw_editor() {
    char temp0[17];
    char temp1[17];
    int i;

    // Copy lines to temporary draw buffers
    i = 0;
    while (i < 16) {
        *(temp0 + i) = *(line0 + i);
        *(temp1 + i) = *(line1 + i);
        i = i + 1;
    }
    *(temp0 + 16) = 0;
    *(temp1 + 16) = 0;

    // Place solid block cursor (0xFF is the solid block on LCD)
    if (cur_row == 0) {
        *(temp0 + cur_col) = 255; 
    } else {
        *(temp1 + cur_col) = 255;
    }

    lcd_print(0, temp0);
    lcd_print(1, temp1);
}

int main() {
    cur_row = 0;
    cur_col = 0;
    clear_buffers();
    
    // Inicjalizacja LCD
    lcd_clear();
    draw_editor();

    while (1) {
        // Czekaj na Serial input
        if (serial_avail() > 0) {
            int key;
            key = serial_readbyte();

            if (key == 128) { // UP arrow
                cur_row = 0;
            }
            else if (key == 129) { // DOWN arrow
                cur_row = 1;
            }
            else if (key == 130) { // LEFT arrow
                if (cur_col > 0) {
                    cur_col = cur_col - 1;
                }
            }
            else if (key == 131) { // RIGHT arrow
                if (cur_col < 15) {
                    cur_col = cur_col + 1;
                }
            }
            else if (key == 8) { // BACKSPACE
                if (cur_col > 0) {
                    cur_col = cur_col - 1;
                    if (cur_row == 0) {
                        *(line0 + cur_col) = ' ';
                    } else {
                        *(line1 + cur_col) = ' ';
                    }
                }
            }
            else if (key >= 32) { // Printy ASCII
                if (key < 127) {
                    if (cur_row == 0) {
                        *(line0 + cur_col) = key;
                    } else {
                        *(line1 + cur_col) = key;
                    }
                    if (cur_col < 15) {
                        cur_col = cur_col + 1;
                    }
                }
            }
            draw_editor();
        }
        delay_ms(20);
    }
    return 0;
}
