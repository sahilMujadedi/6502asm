UPPERMASK=$F0
LOWERMASK=$0F

PORTB=$6000
DDRB=$6002
; first 4 bits represent data
RS=%00001000
RW=%00000100
E= %00000010

  .org $8000

reset:  
  LDA #%11111111 ; set all pins on port B to output
  STA DDRB
  
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
  LDA message,x
  BEQ loop
  JSR print_char
  INX
  JMP print
  
loop:
  JMP loop
  
message: .asciiz "Sahil is cool"
print_char:
  PHA
  AND #UPPERMASK
  ORA #RS
  JSR lcd_instruction
  PLA
  ROL
  ROL
  ROL
  ROL
  AND #UPPERMASK
  ORA #RS
  JSR lcd_instruction
  RTS
lcd_instruction:
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  RTS