UPPERMASK=$F0
LOWERMASK=$0F

PORTD=$5000
PORTC=$5001
PORTB=$6000
PORTA=$6001

DDRD=$5002
DDRC=$5003
DDRB=$6002
DDRA=$6003

VIA_ACR=$500B ; VIA 2 assumed
VIA_T1CL=$5004
VIA_T1CH=$5005
VIA_IER=$500E

; first 4 bits represent data, MSB to LSB
RS=%00000010
RW=%00000100
E= %00001000

BYTE=$00 ; one byte value
BYTE_DISPLAY=$0200 ; up to 34 bytes, one extra byte to account for line break with $0D on a 16x2 display and one for termination
BYTE_DISPLAY_CURSOR=$0222 ; one byte value that points cursor at a position in byte_display

ticks=$01
toggle_time=$05

  .org $8000
  JMP reset
irq:
  BIT VIA_T1CL
  INC ticks
  BNE end_irq
  INC ticks + 1
  BNE end_irq
  INC ticks + 2
  BNE end_irq
  INC ticks + 3
end_irq:
  RTI
reset:
  STZ toggle_time
  JSR init_timer

  LDA #%11111111 ; set all pins on port A to output
  STA DDRC
  
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

  STZ BYTE
  STZ BYTE_DISPLAY_CURSOR
  BRA binary_to_display
  
begin_print:
  LDA #%00000001 ; clear display
  JSR lcd_instruction

  LDX #0
  CLC
print:
  LDA BYTE_DISPLAY,x   ; use x as index to continually print out chars in "message"
  BEQ loop
  CMP #$0D
  BEQ carriage_return
  JSR print_char
  INX
  BRA print
carriage_return:
  LDA #%10101000 ; load $40 into DDRAM to push cursor down
  JSR lcd_instruction
  INX
  BRA print

loop:
  SEC
  LDA ticks
  SBC toggle_time
  CMP #50 ; have 500 ms elapsed?
  BCC loop

  INC BYTE
  STZ BYTE_DISPLAY_CURSOR
  LDA ticks
  STA toggle_time
  BRA binary_to_display

  JMP loop
  
; message: 
;   .byte "Beep boop." ; creates a null-terminated string in memory
;   .byte $0D
;   .asciiz "I'm a robot"
binary_to_display:
  LDX BYTE_DISPLAY_CURSOR
  LDA #%10000000
  CLC
btd_loop:
  BCS binary_to_hex_to_display
  BIT BYTE
  BNE return_1
  PHA
  LDA #"0"
  STA BYTE_DISPLAY,x
  PLA
  ROR
  INX
  ; STX BYTE_DISPLAY_CURSOR
  ; STZ BYTE_DISPLAY,x
  BRA btd_loop
return_1:
  PHA
  LDA #"1"
  STA BYTE_DISPLAY,x
  PLA
  INX
  ; STX BYTE_DISPLAY_CURSOR
  ; STZ BYTE_DISPLAY,x
  ROR
  BRA btd_loop

binary_to_hex_to_display:
  LDA #$0D ; carriage return ascii
  STA BYTE_DISPLAY,x
  INX
  STX BYTE_DISPLAY_CURSOR
  LDA BYTE
  AND #UPPERMASK
  LSR
  LSR
  LSR
  LSR
  TAX
  LDA hexmap,x
  LDX BYTE_DISPLAY_CURSOR
  STA BYTE_DISPLAY,x
  INX
  STX BYTE_DISPLAY_CURSOR

  LDA BYTE
  AND #LOWERMASK
  TAX
  LDA hexmap,x
  LDX BYTE_DISPLAY_CURSOR
  STA BYTE_DISPLAY,x
  INX
  STZ BYTE_DISPLAY,x

  JMP begin_print

init_timer:
  STZ ticks
  STZ ticks + 1
  STZ ticks + 2
  STZ ticks + 3
  LDA #%01000000  ; enable timer 1 continuous interrupt mode
  STA VIA_ACR
  ; creates a 10 ms delay, as $4800 clock cycles takes 10 ms to go through, minus two because of two added cycles from VIA
  LDA #$FE
  STA VIA_T1CL
  LDA #$47
  STA VIA_T1CH

  LDA #%11000000 ; enable interrupts from timer 1
  STA VIA_IER

  CLI
  RTS


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
  STA PORTC      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTC
  EOR #E         ; pull E bit low
  STA PORTC
  RTS
check_busy:      ; screws with accumulator, make sure to push it onto stack before running subroutine

  LDA #(RS | RW | E)  ; set all data pins to input
  STA DDRC

  LDA #RW             ; enable read mode
  STA PORTC
  ORA #E
  STA PORTC

  LDA PORTC           ; read busy flag
  PHA                 ; push busy flag onto stack
  EOR #E
  STA PORTC
  ORA #E
  STA PORTC
  LDA PORTC           ; read other data, unnecessary but required read
  PLA
  AND #%10000000      ; if busy flag = 1, then loop check_busy
  BNE check_busy

  LDA #$ff            ; set pins back to outputs
  STA DDRC

  RTS

hexmap:
  .byte "0123456789ABCDEF"