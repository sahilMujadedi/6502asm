UPPERMASK=$F0
LOWERMASK=$0F

PORTA=$6001
DDRA=$6003
; first 4 bits represent data
RS=%00000010
RW=%00000100
E= %00001000

  .org $8000

reset:  
  LDA #%11111111 ; set all pins on port B to output
  STA DDRA
  
  LDA #%00100000 ; set 4 bit mode
  JSR lcd_instruction
  JSR lcd_instruction
  
  LDA #%10000000 ; set 2 line mode, 5x8 font
  JSR lcd_instruction
  
  LDA #%00000000 ; display on/off control
  JSR lcd_instruction
  LDA #%11110000
  JSR lcd_instruction
  
  LDA #%00000000 ; entry mode set
  JSR lcd_instruction
  LDA #%01100000
  JSR lcd_instruction
  
  LDA #%00000000 ; clear display
  JSR lcd_instruction
  LDA #%00010000
  JSR lcd_instruction
  
  LDX #0
print:
  LDA message,x   ; use x as index to continually print out chars in "message"
  BEQ loop
  JSR print_char
  INX
  JMP print
  
loop:
  JMP loop
  
message: .asciiz "Sahil is cool" ; creates a null-terminated string in memory
print_char:
  PHA                  ; push a onto stack to preserve the char
  AND #UPPERMASK       ; manipulate it for the high nibble
  ORA #RS
  JSR lcd_instruction
  PLA                  ; pull a back to use the lower nibble
  ROL
  ROL
  ROL
  ROL
  AND #UPPERMASK
  ORA #RS
  ; JSR lcd_instruction
  ; RTS
lcd_instruction:
  STA PORTA      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTA
  EOR #E         ; pull E bit low
  STA PORTA
  RTS