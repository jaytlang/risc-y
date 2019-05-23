.text
start:
    .word 0x80000033 // looks like an add instruction, but really isn't
    unimp
