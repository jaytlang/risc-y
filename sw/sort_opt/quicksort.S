.section ".text.init"
    .globl sort

/*
C implementation (for reference)

int partition(int* p, int start, int end) {
    int x = p[end]; // threshold
    int j, tmp, i = start - 1;
    for (j = start; j < end; j++) {
        if (p[j] <= x) {
            i++;
            tmp = p[i];
            p[i] = p[j];
            p[j] = tmp;
        }
    }
    tmp = p[i + 1];
    p[i + 1] = p[end];
    p[end] = tmp;
    return i + 1;
}

void quicksort(int* p, int start, int end) {
    if (start < end) {
        int q = partition(p, start, end);
        quicksort(p, start, q - 1);
        quicksort(p, q + 1, end);
    }
}

*/

/* 
Given A0 (memory address of starting point), A1 (first), A2 (last)
Prefer not using the stack over active registers for performance

PERSONAL CONVENTION: A0/A1/A2 hold original purposes, A3-7 used for other values
		     T0.... used for SOLELY MEMORY REGISTER HOLDINGS
*/

/*
ASSUMPTIONS ABOUT PERFORMANCE COUNTING
- total performance counting: we want to use the cycle counter to capture THE ENTIRE EXECUTION. this will wind up including the wrapper, but i'm curious to see the impact the wrapper has given the 50,000-150,000 range for quicksort given.

- partition: obviously use performance counter to do that math. we gotta make sure it's stopped, store the value somewhere, and then re-go-back and subtract values off. 

*/
sort:
	slli 	a2, a2, 2
	slli 	a1, a1, 2
	add 	a1, a1, a0
	add 	a2, a2, a0
go:                            # @go(int*, int*, int*)
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        bgeu    a1, a2, .LBB3_18
        mv      s0, a2
        mv      s2, a0
        addi    s3, zero, 37
.LBB3_2:                                # =>This Loop Header: Depth=1
        sub     a0, s0, a1
        blt     a0, s3, .LBB3_8
        addi    s1, a1, -4
        lw      a0, 0(s0)
        mv      a2, a1
.LBB3_4:                                #   Parent Loop BB3_2 Depth=1
        lw      a3, 0(a2)
        blt     a0, a3, .LBB3_6
        lw      a4, 4(s1)
        sw      a3, 4(s1)
        sw      a4, 0(a2)
        addi    s1, s1, 4
.LBB3_6:                                #   in Loop: Header=BB3_4 Depth=2
        addi    a2, a2, 4
        bltu    a2, s0, .LBB3_4
        lw      a0, 0(s0)
        lw      a2, 4(s1)
        sw      a2, 0(s0)
        sw      a0, 4(s1)
        mv      a0, s2
        mv      a2, s1
        call    go
        addi    a1, s1, 8
        bltu    a1, s0, .LBB3_2
        j       .LBB3_18
.LBB3_8:
        addi    a2, zero, 1
        blt     a0, a2, .LBB3_18
        add     a0, a0, a1
        addi    a0, a0, 4
        addi    a3, a1, 4
        mv      a4, a1
.LBB3_10:                               # =>This Loop Header: Depth=1
        mv      a2, a3
        lw      a3, 4(a4)
        lw      a4, 0(a4)
        bge     a3, a4, .LBB3_17
        mv      a4, a2
        bgeu    a1, a2, .LBB3_16
        mv      a5, a2
.LBB3_13:                               #   Parent Loop BB3_10 Depth=1
        lw      s1, -4(a5)
        bge     a3, s1, .LBB3_15
        addi    a4, a5, -4
        sw      s1, 0(a5)
        mv      a5, a4
        bltu    a1, a4, .LBB3_13
        j       .LBB3_16
.LBB3_15:                               #   in Loop: Header=BB3_10 Depth=1
        mv      a4, a5
.LBB3_16:                               #   in Loop: Header=BB3_10 Depth=1
        sw      a3, 0(a4)
.LBB3_17:                               #   in Loop: Header=BB3_10 Depth=1
        addi    a3, a2, 4
        mv      a4, a2
        bltu    a3, a0, .LBB3_10
.LBB3_18:
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret
