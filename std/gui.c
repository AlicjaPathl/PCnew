#include "gui.h"

// Shared parameter buffer at a fixed RAM address (0xE000 = 57344)
// This region is above user code but below boot_string_addr (0xF000)
#define GUI_PARAM_BUF 0xE000

// Helper: write uint32 big-endian to RAM address
void _gui_write_param(int addr, int val) {
    asm("LOAD AX, [BP + 8]");
    asm("LOAD BX, [BP + 12]");
    asm("STORE BX, [AX]");
}

void gui_init(int w, int h, char *title) {
    // AX=30, BX=w, CX=h, DX=title_addr
    asm("LOAD BX, [BP + 8]");
    asm("LOAD CX, [BP + 12]");
    asm("LOAD DX, [BP + 16]");
    asm("MOV AX, 30");
    asm("syscall");
}

void gui_clear(int color) {
    asm("LOAD BX, [BP + 8]");
    asm("MOV AX, 31");
    asm("syscall");
}

void gui_draw_rect(int x, int y, int w, int h, int color, int fill) {
    // Write 6 params to GUI_PARAM_BUF
    _gui_write_param(0xE000, x);
    _gui_write_param(0xE004, y);
    _gui_write_param(0xE008, w);
    _gui_write_param(0xE00C, h);
    _gui_write_param(0xE010, color);
    _gui_write_param(0xE014, fill);
    asm("MOV BX, 0xE000");
    asm("MOV AX, 32");
    asm("syscall");
}

void gui_draw_line(int x1, int y1, int x2, int y2, int color) {
    _gui_write_param(0xE000, x1);
    _gui_write_param(0xE004, y1);
    _gui_write_param(0xE008, x2);
    _gui_write_param(0xE00C, y2);
    _gui_write_param(0xE010, color);
    asm("MOV BX, 0xE000");
    asm("MOV AX, 33");
    asm("syscall");
}

void gui_draw_text(int x, int y, int color, char *text, int font_size) {
    _gui_write_param(0xE000, x);
    _gui_write_param(0xE004, y);
    _gui_write_param(0xE008, color);
    _gui_write_param(0xE00C, text);
    _gui_write_param(0xE010, font_size);
    asm("MOV BX, 0xE000");
    asm("MOV AX, 34");
    asm("syscall");
}

int gui_poll_event(int *event_buf) {
    // Write event_buf address to BX
    asm("LOAD BX, [BP + 8]");
    asm("MOV AX, 35");
    asm("syscall");
    // AX now has 1 or 0
}

void gui_present() {
    asm("MOV AX, 36");
    asm("syscall");
}

void gui_panel(int x, int y, int w, int h, int bg_color, int border_color) {
    gui_draw_rect(x, y, w, h, bg_color, 1);
    gui_draw_rect(x, y, w, h, border_color, 0);
}

void gui_header(int x, int y, int w, int h, char *title, int bg_color, int text_color) {
    gui_draw_rect(x, y, w, h, bg_color, 1);
    // Draw text inside header (offset a bit for margins)
    gui_draw_text(x + 10, y + (h - 16) / 2, text_color, title, 12);
}

void gui_label(int x, int y, char *text, int color, int font_size) {
    gui_draw_text(x, y, color, text, font_size);
}

int gui_button(int x, int y, int w, int h, char *text, int mx, int my, int evt_type) {
    int hovered = 0;
    if (mx >= x && mx <= (x + w) && my >= y && my <= (y + h)) {
        hovered = 1;
    }

    int btn_color = 0x3F3F4E; // default color
    if (hovered) {
        btn_color = 0x5F5F7E; // highlighted when hovered
    }

    gui_draw_rect(x, y, w, h, btn_color, 1);
    gui_draw_rect(x, y, w, h, 0xFFFFFF, 0); // white border

    // Draw text centered inside button
    gui_draw_text(x + 10, y + (h - 16) / 2, 0xFFFFFF, text, 12);

    if (hovered && evt_type == 1) { // EVT_MOUSE_LEFT click
        return 1;
    }
    return 0;
}
