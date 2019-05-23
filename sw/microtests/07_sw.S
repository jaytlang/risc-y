.text
start:
    lui x1, 1 // should match the address of e
    addi x2, x0, 15
    sw x2, 0(x1)
    addi x2, x0, 10
    sw x2, 4(x1)
    addi x2, x0, 5
    sw x2, 8(x1)
    addi x2, x0, 0
    sw x2, 12(x1)
    addi x2, x0, 1
    sw x2, -4(x1)
    addi x2, x0, 2
    sw x2, -8(x1)
    addi x2, x0, 4
    sw x2, -12(x1)
    addi x2, x0, 8
    sw x2, -16(x1)
    addi x3, x0, 0x400
    addi x3, x3, 0x400
    addi x2, x0, 100
    sw x2, 0x7F0(x10) // should matche the address of a
    addi x2, x0, 200
    sw x2, 0x7FC(x10)
    nop
    nop
    nop
    nop
    unimp
    // check
    lw x2, 0(x1)
    lw x3, 4(x1)
    lw x4, 8(x1)
    lw x5, 12(x1)
    lw x6, -4(x1)
    lw x7, -8(x1)
    lw x8, -12(x1)
    lw x9, -16(x1)

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

