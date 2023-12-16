  .org $200
  lda #$ff
  sta $5003
  
  ldx #$FF
loop:
  stx $5001
  jmp loop
