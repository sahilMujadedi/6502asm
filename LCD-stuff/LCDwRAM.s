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
  
  LDA #%01010000 ; write S
  JSR print_char
  LDA #%00110000
  JSR print_char
  
  LDA #%01100000 ; write a
  JSR print_char
  LDA #%00010000
  JSR print_char
  
  LDA #%01100000 ; write h
  JSR print_char
  LDA #%10000000
  JSR print_char
  
  LDA #%01100000 ; write i
  JSR print_char
  LDA #%10010000
  JSR print_char
  
  LDA #%01100000 ; write l
  JSR print_char
  LDA #%11000000
  JSR print_char
  
loop:
  JMP loop
  
  
print_char:
  ORA #RS
lcd_instruction:
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  RTS