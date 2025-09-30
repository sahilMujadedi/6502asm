# Code for SalBox
This is a little project I've been working on.
I've built a computer based on the 6502 microprocessor from the 70's ( a newer variant of it ) based on Ben Eater's 6502 series.
I'm branching out at this point to build a different type of computer, so I've named it the SalBox. This is nothing serious, so my git work will look messy.

I'm using the VASM assembler ( google it ) for this, use this command to generate a binary file in the correct format:

```vasm6502_oldstyle -Fbin -dotdir -wdc02 example.s```

I then use this command with hexdump to return the binary in the correct format into the clipboard, depends on hexdump and xclip:

```hexdump -ve '1/1 \"0x%02x,\"' a.out | xclip -selection clipboard```

Then paste into the "instructions" array of the arduino EEPROM Programmer ino file, run the writeInstructions(0x0000) to start writing at the beginning of the EEPROM, and it should program the EEPROM. Keep in mind this program was created for the 28C256 32 KB EEPROM using two 74HC595 shift registers for address selection and 8 I/O pins for data read and write.




