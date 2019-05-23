.text
start:
    addi x1, x0, 1
    add x2, x1, x0
    add x3, x2, x1
    add x4, x3, x2
    add x5, x4, x3
    add x6, x5, x4
    addi x7, x0, 0x7FF
    add x8, x1, x7
    add x9, x7, x7
    addi x10, x0, -2
    add x11, x1, x10
    nop
    nop
    nop
    nop
    unimp
