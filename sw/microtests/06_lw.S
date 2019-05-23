.text
start:
    lui x1, 1 // should match the address of e
    lw x2, 0(x1)
    lw x3, 4(x1)
    lw x4, 8(x1)
    lw x5, 12(x1)
    lw x6, -4(x1)
    lw x7, -8(x1)
    lw x8, -12(x1)
    lw x9, -16(x1)
    addi x10, x0, 0x400
    addi x10, x10, 0x400
    lw x11, 0x7F0(x10) // should matche the address of a
    lw x12, 0x7F4(x10)
    lw x13, 0x7F8(x10)
    lw x14, 0x7FC(x10)
    nop
    nop
    nop
    nop
    unimp

.data
. = 0x0FF0
a:      .word 0
b:      .word 1
c:      .word 52
d:      .word -215
e:      .word 17
f:      .word 59
g:      .word 12
h:      .word -16

