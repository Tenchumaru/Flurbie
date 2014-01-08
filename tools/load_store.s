; This is a one-pass assembler and cannot handle symbols defined later.

mem1 = $3c

ldi r1, 3            ; 00 07040003
loop1:
set r1, r1 >> 1      ; 04 000600c1
ldi!z pc, loop1      ; 08 0f080004
ldi r1, -$8000       ; 0c 07048000
xorih r1, $fffe      ; 10 0705fffe
loop2:
set r1, r1 << 1      ; 14 000600a1
ldi!z pc, loop2      ; 18 0f080014
ldi r1, mem1         ; 1c 0704003c
ld r1, [r1]          ; 20 07061000
ldi r1, mem1         ; 24 0704003c
st [r1, -4], r1      ; 28 07061ffc
ldi pc, 0            ; 2c 07080000

. = mem1 - 8
.int $dddddddd       ; 34 dddddddd
.int $eeeeeeee       ; 38 eeeeeeee
.int $12345678       ; 3c 12345678
