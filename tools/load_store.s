; This is a one-pass assembler and cannot handle symbols defined later.

mem1 = $3c

ldi r1, 3            ; 00 07050003
loop1:
set r1, r1 >> 1      ; 04 000600c1
ldi!z pc, loop1      ; 08 0f090004
ldi r1, -$8000       ; 0c 07058000
xorih r1, $fffe      ; 10 0706fffe
loop2:
set r1, r1 << 1      ; 14 000600a1
ldi!z pc, loop2      ; 18 0f090014
ldi r1, mem1         ; 1c 0705003c
ld r1, [r1]          ; 20 07040800
ldi r1, mem1         ; 24 0705003c
st [r1, -4], r1      ; 28 07070ffc
ldi pc, 0            ; 2c 07090000

. = mem1 - 8
.int $dddddddd       ; 34 dddddddd
.int $eeeeeeee       ; 38 eeeeeeee
.int $12345678       ; 3c 12345678
