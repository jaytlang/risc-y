.section ".text.init"
    .globl _start
    .globl exit
    .globl main
_start:
    // initialize global pointer
    // la gp, _gp
    li gp, 0

    // initialize stack pointer
    // hard-code sp to the top of memory (assuming 64 KB)
    li sp, 0x10000

    call main
    j exit



exit:
    li t0, 0x40001000
    sw a0, 0(t0)

exit_loop:
    beq x0, x0, exit_loop
