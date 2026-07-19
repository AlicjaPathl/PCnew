#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gui.h>

int main() {
    print_string("GUI Test starting...\n");

    // Init GUI window: 400x300 pixels
    gui_init(400, 300, "PC VM Mini-Qt Demo");

    // Mouse coordinates and event type
    int mx = 0;
    int my = 0;
    int evt_type = 0;
    int key = 0;

    int counter = 0;
    int running = 1;

    // Buffer to receive events: type(4B), x(4B), y(4B), key(4B)
    int ev_buf[4];

    // Main GUI Loop
    while (running) {
        // Poll event
        evt_type = EVT_NONE;
        if (gui_poll_event(ev_buf)) {
            evt_type = *(ev_buf);      // type
            mx = *(ev_buf + 1);        // x
            my = *(ev_buf + 2);        // y
            key = *(ev_buf + 3);       // key

            if (evt_type == EVT_KEY_DOWN && key == 27) { // ESC key
                running = 0;
            }
        }

        // Draw Frame
        gui_clear(COLOR_DARK);

        // Panel background
        gui_panel(20, 20, 360, 260, COLOR_ACCENT, COLOR_WHITE);

        // Window header
        gui_header(20, 20, 360, 30, "Widget Dashboard", COLOR_PURPLE, COLOR_WHITE);

        // Counter label
        gui_label(40, 70, "Clicks Counter:", COLOR_CYAN, 14);

        // Standard integer conversion & printing in GUI
        // Let's print the counter value
        char *lbl = "Clicks: ";
        gui_label(40, 100, lbl, COLOR_YELLOW, 20);

        char num_str[16];
        int temp = counter;
        int idx = 0;
        if (temp == 0) {
            *(num_str + idx) = '0';
            idx = idx + 1;
        } else {
            char rev[16];
            int ridx = 0;
            while (temp > 0) {
                *(rev + ridx) = '0' + (temp % 10);
                temp = temp / 10;
                ridx = ridx + 1;
            }
            while (ridx > 0) {
                ridx = ridx - 1;
                *(num_str + idx) = *(rev + ridx);
                idx = idx + 1;
            }
        }
        *(num_str + idx) = 0;
        gui_label(150, 100, num_str, COLOR_YELLOW, 20);

        // Button Click Me
        if (gui_button(40, 150, 120, 40, "Click Me!", mx, my, evt_type)) {
            counter = counter + 1;
            print_string("Button 'Click Me!' clicked! Counter: ");
            print_int(counter);
            print_string("\n");
        }

        // Button Reset
        if (gui_button(180, 150, 120, 40, "Reset", mx, my, evt_type)) {
            counter = 0;
            print_string("Button 'Reset' clicked!\n");
        }

        // Button Exit
        if (gui_button(40, 210, 260, 40, "Exit Application", mx, my, evt_type)) {
            running = 0;
        }

        // Present Frame to display on screen and yield control to Tkinter
        gui_present();

        // Small delay to prevent 100% CPU usage
        delay(16); // ~60 FPS
    }

    print_string("GUI program finished successfully.\n");
    exit(0);
    return 0;
}
