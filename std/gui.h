#ifndef GUI_H
#define GUI_H

// Event types
#define EVT_NONE         0
#define EVT_MOUSE_LEFT   1
#define EVT_MOUSE_RIGHT  2
#define EVT_KEY_DOWN     3
#define EVT_KEY_UP       4
#define EVT_MOUSE_MOVE   5

// Common colors (0xRRGGBB)
#define COLOR_BLACK   0x000000
#define COLOR_WHITE   0xFFFFFF
#define COLOR_RED     0xFF0000
#define COLOR_GREEN   0x00FF00
#define COLOR_BLUE    0x0000FF
#define COLOR_YELLOW  0xFFFF00
#define COLOR_CYAN    0x00FFFF
#define COLOR_MAGENTA 0xFF00FF
#define COLOR_ORANGE  0xFF8800
#define COLOR_GRAY    0x888888
#define COLOR_DARK    0x1A1A2E
#define COLOR_ACCENT  0x16213E
#define COLOR_PURPLE  0x533483
#define COLOR_TEAL    0x0F3460

// Initialize a GUI window with given width, height, and title.
// Syscall AX=30, BX=w, CX=h, DX=title_addr
void gui_init(int w, int h, char *title);

// Clear the canvas with a background color.
// Syscall AX=31, BX=color
void gui_clear(int color);

// Draw a filled or outlined rectangle.
// Params stored in RAM buffer: x, y, w, h, color, fill (each 4B)
// Syscall AX=32, BX=params_addr
void gui_draw_rect(int x, int y, int w, int h, int color, int fill);

// Draw a line between two points.
// Params: x1, y1, x2, y2, color (each 4B)
// Syscall AX=33, BX=params_addr
void gui_draw_line(int x1, int y1, int x2, int y2, int color);

// Draw text at position (x, y) with a color and font size.
// Params: x, y, color, str_addr, font_size (each 4B)
// Syscall AX=34, BX=params_addr
void gui_draw_text(int x, int y, int color, char *text, int font_size);

// Poll for the next GUI event.
// Writes event data to a 16-byte buffer: type(4B), x(4B), y(4B), key(4B)
// Returns 1 if an event was retrieved, 0 if queue is empty.
// Syscall AX=35, BX=event_buf_addr
int gui_poll_event(int *event_buf);

// Present/refresh the window (flush draw calls).
// Syscall AX=36
void gui_present();

// === ImGui Widget Helpers ===

// Draws a panel (background window area)
void gui_panel(int x, int y, int w, int h, int bg_color, int border_color);

// Draws a header title bar
void gui_header(int x, int y, int w, int h, char *title, int bg_color, int text_color);

// Draws a label/text
void gui_label(int x, int y, char *text, int color, int font_size);

// Draws a button and returns 1 if it was clicked, 0 otherwise.
// It changes colors depending on hover state (requires mx, my).
int gui_button(int x, int y, int w, int h, char *text, int mx, int my, int evt_type);

#endif
