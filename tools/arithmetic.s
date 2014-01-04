ldi r1, 17		 ; 00 0x07050011
add r1, r1, pc	 ; 04 0x00061100
mul r1, r1, 5	 ; 08 0x02041005
div r1, r1, 5	 ; 0c 0x03041005
umul r1, r1, 5	 ; 10 0x02841005
udiv r1, r1, 5	 ; 14 0x03841005
mul r1, r1, -5	 ; 18 0x02041ffb
div r1, r1, -5	 ; 1c 0x03041ffb
umul r1, r1, -5	 ; 20 0x02841ffb
udiv r1, r1, -5	 ; 24 0x03841ffb
sub r1, r1, 5	 ; 28 0x01041005
add r1, r1, 5	 ; 2c 0x00041005
ldi r3, -1		 ; 30 0x070dffff
subb r1, r1, 5	 ; 34 0x01841005
ldi r3, -1		 ; 38 0x070dffff
addc r1, r1, 5	 ; 3c 0x00841005
ldi pc, 0		 ; 40 0x07090000
