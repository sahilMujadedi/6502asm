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

VIA_ACR=$600B ; VIA 2 assumed
VIA_T1CL=$6004
VIA_T1CH=$6005
VIA_T2CL=$6008
VIA_T2CH=$6009
VIA_IER=$600E

; first 4 bits represent data, MSB to LSB
RS=%00000010
RW=%00000100
E= %00001000

kb_buffer=$0200 ; 256 bytes for keyboard input
kb_rptr=$00     ; write pointer increments even when computer is not ready to display, read pointer updates display and increments when it is ready
kb_wptr=$01     ; both 1 byte

kb_flags=$02    ; 1 byte
RELEASE=%00000001
LSHIFT =%00000010
RSHIFT =%00000100

calc_ptr=$03
calcval1=$04
calcval2=$05
calcvalbuf=$06 ; holds value to be transferred into calcval1 or 2


  .org $8000
  JMP reset
irq:
  PHA
  PHX
  LDA kb_flags
  AND #RELEASE
  BEQ read_key
  
  LDA kb_flags
  EOR #RELEASE
  STA kb_flags
  LDA PORTA
  CMP #$12 ; lshift
  BEQ lshift_up
  CMP #$59 ; rshift
  BEQ rshift_up
  BRA exit_irq
lshift_up:
  LDA kb_flags
  EOR #LSHIFT  ; flip shift bit
  STA kb_flags
  BRA exit_irq
rshift_up:
  LDA kb_flags
  EOR #RSHIFT
  STA kb_flags
  BRA exit_irq

read_key:
  LDA PORTA
  CMP #$F0
  BEQ release_key
  CMP #$12 ; lshift
  BEQ lshift_down
  CMP #$59 ; rshift
  BEQ rshift_down

  TAX
  LDA kb_flags
  AND #(LSHIFT | RSHIFT)
  BNE shifted_key

  LDA keymap,x
  BRA push_key

shifted_key:
  LDA keymap_shifted,x  
push_key:
  LDX kb_wptr
  STA kb_buffer,x
  INC kb_wptr
  BRA exit_irq
release_key:
  LDA kb_flags
  ORA #RELEASE
  STA kb_flags
  BRA exit_irq
lshift_down:
  LDA kb_flags
  ORA #LSHIFT
  STA kb_flags
  BRA exit_irq
rshift_down:
  LDA kb_flags
  ORA #RSHIFT
  STA kb_flags
  ; BRA exit_irq

exit_irq:      
  LDA #10          ; wait for 11 pulses on PB6 then generate interrupt. this clears the interrupt and also sets it for the next one.
  STA VIA_T2CL
  STZ VIA_T2CH

  PLA
  PLX
  RTI
end_irq:
  RTI
reset:
  LDX #$FF
  TXS
  LDA #%11111111 ; set all pins on port C to output
  STA DDRC

  STZ DDRA ; set all pins on port A to input
  STZ DDRB ; set all pins on port B to input
  
  
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

  LDA #%00100000
  STA VIA_ACR

  LDA #%10100000
  STA VIA_IER

  LDA #10
  STA VIA_T2CL
  STZ VIA_T2CH
  
  STZ kb_wptr
  STZ kb_rptr
  STZ kb_flags

  STZ calc_ptr

  CLI
  JMP loop

loop:
  SEI
  LDA kb_rptr
  CMP kb_wptr
  CLI
  BNE key_pressed
  JMP loop
key_pressed:
  LDX kb_rptr
  LDA kb_buffer,x
  CMP #$0a
  BEQ sum
  CMP #$1b
  BEQ clear_screen
  CMP #$08
  BEQ backspace

  JSR print_char
  INC kb_rptr
  INC calc_ptr
  BRA loop
line_feed:
  LDA #%10101000 ; load $40 into DDRAM to push cursor down
  JSR lcd_instruction
  INC kb_rptr
  BRA loop
clear_screen:
  LDA #%00000001 ; clear display
  JSR lcd_instruction
  INC kb_rptr
  STZ calc_ptr
  BRA loop
backspace:
  LDA #%00010000 ; move cursor backwards
  JSR lcd_instruction
  INC kb_rptr
  DEC calc_ptr
  BRA loop
sum:
  LDX #0
sumloop:
  LDA kb_buffer,x
  STA calcvalbuf
  INX
  LDA kb_buffer,x
  STA calcvalbuf + 1
  JSR ascii_to_bin1
  LDA calcvalbuf
  STA calcval1
  INX
  INX
  LDA kb_buffer,x
  STA calcvalbuf
  INX
  LDA kb_buffer,x
  STA calcvalbuf + 1
  JSR ascii_to_bin1
  LDA calcvalbuf
  STA calcval2

exit_sumloop:
  CLC
  LDA calcval1
  ADC calcval2
  PHA
  LDA #%10101000 ; load $40 into DDRAM to push cursor down
  JSR lcd_instruction
  PLA
  JSR bin_to_ascii
  
  BRA loop


ascii_to_bin1:
  LDA calcvalbuf
  BIT #%11000000 ; check if hex or digit
  BEQ dig1
  AND #LOWERMASK
  TAX
  LDA ascii_to_bin_map,x
  ASL
  ASL
  ASL
  ASL
  STA calcvalbuf
dig1:
  AND #LOWERMASK
  ASL
  ASL
  ASL
  ASL
  STA calcvalbuf
ascii_to_bin2:
  LDA calcvalbuf + 1
  BIT #%11000000 ; check if hex or digit
  BEQ dig2
  AND #LOWERMASK
  TAX
  LDA ascii_to_bin_map,x
  ORA calcvalbuf
  STA calcvalbuf
dig2:
  AND #LOWERMASK
  ORA calcvalbuf
  STA calcvalbuf
  RTS
bin_to_ascii:
  PHA
  AND #UPPERMASK
  LSR
  LSR
  LSR
  LSR
  TAX
  LDA hexmap,x
  JSR print_char
  PLA
  AND #LOWERMASK
  TAX
  LDA hexmap,x
  JSR print_char
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
ascii_to_bin_map:
  .byte $00, $0a, $0b, $0c, $0d, $0e, $0f
hexmap:
  .byte "0123456789ABCDEF"
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=????", $0a, "]?\??" ; 50-5F
  .byte "??????", $08, "??1?47???" ; 60-6F
  .byte "0.2568", $1b, "??+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF
keymap_shifted:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q!???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte '??"?{+?????}?|??' ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF