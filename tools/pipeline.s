; This is a one-pass assembler and cannot handle symbols defined later.

mem1 = $3c

ldi r1, 2	         ; 00 07050002
loop1:
set r1, r1 >> 1      ; 04 000600c1
ldi!z pc, loop1      ; 08 0f090004
ldi r1, mem1         ; 0c 0705003c
ld r1, [r1]          ; 10 07040800
set r3, r1           ; 14 000e0080
ldi pc, 0            ; 18 07090000

. = mem1 - 8
.int $dddddddd       ; 34 dddddddd
.int $eeeeeeee       ; 38 eeeeeeee
.int $12345678       ; 3c 12345678
