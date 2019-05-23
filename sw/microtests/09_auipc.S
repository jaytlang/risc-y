.text
start:
    auipc x1, 1
    auipc x2, 0
    auipc x3, 0xFFFFF
    j faraway
    unimp
. = 0x1234
faraway:
    auipc x4, 0x80000
    auipc x5, 0x500
    nop
    nop
    nop
    nop
    unimp
