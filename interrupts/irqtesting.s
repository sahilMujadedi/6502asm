UPPERMASK=$F0
LOWERMASK=$0F

; via stuff

;via 1
PORTB=$6000
PORTA=$6001
DDRB=$6002
DDRA=$6003
;via 2
PORTD=$5000
PORTC=$5001
DDRD=$5002
DDRC=$5003
VIA2_PCR=$500C
VIA2_IFR=$500D
VIA2_IER=$500E

; first 4 bits represent data, MSB to LSB
RS=%00000010
RW=%00000100
E= %00001000


; BCD stuff
value=$00 ; 2 byte unsigned 16-bit integer memory space
mod10=$02 ; 1 byte to perform operations on to create BCD
bcd_out=$03 ; 6 bytes (5 possible digits in 16 bit int, plus null terminator

; irq stuff
counter=$09 ; 2 bytes, 16-bit integer

  .org $8000

  JMP reset
irq:
  PHA
  PHX
  PHY



  INC counter
  BNE exit_irq
  INC counter + 1

  LDA #%00000010 ; clear display
  JSR lcd_instruction

exit_irq:
  PLA
  PLX
  PLY

  BIT PORTD ; clear VIA interrupt by reading portd

  RTI


reset:
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
  
  LDA #%00001100 ; display on/off control
  JSR lcd_instruction
  
  LDA #%00000110 ; entry mode set
  JSR lcd_instruction
  
  LDA #%00000001 ; clear display
  JSR lcd_instruction

  STZ counter
  STZ counter + 1

  CLI

  LDA #$90       ; enable interrupts from CB1
  STA VIA2_IER
  STZ VIA2_PCR

loop:
  CLI
  LDA counter      ; store number into ram (zero-page)
  STA value
  LDA counter + 1
  STA value + 1

  STZ bcd_out
divide:
  STZ mod10      ; init remainder to 0
  
  CLC
  LDX #16
divloop:
  ROL value       ; shift all bits left
  ROL value + 1
  ROL mod10

  SEC             ; dividend - divisor
  LDA mod10
  SBC #10
  BCC ignore_bcd_result  ; if dividend - divisor is negative
  STA mod10

ignore_bcd_result:
  DEX
  BNE divloop

  ROL value        ; shift in last bit of quotient into value
  ROL value + 1

  LDA mod10        ; load accumulator w/ mod10, convert value to ascii, print it out
  CLC
  ADC #"0"
  JSR push_bcd_char

  LDA value        ; check if all digits have been completed, if not (value != 0), clear mod10 and keep going
  ORA value + 1
  BNE divide

  LDA #%00000010 ; clear display
  JSR lcd_instruction
  
  SEI
  LDX #0
print:
  LDA bcd_out,x
  BEQ loop
  JSR print_char
  INX
  BRA print

push_bcd_char:
  PHA
  LDY #0
bcd_char_loop:
  LDA bcd_out,y
  TAX
  PLA
  STA bcd_out,y
  INY
  TXA
  PHA
  BNE bcd_char_loop

  PLA
  STA bcd_out,y

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
