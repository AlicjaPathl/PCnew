/*
 * PC-VM for Arduino + LCD 16x2 (I2C)
 * Generated / maintained by ardc.py + write.py
 *
 * Flash: VM interpreter + disk.h (PROGMEM)
 * SRAM:  vm_ram[] = runtime stack + code copy (1024 B)
 *
 * ── Syscall Table ───────────────────────────────────────────────
 *  AX=0   print_boot         → Serial + LCD row 0
 *  AX=1   print_string(CX)   → Serial; BX=0→LCD0, BX=1→LCD1, BX=2→println
 *  AX=2   read_int(CX)       → Serial.parseInt → RAM[CX]
 *  AX=40  lcd_print(BX,CX)   → LCD row BX, string at CX
 *  AX=41  lcd_clear           → @CLR|
 *  AX=42  lcd_backlight(BX)   → @BLON| / @BLOFF|
 *  AX=43  lcd_cursor(BX,CX)   → @CURSOR|row,col
 *  AX=44  lcd_char(CX)        → @CHAR|c
 *  AX=45  lcd_scroll(BX)      → @SCRL|L or R
 *  AX=46  pin_mode(BX,CX)     → pinMode
 *  AX=47  pin_write(BX,CX)    → digitalWrite
 *  AX=48  pin_read(BX) → AX  → digitalRead
 *  AX=49  analog_read(BX)→AX → analogRead
 *  AX=50  analog_write(BX,CX) → analogWrite
 *  AX=51  delay_ms(BX)        → delay()
 *  AX=52  millis_now() → AX  → millis()
 *  AX=53  serial_avail()→AX  → Serial.available()
 *  AX=54  serial_readbyte()→AX → Serial.read()
 *  AX=55  eeprom_write(BX,CX) → EEPROM.write
 *  AX=56  eeprom_read(BX)→AX → EEPROM.read
 *  AX=60  exit(CX)            → halt VM
 * ────────────────────────────────────────────────────────────────
 *
 * Packets sent over Serial to Python host (ardpy.py):
 *   @LCD0|text      → row 0
 *   @LCD1|text      → row 1
 *   @CLR|           → clear LCD
 *   @BOOT|text      → boot message
 *   @BLON|          → backlight on
 *   @BLOFF|         → backlight off
 *   @PRINT|text     → plain print (no LCD)
 *   @HALT|code      → program ended
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <EEPROM.h>
#include <avr/pgmspace.h>
#include "disk.h"

// ─── CONFIG ──────────────────────────────────────────────────────────────────
#define VM_RAM_SIZE   1024    // Uno: 1024  |  Mega: 4096
#define DISK_BUF_SIZE   64
#define LCD_ADDR      0x27
#define LCD_COLS        16
#define LCD_ROWS         2
#define SERIAL_BAUD   9600
// ─────────────────────────────────────────────────────────────────────────────

LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);

// Register file
#define AX 0
#define BX 1
#define CX 2
#define DX 3
#define SP 4
#define BP 5

uint8_t  vm_ram[VM_RAM_SIZE];
int32_t  regs[6];
uint32_t vm_pc;
bool     vm_running;
bool     vm_zf;
bool     vm_lf;
uint8_t  disk_buf[DISK_BUF_SIZE];

// Current LCD lines (for flicker-free redraw)
char lcd_line[2][17];   // 16 chars + null

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

inline uint32_t rd32(const uint8_t *b) {
  return ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) |
         ((uint32_t)b[2] << 8)  |  (uint32_t)b[3];
}
inline uint16_t rd16(const uint8_t *b) {
  return ((uint16_t)b[0] << 8) | b[1];
}
// Jump/call addresses: 8-byte field, big-endian (lower 32 bits used)
inline uint32_t rd_addr(const uint8_t *b) {
  return ((uint32_t)b[4] << 24) | ((uint32_t)b[5] << 16) |
         ((uint32_t)b[6] << 8)  |  (uint32_t)b[7];
}

// ─────────────────────────────────────────────────────────────────────────────
// LCD
// ─────────────────────────────────────────────────────────────────────────────

void lcd_draw_row(uint8_t row) {
  // Pad to 16 chars
  char buf[17];
  strncpy(buf, lcd_line[row], 16);
  buf[16] = 0;
  uint8_t len = strlen(buf);
  while (len < 16) buf[len++] = ' ';
  buf[16] = 0;
  lcd.setCursor(0, row);
  lcd.print(buf);
}

// Read a null-terminated string from VM RAM into a char buffer (max 16 chars)
void vm_str_to_buf(uint32_t addr, char *buf, uint8_t maxlen) {
  uint8_t i = 0;
  while (addr < VM_RAM_SIZE && i < maxlen - 1) {
    char c = (char)vm_ram[addr++];
    if (c == 0 || c == '\n') break;
    buf[i++] = c;
  }
  buf[i] = 0;
}

// Print VM string to LCD row and Serial
void lcd_print_vm(uint8_t row, uint32_t addr) {
  if (row >= LCD_ROWS) row = LCD_ROWS - 1;
  vm_str_to_buf(addr, lcd_line[row], 17);
  lcd_draw_row(row);
  
  // Also send packet to Python host
  Serial.print(row == 0 ? F("@LCD0|") : F("@LCD1|"));
  Serial.println(lcd_line[row]);
}

// Print VM string to Serial only
void serial_print_vm(uint32_t addr, bool newline) {
  Serial.print(F("@PRINT|"));
  while (addr < VM_RAM_SIZE) {
    char c = (char)vm_ram[addr++];
    if (c == 0) break;
    Serial.print(c);
  }
  if (newline) Serial.println();
  else Serial.print('\n');
}

// ─────────────────────────────────────────────────────────────────────────────
// Syscall dispatcher
// ─────────────────────────────────────────────────────────────────────────────

void do_syscall() {
  int32_t  ax = regs[AX];
  int32_t  bx = regs[BX];
  uint32_t cx = (uint32_t)regs[CX];
  int32_t  dx = regs[DX];

  switch (ax) {

    // ── I/O ────────────────────────────────────────────────────────────
    case 0: {  // print_boot — string at RAM[boot_ptr]
      uint32_t addr = rd32(&vm_ram[0xF000 < VM_RAM_SIZE ? 0x0100 : 0x0100]);
      char buf[17];
      vm_str_to_buf(addr, buf, 17);
      strncpy(lcd_line[0], buf, 16);
      lcd_draw_row(0);
      strncpy(lcd_line[1], "               ", 16);
      lcd_draw_row(1);
      Serial.print(F("@BOOT|")); Serial.println(buf);
      break;
    }

    case 1: {  // print_string(CX); BX=0→LCD0, BX=1→LCD1, BX=2→Serial only
      if (bx == 2) {
        serial_print_vm(cx, true);
      } else if (bx == 0 || bx == 1) {
        lcd_print_vm((uint8_t)bx, cx);
        serial_print_vm(cx, true);
      } else {
        // default: Serial + LCD row 0
        lcd_print_vm(0, cx);
        serial_print_vm(cx, true);
      }
      break;
    }

    case 2: {  // read_int → RAM[CX]
      Serial.print(F("> "));
      while (!Serial.available()) { delay(10); }
      int32_t val = Serial.parseInt();
      if (cx + 4 <= VM_RAM_SIZE) {
        vm_ram[cx]   = (val >> 24) & 0xFF;
        vm_ram[cx+1] = (val >> 16) & 0xFF;
        vm_ram[cx+2] = (val >> 8)  & 0xFF;
        vm_ram[cx+3] =  val        & 0xFF;
      }
      break;
    }

    // ── LCD ─────────────────────────────────────────────────────────────
    case 40: {  // lcd_print(BX=row, CX=addr)
      lcd_print_vm((uint8_t)(bx & 1), cx);
      break;
    }

    case 41: {  // lcd_clear()
      memset(lcd_line[0], 0, 17);
      memset(lcd_line[1], 0, 17);
      lcd_draw_row(0);
      lcd_draw_row(1);
      Serial.println(F("@CLR|"));
      break;
    }

    case 42: {  // lcd_backlight(BX)
      if (bx) { lcd.backlight(); Serial.println(F("@BLON|")); }
      else     { lcd.noBacklight(); Serial.println(F("@BLOFF|")); }
      break;
    }

    case 43: {  // lcd_cursor(BX=row, CX=col)
      lcd.setCursor((uint8_t)(cx & 0xFF), (uint8_t)(bx & 1));
      Serial.print(F("@CURSOR|"));
      Serial.print(bx); Serial.print(','); Serial.println(cx);
      break;
    }

    case 44: {  // lcd_char(CX=char) [when BX=255]
      char c = (char)(cx & 0xFF);
      lcd.print(c);
      Serial.print(F("@CHAR|")); Serial.println(c);
      break;
    }

    case 45: {  // lcd_scroll(BX=0→left, 1→right)
      if (bx == 0) { lcd.scrollDisplayLeft(); Serial.println(F("@SCRL|L")); }
      else          { lcd.scrollDisplayRight(); Serial.println(F("@SCRL|R")); }
      break;
    }

    // ── GPIO ────────────────────────────────────────────────────────────
    case 46: {  // pin_mode(BX=pin, CX=mode)
      uint8_t mode_val = (cx == 2) ? INPUT_PULLUP : (cx ? OUTPUT : INPUT);
      pinMode((uint8_t)bx, mode_val);
      break;
    }

    case 47: {  // pin_write(BX=pin, CX=val)
      digitalWrite((uint8_t)bx, cx ? HIGH : LOW);
      break;
    }

    case 48: {  // pin_read(BX=pin) → AX
      regs[AX] = digitalRead((uint8_t)bx) ? 1 : 0;
      break;
    }

    case 49: {  // analog_read(BX=pin) → AX
      regs[AX] = analogRead((uint8_t)bx);
      break;
    }

    case 50: {  // analog_write(BX=pin, CX=val)
      analogWrite((uint8_t)bx, (uint8_t)(cx & 0xFF));
      break;
    }

    // ── Timing ─────────────────────────────────────────────────────────
    case 51: {  // delay_ms(BX)
      delay((uint32_t)bx);
      break;
    }

    case 52: {  // millis_now() → AX
      regs[AX] = (int32_t)(millis() & 0x7FFFFFFFUL);
      break;
    }

    // ── Serial ─────────────────────────────────────────────────────────
    case 53: {  // serial_avail() → AX
      regs[AX] = Serial.available();
      break;
    }

    case 54: {  // serial_readbyte() → AX
      regs[AX] = Serial.read();  // -1 if no data
      break;
    }

    // ── EEPROM ─────────────────────────────────────────────────────────
    case 55: {  // eeprom_write(BX=addr, CX=val)
      if ((uint16_t)bx < EEPROM.length())
        EEPROM.write((uint16_t)bx, (uint8_t)(cx & 0xFF));
      break;
    }

    case 56: {  // eeprom_read(BX=addr) → AX
      regs[AX] = ((uint16_t)bx < EEPROM.length())
                   ? EEPROM.read((uint16_t)bx)
                   : 0;
      break;
    }

    // ── Disk ────────────────────────────────────────────────────────────
    case 25: {  // disk_read: sector BX → disk_buf
      uint32_t sector = (uint32_t)bx;
      uint32_t offset = 4 + sector * 512UL;
      for (uint16_t i = 0; i < DISK_BUF_SIZE; i++) {
        uint32_t idx = offset + i;
        disk_buf[i] = (idx < sizeof(disk_image))
                      ? pgm_read_byte(&disk_image[idx])
                      : 0;
      }
      regs[AX] = 0;
      break;
    }

    // ── Halt ────────────────────────────────────────────────────────────
    case 60: {
      vm_running = false;
      Serial.print(F("@HALT|")); Serial.println(regs[CX]);
      if (regs[CX] != 0) {
        strncpy(lcd_line[0], "*** HALTED ***  ", 16);
        strncpy(lcd_line[1], "                ", 16);
        lcd_draw_row(0); lcd_draw_row(1);
      }
      break;
    }

    default:
      Serial.print(F("[VM] Unknown syscall AX="));
      Serial.println(ax);
      break;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory operations
// ─────────────────────────────────────────────────────────────────────────────

uint32_t resolve_addr(uint32_t addr, uint8_t mode) {
  if (mode == 0) {
    return addr;
  } else if (mode == 1) {
    if (addr < 6) return regs[addr];
    return 0;
  } else if (mode == 2) {
    uint8_t reg_idx = (addr >> 24) & 0xFF;
    int32_t offset = addr & 0xFFFFFF;
    if (offset >= 0x800000) {
      offset -= 0x1000000;
    }
    if (reg_idx < 6) return regs[reg_idx] + offset;
    return offset;
  }
  return 0;
}

void do_store(uint8_t reg, uint32_t addr, uint8_t mode) {
  uint32_t target_addr = resolve_addr(addr, mode);
  if (mode == 0 && target_addr % 512 == 0 && target_addr == 0) {
    for (uint16_t i = 0; i < DISK_BUF_SIZE && target_addr+i < VM_RAM_SIZE; i++)
      vm_ram[target_addr + i] = disk_buf[i];
  } else if (target_addr + 4 <= VM_RAM_SIZE) {
    if (reg < 6) {
      int32_t val = regs[reg];
      vm_ram[target_addr]   = (val >> 24) & 0xFF;
      vm_ram[target_addr+1] = (val >> 16) & 0xFF;
      vm_ram[target_addr+2] = (val >> 8)  & 0xFF;
      vm_ram[target_addr+3] =  val        & 0xFF;
    }
  }
}

void do_store_byte(uint8_t reg, uint32_t addr, uint8_t mode) {
  uint32_t target_addr = resolve_addr(addr, mode);
  if (reg < 6 && target_addr < VM_RAM_SIZE) {
    vm_ram[target_addr] = (uint8_t)(regs[reg] & 0xFF);
  }
}

void do_load(uint8_t reg, uint32_t addr, uint8_t mode) {
  uint32_t target_addr = resolve_addr(addr, mode);
  if (reg < 6 && target_addr + 4 <= VM_RAM_SIZE) {
    regs[reg] = ((int32_t)vm_ram[target_addr]   << 24) |
                ((int32_t)vm_ram[target_addr+1] << 16) |
                ((int32_t)vm_ram[target_addr+2] << 8)  |
                 (int32_t)vm_ram[target_addr+3];
  }
}

void do_load_byte(uint8_t reg, uint32_t addr, uint8_t mode) {
  uint32_t target_addr = resolve_addr(addr, mode);
  if (reg < 6 && target_addr < VM_RAM_SIZE) {
    regs[reg] = vm_ram[target_addr];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instruction execution
// ─────────────────────────────────────────────────────────────────────────────

bool execute_instruction() {
  if (!vm_running) return false;
  if (vm_pc + 9 > VM_RAM_SIZE) {
    Serial.println(F("[VM] PC out of range")); return false;
  }

  uint8_t  opcode = vm_ram[vm_pc];
  uint8_t *args   = &vm_ram[vm_pc + 1];

  if (opcode == 0) return false;

  switch (opcode) {

    case 1: {   // MOV
      uint8_t  mode = args[0];
      uint16_t dest = rd16(&args[1]);
      uint32_t src  = rd32(&args[3]);
      if      (mode == 0 && dest < 6) {
        if (dest == SP && src > VM_RAM_SIZE) {
          regs[dest] = VM_RAM_SIZE;
        } else {
          regs[dest] = (int32_t)src;
        }
      }
      else if (mode == 1 && dest + 4 <= VM_RAM_SIZE) {
        vm_ram[dest]   = (src>>24)&0xFF; vm_ram[dest+1] = (src>>16)&0xFF;
        vm_ram[dest+2] = (src>>8)&0xFF;  vm_ram[dest+3] =  src&0xFF;
      }
      else if (mode == 2 && dest < 6 && src < 6) regs[dest] = regs[src];
      vm_pc += 9; break;
    }

    case 2: {   // CMP
      uint8_t  mode = args[0];
      uint16_t dest = rd16(&args[1]);
      uint32_t src  = rd32(&args[3]);
      int32_t  v1 = (dest < 6) ? regs[dest] : 0;
      int32_t  v2 = (mode==1 && src<6) ? regs[src] : (int32_t)src;
      vm_zf = (v1 == v2); vm_lf = (v1 < v2);
      vm_pc += 9; break;
    }

    case 3: { uint32_t t=rd_addr(args); vm_pc=t; break; }          // JMP
    case 4: { uint32_t t=rd_addr(args); vm_pc=vm_zf?t:vm_pc+9; break; }  // JZ
    case 5: { uint32_t t=rd_addr(args); vm_pc=!vm_zf?t:vm_pc+9; break; } // JNZ
    case 6: { do_syscall(); vm_pc+=9; break; }                      // SYSCALL

    case 7: {   // STORE
      uint8_t reg = args[0]; uint32_t addr = rd32(&args[1]); uint8_t mode = args[5];
      do_store(reg, addr, mode);
      vm_pc += 9; break;
    }

    case 8: {   // LOAD
      uint8_t reg = args[0]; uint32_t addr = rd32(&args[1]); uint8_t mode = args[5];
      do_load(reg, addr, mode);
      vm_pc += 9; break;
    }

    case 9: {   // ADD
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] += (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 10: { uint32_t t=rd_addr(args); vm_pc=vm_lf?t:vm_pc+9; break; }  // JL
    case 11: { // SUB
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] -= (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 12: { // MUL
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] *= (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 13: { // DIV
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) { int32_t div=(m==0)?(int32_t)s:regs[s]; if(div) regs[d]/=div; }
      vm_pc+=9; break;
    }
    case 14: { // AND
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] &= (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 15: { // OR
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] |= (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 16: { // XOR
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d] ^= (m==1&&s<6)?regs[s]:(int32_t)s;
      vm_pc+=9; break;
    }
    case 17: { uint8_t r=args[0]; if(r<6) regs[r]=~regs[r]; vm_pc+=9; break; } // NOT
    case 18: { // SHL
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d]<<=(m==0?s:regs[s])&31; vm_pc+=9; break;
    }
    case 19: { // SHR
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6) regs[d]>>=(m==0?s:regs[s])&31; vm_pc+=9; break;
    }
    case 20: { delay(rd32(&args[0])); vm_pc+=9; break; } // DELAY
    case 21: { // PUSH
      uint8_t m=args[0]; uint32_t v=rd32(&args[1]);
      int32_t pv = (m==1&&v<6)?regs[v]:(int32_t)v;
      regs[SP]-=4;
      if (regs[SP]+4<=VM_RAM_SIZE) {
        vm_ram[regs[SP]]=(pv>>24)&0xFF; vm_ram[regs[SP]+1]=(pv>>16)&0xFF;
        vm_ram[regs[SP]+2]=(pv>>8)&0xFF; vm_ram[regs[SP]+3]=pv&0xFF;
      }
      vm_pc+=9; break;
    }
    case 22: { // POP
      uint8_t r=args[0];
      if (r<6&&regs[SP]+4<=VM_RAM_SIZE) {
        regs[r]=((int32_t)vm_ram[regs[SP]]<<24)|((int32_t)vm_ram[regs[SP]+1]<<16)|
                ((int32_t)vm_ram[regs[SP]+2]<<8)|(int32_t)vm_ram[regs[SP]+3];
        regs[SP]+=4;
      }
      vm_pc+=9; break;
    }
    case 23: { // CALL
      uint32_t target=rd_addr(args); uint32_t ret=vm_pc+9;
      regs[SP]-=4;
      if (regs[SP]+4<=VM_RAM_SIZE) {
        vm_ram[regs[SP]]=(ret>>24)&0xFF; vm_ram[regs[SP]+1]=(ret>>16)&0xFF;
        vm_ram[regs[SP]+2]=(ret>>8)&0xFF; vm_ram[regs[SP]+3]=ret&0xFF;
        vm_pc=target;
      } else vm_pc+=9;
      break;
    }
    case 24: { // RET
      if (regs[SP]+4<=VM_RAM_SIZE) {
        uint32_t r=((uint32_t)vm_ram[regs[SP]]<<24)|((uint32_t)vm_ram[regs[SP]+1]<<16)|
                   ((uint32_t)vm_ram[regs[SP]+2]<<8)|(uint32_t)vm_ram[regs[SP]+3];
        regs[SP]+=4; vm_pc=r;
      } else vm_pc+=9;
      break;
    }
    case 25: { uint32_t t=rd_addr(args); vm_pc=(!vm_zf&&!vm_lf)?t:vm_pc+9; break; } // JG
    case 26: { uint32_t t=rd_addr(args); vm_pc=(!vm_lf)?t:vm_pc+9; break; }         // JGE
    case 27: { uint32_t t=rd_addr(args); vm_pc=(vm_lf||vm_zf)?t:vm_pc+9; break; }   // JLE
    case 28: { uint8_t r=args[0]; if(r<6) regs[r]=-regs[r]; vm_pc+=9; break; } // NEG
    case 29: { uint8_t r=args[0]; if(r<6) regs[r]++; vm_pc+=9; break; } // INC
    case 30: { uint8_t r=args[0]; if(r<6) regs[r]--; vm_pc+=9; break; } // DEC
    case 31: { // MOD
      uint8_t m=args[0]; uint16_t d=rd16(&args[1]); uint32_t s=rd32(&args[3]);
      if (d<6){int32_t div=(m==0)?(int32_t)s:regs[s]; if(div) regs[d]%=div;}
      vm_pc+=9; break;
    }
    case 32: {  // LOAD_B
      uint8_t reg = args[0]; uint32_t addr = rd32(&args[1]); uint8_t mode = args[5];
      do_load_byte(reg, addr, mode);
      vm_pc += 9; break;
    }
    case 33: {  // STORE_B
      uint8_t reg = args[0]; uint32_t addr = rd32(&args[1]); uint8_t mode = args[5];
      do_store_byte(reg, addr, mode);
      vm_pc += 9; break;
    }

    default:
      Serial.print(F("[VM] Unknown opcode="));
      Serial.println(opcode);
      return false;
  }
  return vm_running;
}

// ─────────────────────────────────────────────────────────────────────────────
// Arduino setup / loop
// ─────────────────────────────────────────────────────────────────────────────

void setup() {
  Serial.begin(SERIAL_BAUD);

  // I2C init (platform-specific)
#if defined(ESP8266)
  Wire.begin(4, 5);
#elif defined(ESP32)
  Wire.begin(21, 22);
#else
  Wire.begin();
#endif

  lcd.init();
  lcd.backlight();
  memset(lcd_line[0], 0, 17);
  memset(lcd_line[1], 0, 17);
  strncpy(lcd_line[0], "Python VM", 16);
  strncpy(lcd_line[1], "Booting...", 16);
  lcd_draw_row(0); lcd_draw_row(1);

  Serial.println(F("=== PC-VM Arduino ==="));
  Serial.println(F("READY"));

  uint32_t img_size = sizeof(disk_image);
  if (img_size < 4) {
    Serial.println(F("[ERROR] disk.h empty"));
    strncpy(lcd_line[0], "ERROR: no disk", 16);
    lcd_draw_row(0);
    return;
  }

  // Read entry point from 4-byte header
  uint32_t entry = ((uint32_t)pgm_read_byte(&disk_image[0]) << 24) |
                   ((uint32_t)pgm_read_byte(&disk_image[1]) << 16) |
                   ((uint32_t)pgm_read_byte(&disk_image[2]) << 8)  |
                    (uint32_t)pgm_read_byte(&disk_image[3]);

  Serial.print(F("[VM] entry=0x")); Serial.println(entry, HEX);

  // Copy program into VM RAM
  uint32_t copy_len = img_size - 4;
  if (copy_len > VM_RAM_SIZE) copy_len = VM_RAM_SIZE;
  for (uint32_t i = 0; i < copy_len; i++)
    vm_ram[i] = pgm_read_byte(&disk_image[4 + i]);

  // Init VM
  regs[AX]=regs[BX]=regs[CX]=regs[DX]=regs[BP]=0;
  regs[SP]   = VM_RAM_SIZE;
  vm_pc      = entry;
  vm_running = true;
  vm_zf = vm_lf = false;
  memset(disk_buf, 0, DISK_BUF_SIZE);

  strncpy(lcd_line[0], "VM Running", 16);
  strncpy(lcd_line[1], "               ", 16);
  lcd_draw_row(0); lcd_draw_row(1);
  Serial.println(F("[VM] Running..."));

  // Execute program
  while (execute_instruction()) {}

  Serial.println(F("[VM] Halted."));
}

void loop() {
  // Check for Serial commands from Python host
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    // @RESET → restart VM (soft reset via watchdog would need avr/wdt.h)
    if (cmd == F("@RESET")) {
      setup();
    }
    // @PING → acknowledge
    else if (cmd == F("@PING")) {
      Serial.println(F("@PONG|"));
    }
  }
  delay(100);
}