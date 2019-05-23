.text
start:
    lui x1, 1
    addi x1, x1, 4
    jalr x2, 0(x1) // jumps to 0x1004
    unimp

. = 0x1000
    jalr x6, 0x600(x1) // jumps to 0x1604
    jalr x3, 0x400(x1) // jumps to 0x1404
    unimp

. = 0x1400
    jalr x5, -4(x1) // jumps to 0x1000
    jalr x4, 0x3FC(x1) // jumps to 0x1400
    unimp

. = 0x1604
    nop
    nop
    nop
    nop
    unimp
