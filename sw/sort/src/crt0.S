.section ".text.init"
    .globl _start
    .globl exit
    .globl main
    .globl print_char
    .globl load_arg
_start:
    // initialize global pointer
    // la gp, _gp
    li gp, 0

    // initialize stack pointer
    // hard-code sp to the top of memory (assuming 64 KB)
    li sp, 0x10000

    call main
    j exit

print_char:
    andi t0, a0, 0xff
    li t1, 0x40000000
    sw t0, 0(t1)
    ret

load_arg:
    li t0, 0x40003000
    lw a0, 0(t0)
    ret

exit:
    li t0, 0x40001000
    sw a0, 0(t0)

exit_loop:
    beq x0, x0, exit_loop
