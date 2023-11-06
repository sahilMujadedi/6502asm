UPPERMASK=$F0
LOWERMASK=$0F

PORTB=$6000
PORTA=$6001
DDRB=$6002
DDRA=$6003
; first 4 bits represent data, MSB to LSB
RS=%00000010
RW=%00000100
E= %00001000



  .org $8000

reset:  
  LDA #%11111111 ; set all pins on port A to output
  STA DDRA
  
  LDA #%00100000 ; set 4 bit mode
  JSR lcd_send
  JSR check_busy
  JSR lcd_send
  
  LDA #%10000000 ; set 2 line mode, 5x8 font
  JSR lcd_send
  JSR check_busy
  ;; end of 4 bit set up. control from here is the exact same as 8 bit mode.
  
  LDA #%00001111 ; display on/off control
  JSR lcd_instruction
  
  LDA #%00000110 ; entry mode set
  JSR lcd_instruction
  
  LDA #%00000001 ; clear display
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
  
message: .asciiz "I'm alive!" ; creates a null-terminated string in memory
print_char:
  PHA                  ; push a onto stack to preserve the char
  PHA
  JSR check_busy
  PLA

  AND #UPPERMASK       ; manipulate it for the high nibble
  ORA #RS

  JSR lcd_send
  PLA                  ; pull a back to use the lower nibble
  ASL
  ASL
  ASL
  ASL
  ORA #RS
  JSR lcd_send
  RTS
lcd_instruction:
  PHA
  PHA
  JSR check_busy
  PLA

  AND #UPPERMASK
  
  JSR lcd_send
  PLA
  ASL
  ASL
  ASL
  ASL
  ; JSR lcd_send
  ; RTS
lcd_send:
  STA PORTA      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTA
  EOR #E         ; pull E bit low
  STA PORTA
  RTS
check_busy:      ; screws with accumulator, make sure to push it onto stack before running subroutine

  LDA #(RS | RW | E)  ; set all data pins to input
  STA DDRA

  LDA #RW             ; enable read mode
  STA PORTA
  ORA #E
  STA PORTA

  LDA PORTA           ; read busy flag
  PHA                 ; push busy flag onto stack
  EOR #E
  STA PORTA
  ORA #E
  STA PORTA
  LDA PORTA           ; read other data, unnecessary but required read
  PLA
  AND #%10000000      ; if busy flag = 1, then loop check_busy
  BNE check_busy

  LDA #$ff            ; set pins back to outputs
  STA DDRA

  RTS