ldi r1, 17		 ; 00 07040011  11
add r1, r1, pc	 ; 04 00061100  15
mul r1, r1, 5	 ; 08 02041005  69
div r1, r1, 5	 ; 0c 03041005  15
umul r1, r1, 5	 ; 10 02841005  69
udiv r1, r1, 5	 ; 14 03841005  15
mul r1, r1, -5	 ; 18 02041ffb  FF97
div r1, r1, -5	 ; 1c 03041ffb  15
umul r1, r1, -5	 ; 20 02841ffb  FF97
udiv r1, r1, -5	 ; 24 03841ffb  0
sub r1, r1, 5	 ; 28 01041005  FFFB
add r1, r1, 5	 ; 2c 00041005  0
ldi r3, -1		 ; 30 070cffff  0
subb r1, r1, 5	 ; 34 01841005  FFFA
ldi r3, -1		 ; 38 070cffff  FFFA
addc r1, r1, 5	 ; 3c 00841005  0
ldi pc, 0		 ; 40 07080000  0
