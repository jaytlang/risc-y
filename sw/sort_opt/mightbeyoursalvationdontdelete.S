.section ".text.init"
    .globl sort

/*
int* partition(int* p, int *startptr, int *endptr) {
    int x = *endptr; // threshold
    int *j, tmp, tmp2, *i = startptr - 1;
    for (j = startptr; j < endptr; j+=1) {
        //Dereference p[j] 
        int pj = *j;
        if (pj <= x) {
            i += 1;
            tmp = *i;
            *i = pj;
            *j = tmp;
        }
    }
    int *incrementedi = i + 1;
    tmp = *incrementedi;   //p[i+1]
    tmp2 = *endptr; //p[end]
    *endptr = tmp;
    *incrementedi = tmp2;
    return i + 1;
}

void shift_element(int *arr, int *i) {
	int ival;
	for(ival = *i; i > arr && *(i-1) > ival; i--) {
		*i = *(i-1);
	}
	*i = ival;
}

void insertion_sort(int *arr, int len) {
	int *i, *last = arr + len;
	for(i = arr + 1; i < last; i++)
		if(*i < *(i-1))
			shift_element(arr, i);
}



void go(int* p, int *startptr, int *endptr) {
    if (startptr < endptr) {
        if (endptr - startptr > 16) {
            int* q = partition(p, startptr, endptr);
            go(p, startptr, q - 1);
            go(p, q + 1, endptr);
        } else {
            insertion_sort(startptr, endptr-startptr+1);
        }
    }
 }


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
        bgeu    a1, a2, .SUBFUNCTION_END
        mv      s0, a2
        mv      s2, a0
        addi    s3, zero, 33
.SUBFUNCTION_2:                                # =>This Loop Header: Depth=1
        sub     a0, s0, a1
        blt     a0, s3, .SUBFUNCTION_8 		//fall to insertion sort
        addi    s1, a1, -4
        lw      a0, 0(s0)
        mv      a2, a1
.SUBFUNCTION_4:                                #   Parent Loop BB3_2 Depth=1
        lw      a3, 0(a2)
        blt     a0, a3, .SUBFUNCTION_6
        lw      a4, 4(s1)
        sw      a3, 4(s1)
        sw      a4, 0(a2)
        addi    s1, s1, 4
.SUBFUNCTION_6:                                #   in Loop: Header=BB3_4 Depth=2
        addi    a2, a2, 4
        bltu    a2, s0, .SUBFUNCTION_4
        lw      a0, 0(s0)
        lw      a2, 4(s1)
        sw      a2, 0(s0)
        sw      a0, 4(s1)
        mv      a0, s2
        mv      a2, s1
        call    go
        addi    a1, s1, 8
        bltu    a1, s0, .SUBFUNCTION_2 //tail call optimization
        j       .SUBFUNCTION_END

/* INSERTION SORT FOR <8 ELEMENTS */
.SUBFUNCTION_8:
        addi    a2, zero, 1
        blt     a0, a2, .SUBFUNCTION_END
        add     a0, a0, a1
        addi    a0, a0, 4
        addi    a3, a1, 4
        mv      a4, a1
.SUBFUNCTION_10:                               # =>This Loop Header: Depth=1
        mv      a2, a3
        lw      a3, 4(a4)
        lw      a4, 0(a4)
        bge     a3, a4, .SUBFUNCTION_17
        mv      a4, a2
        bgeu    a1, a2, .SUBFUNCTION_16
        mv      a5, a2
.SUBFUNCTION_13:                               #   Parent Loop BB3_10 Depth=1
        lw      s1, -4(a5)
        bge     a3, s1, .SUBFUNCTION_15
        addi    a4, a5, -4
        sw      s1, 0(a5)
        mv      a5, a4
        bltu    a1, a4, .SUBFUNCTION_13
        j       .SUBFUNCTION_16
.SUBFUNCTION_15:                               #   in Loop: Header=BB3_10 Depth=1
        mv      a4, a5
.SUBFUNCTION_16:                               #   in Loop: Header=BB3_10 Depth=1
        sw      a3, 0(a4)
.SUBFUNCTION_17:                               #   in Loop: Header=BB3_10 Depth=1
        addi    a3, a2, 4
        mv      a4, a2
        bltu    a3, a0, .SUBFUNCTION_10
.SUBFUNCTION_END:
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret
