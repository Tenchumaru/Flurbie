; This is a one-pass assembler and cannot handle symbols defined later.

mem1 = $3c

ldi r1, 2	         ; 00 07040002
loop1:
set r1, r1 >> 1      ; 04 000600c1
ldi!z pc, loop1      ; 08 0f080004
ldi r1, mem1         ; 0c 0704003c
ld r1, [r1]          ; 10 07061000
set r3, r1           ; 14 000e0080
ldi r3, mem1         ; 18 070c003c
st [r3, -4], r1      ; 1c 070e1ffc
ldi pc, 0            ; 20 07080000

. = mem1 - 8
.int $dddddddd       ; 34 dddddddd
.int $eeeeeeee       ; 38 eeeeeeee
.int $12345678       ; 3c 12345678
