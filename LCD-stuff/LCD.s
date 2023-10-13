PORTB=$6000
DDRB=$6002
RS=%00001000
RW=%00000100
E= %00000010

  .org $8000
  
  LDA #%11111111 ; set all pins on port B to output
  STA DDRB
  
  LDA #%00100000 ; set 4 bit mode
  
  STA PORTB      ; instruction cycle, must be run twice for 4 bit mode
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%10000000 ; set 2 line mode, 5x8 font
  
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%00000000 ; display on/off control
  
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%11110000 
  
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%00000000 ; entry mode set
  
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%01100000 
  
  STA PORTB      ; instruction cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%01000000 ; write H
  
  ORA #RS
  STA PORTB      ; write cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
  LDA #%10000000 
  
  ORA #RS
  STA PORTB      ; write cycle
  ORA #E         ; pull E bit high
  STA PORTB
  EOR #E         ; pull E bit low
  STA PORTB
  
loop:
  JMP loop
