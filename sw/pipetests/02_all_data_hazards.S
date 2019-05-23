addi x1, x0, 0x100
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, -1
addi x1, x1, -1
addi x1, x1, -1
addi x1, x1, -1
lw x1, 0(x1)
lw x1, 0(x1)
lw x1, 0(x1)
lw x1, 0(x1)

nop
nop
nop
nop
unimp

. = 0x100
.word 0x104
.word 0x108
.word 0x10C
.word 0x110
