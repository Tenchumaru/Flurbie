; This is a one-pass assembler and cannot handle symbols defined later.

mem1 = $3c

ldi r1, mem1         ; 00 0705003c
ld r1, [r1]          ; 04 07040800
set r3, r1           ; 08 000e0080
ldi pc, 0            ; 0c 07090000

. = mem1 - 8
.int $dddddddd       ; 34 dddddddd
.int $eeeeeeee       ; 38 eeeeeeee
.int $12345678       ; 3c 12345678
