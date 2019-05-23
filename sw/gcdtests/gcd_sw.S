.text
start:      li sp, 0x10000

            la s0, inputs
            la s1, outputs
            la s2, numinputs
            lw s2, 0(s2)

            // some sanity checks to avoid false positives
            bnez s2, sanity1         // the number of tests should not be 0
            li a0, 10
            jal exit
sanity1:    li t0, 1000
            bltu s2, t0, sanity2    // the number of tests should be less than 1000
            li a0, 20
            jal exit
sanity2:

main_loop:  beqz s2, end_loop
            lw a0, 0(s0)
            lw a1, 4(s0)
            jal gcd
            sw a0, 0(s1)
            addi s0, s0, 8
            addi s1, s1, 4
            addi s2, s2, -1
            j main_loop
end_loop:

            la s0, answers
            la s1, outputs
            la s2, numinputs
            lw s2, 0(s2)
            addi s2, s2, 1
            li s3, 1

check_loop: beq s3, s2, end_check
            lw t0, 0(s0)
            lw t1, 0(s1)
            beq t0, t1, skip_fail
            // fail
            mv a0, s3
            jal exit
skip_fail:  addi s0, s0, 4
            addi s1, s1, 4
            addi s3, s3, 1
            j check_loop
end_check:

            // if the program got here the right way, s2 == s3,
            // so this code will exit with the exit code 0 signaling
            // a successful execution of the program.
            sub a0, s2, s3
            jal exit

            unimp

// GCD Function

gcd:        beqz a0, a0_is_zero
gcd_loop:   beqz a1, gcd_end
            bgeu a1, a0, a1_ge_a0
            mv t0, a1
            mv a1, a0
            mv a0, t0
            j gcd_loop
a1_ge_a0:   sub a1, a1, a0
            j gcd_loop
a0_is_zero: mv a0, a1
gcd_end:    ret

            unimp

// exit Function

exit:       li t0, 0x40001000
            sw a0, 0(t0)

            unimp

.data
numinputs:  .word 4
inputs:     .word 25
            .word 17
            .word 779
            .word 1025
            .word 12920
            .word 43605
            .word 1000000
            .word 1007001
            .word 0xABCDEF
answers:    .word 1
            .word 41
            .word 1615
            .word 1
            .word 0x00ABCDEF
outputs:    .word 0x00ABCDEF
            .word 0x00ABCDEF
            .word 0x00ABCDEF
            .word 0x00ABCDEF
            .word 0x00ABCDEF

