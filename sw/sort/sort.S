.section ".text.init"
    .globl sort

//If you want the C source come talk to me
//620 lines of pain
sort:
	slli 	a2, a2, 2
	slli 	a1, a1, 2
	add 	a1, a1, a0
	add 	a2, a2, a0


_Z2goPiS_S_:
	bgeu	a1,a2,.L127
	addi	sp,sp,-32
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	ra,28(sp)
	sub	a5,a2,a1
	li	a4,64
	mv	s0,a1
	mv	s1,a2
	mv	s2,a0
	li	s3,64
	ble	a5,a4,.L117
.L116:
	mv	a1,s1
	mv	a0,s0
	call	_Z9partitionPiS_
	mv	a5,a0
	mv	a1,s0
	addi	a2,a0,-4
	mv	a0,s2
	addi	s0,a5,4
	call	_Z2goPiS_S_
	sub	a5,s1,s0
	bgeu	s0,s1,.L114
	bgt	a5,s3,.L116
.L117:
	andi	a2,a5,-4
	addi	a2,a2,4
	add	a2,s0,a2
	addi	a3,s0,4
	bgtu	a2,a3,.L122
	j	.L114
.L120:
	addi	a3,a3,4
	bleu	a2,a3,.L114
.L122:
	lw	a1,0(a3)
	lw	a4,-4(a3)
	ble	a4,a1,.L120
	mv	a5,a3
	j	.L119
.L130:
	lw	a4,-4(a5)
	ble	a4,a1,.L121
.L119:
	sw	a4,0(a5)
	addi	a5,a5,-4
	bgtu	a5,s0,.L130
.L121:
	sw	a1,0(a5)
	addi	a3,a3,4
	bgtu	a2,a3,.L122
.L114:
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	addi	sp,sp,32
	jr	ra
.L127:
	ret
_Z9partitionPiS_:
	addi	a6,a1,-180
	mv	a5,a0
	lw	a2,0(a1)
	addi	a7,a1,-40
	lw	a3,0(a0)
	mv	a4,a0
	bgeu	a0,a6,.L90
.L2:
	lw	a0,0(a4)
	bge	a0,a2,.L5
	sw	a3,0(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L5:
	lw	a0,4(a4)
	bge	a0,a2,.L6
	sw	a3,4(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L6:
	lw	a0,8(a4)
	bge	a0,a2,.L7
	sw	a3,8(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L7:
	lw	a0,12(a4)
	bge	a0,a2,.L8
	sw	a3,12(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L8:
	lw	a0,16(a4)
	bge	a0,a2,.L9
	sw	a3,16(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L9:
	lw	a0,20(a4)
	bge	a0,a2,.L10
	sw	a3,20(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L10:
	lw	a0,24(a4)
	bge	a0,a2,.L11
	sw	a3,24(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L11:
	lw	a0,28(a4)
	bge	a0,a2,.L12
	sw	a3,28(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L12:
	lw	a0,32(a4)
	bge	a0,a2,.L13
	sw	a3,32(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L13:
	lw	a0,36(a4)
	bge	a0,a2,.L14
	sw	a3,36(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L14:
	lw	a0,40(a4)
	bge	a0,a2,.L15
	sw	a3,40(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L15:
	lw	a0,44(a4)
	bge	a0,a2,.L16
	sw	a3,44(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L16:
	lw	a0,48(a4)
	bge	a0,a2,.L17
	sw	a3,48(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L17:
	lw	a0,52(a4)
	bge	a0,a2,.L18
	sw	a3,52(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L18:
	lw	a0,56(a4)
	bge	a0,a2,.L19
	sw	a3,56(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L19:
	lw	a0,60(a4)
	bge	a0,a2,.L20
	sw	a3,60(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L20:
	lw	a0,64(a4)
	bge	a0,a2,.L21
	sw	a3,64(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L21:
	lw	a0,68(a4)
	bge	a0,a2,.L22
	sw	a3,68(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L22:
	lw	a0,72(a4)
	bge	a0,a2,.L23
	sw	a3,72(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L23:
	lw	a0,76(a4)
	bge	a0,a2,.L24
	sw	a3,76(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L24:
	lw	a0,80(a4)
	bge	a0,a2,.L25
	sw	a3,80(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L25:
	lw	a0,84(a4)
	bge	a0,a2,.L26
	sw	a3,84(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L26:
	lw	a0,88(a4)
	bge	a0,a2,.L27
	sw	a3,88(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L27:
	lw	a0,92(a4)
	bge	a0,a2,.L28
	sw	a3,92(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L28:
	lw	a0,96(a4)
	bge	a0,a2,.L29
	sw	a3,96(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L29:
	lw	a0,100(a4)
	bge	a0,a2,.L30
	sw	a3,100(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L30:
	lw	a0,104(a4)
	bge	a0,a2,.L31
	sw	a3,104(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L31:
	lw	a0,108(a4)
	bge	a0,a2,.L32
	sw	a3,108(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L32:
	lw	a0,112(a4)
	bge	a0,a2,.L33
	sw	a3,112(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L33:
	lw	a0,116(a4)
	bge	a0,a2,.L34
	sw	a3,116(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L34:
	lw	a0,120(a4)
	bge	a0,a2,.L35
	sw	a3,120(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L35:
	lw	a0,124(a4)
	bge	a0,a2,.L36
	sw	a3,124(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L36:
	lw	a0,128(a4)
	bge	a0,a2,.L37
	sw	a3,128(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L37:
	lw	a0,132(a4)
	bge	a0,a2,.L38
	sw	a3,132(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L38:
	lw	a0,136(a4)
	bge	a0,a2,.L39
	sw	a3,136(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L39:
	lw	a0,140(a4)
	bge	a0,a2,.L40
	sw	a3,140(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L40:
	lw	a0,144(a4)
	bge	a0,a2,.L41
	sw	a3,144(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L41:
	lw	a0,148(a4)
	bge	a0,a2,.L42
	sw	a3,148(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L42:
	lw	a0,152(a4)
	bge	a0,a2,.L43
	sw	a3,152(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L43:
	lw	a0,156(a4)
	bge	a0,a2,.L44
	sw	a3,156(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L44:
	lw	a0,160(a4)
	bge	a0,a2,.L45
	sw	a3,160(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L45:
	lw	a0,164(a4)
	bge	a0,a2,.L46
	sw	a3,164(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L46:
	lw	a0,168(a4)
	bge	a0,a2,.L47
	sw	a3,168(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L47:
	lw	a0,172(a4)
	bge	a0,a2,.L48
	sw	a3,172(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L48:
	lw	a0,176(a4)
	bge	a0,a2,.L49
	sw	a3,176(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L49:
	addi	a4,a4,180
	bgtu	a6,a4,.L2
.L90:
	bleu	a7,a4,.L92
.L4:
	lw	a0,0(a4)
	bge	a0,a2,.L53
	sw	a3,0(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L53:
	lw	a0,4(a4)
	bge	a0,a2,.L54
	sw	a3,4(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L54:
	lw	a0,8(a4)
	bge	a0,a2,.L55
	sw	a3,8(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L55:
	lw	a0,12(a4)
	bge	a0,a2,.L56
	sw	a3,12(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L56:
	lw	a0,16(a4)
	bge	a0,a2,.L57
	sw	a3,16(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L57:
	lw	a0,20(a4)
	bge	a0,a2,.L58
	sw	a3,20(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L58:
	lw	a0,24(a4)
	bge	a0,a2,.L59
	sw	a3,24(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L59:
	lw	a0,28(a4)
	bge	a0,a2,.L60
	sw	a3,28(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L60:
	lw	a0,32(a4)
	bge	a0,a2,.L61
	sw	a3,32(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L61:
	lw	a0,36(a4)
	bge	a0,a2,.L62
	sw	a3,36(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L62:
	addi	a4,a4,40
	bgtu	a7,a4,.L4
.L92:
	bleu	a1,a4,.L51
	lw	a0,0(a4)
	blt	a0,a2,.L93
.L63:
	addi	a0,a4,4
	bleu	a1,a0,.L51
	lw	a0,4(a4)
	blt	a0,a2,.L94
.L65:
	addi	a0,a4,8
	bleu	a1,a0,.L51
	lw	a0,8(a4)
	blt	a0,a2,.L95
.L66:
	addi	a0,a4,12
	bleu	a1,a0,.L51
	lw	a0,12(a4)
	blt	a0,a2,.L96
.L67:
	addi	a0,a4,16
	bleu	a1,a0,.L51
	lw	a0,16(a4)
	ble	a2,a0,.L68
	sw	a3,16(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L68:
	addi	a0,a4,20
	bleu	a1,a0,.L51
	lw	a0,20(a4)
	ble	a2,a0,.L69
	sw	a3,20(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L69:
	addi	a0,a4,24
	bleu	a1,a0,.L51
	lw	a0,24(a4)
	ble	a2,a0,.L70
	sw	a3,24(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L70:
	addi	a0,a4,28
	bleu	a1,a0,.L51
	lw	a0,28(a4)
	bgt	a2,a0,.L97
.L71:
	addi	a0,a4,32
	bleu	a1,a0,.L51
	lw	a0,32(a4)
	bgt	a2,a0,.L98
.L72:
	addi	a0,a4,36
	bleu	a1,a0,.L51
	lw	a0,36(a4)
	bgt	a2,a0,.L99
.L73:
	addi	a0,a4,40
	bleu	a1,a0,.L51
	lw	a0,40(a4)
	bge	a0,a2,.L51
	sw	a3,40(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
.L51:
	lw	a4,0(a1)
	sw	a3,0(a1)
	mv	a0,a5
	sw	a4,0(a5)
	ret
.L93:
	sw	a3,0(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L63
.L94:
	sw	a3,4(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L65
.L95:
	sw	a3,8(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L66
.L96:
	sw	a3,12(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L67
.L97:
	sw	a3,28(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L71
.L98:
	sw	a3,32(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L72
.L99:
	sw	a3,36(a4)
	sw	a0,0(a5)
	lw	a3,4(a5)
	addi	a5,a5,4
	j	.L73
_Z13shift_elementPiS_:
	lw	a4,0(a1)
	bgtu	a1,a0,.L103
	j	.L101
.L104:
	sw	a5,0(a1)
	addi	a1,a1,-4
	bgeu	a0,a1,.L101
.L103:
	lw	a5,-4(a1)
	bgt	a5,a4,.L104
.L101:
	sw	a4,0(a1)
	ret
_Z14insertion_sortPii:
	slli	a1,a1,2
	add	a1,a0,a1
	addi	a3,a0,4
	bgtu	a1,a3,.L110
	j	.L105
.L108:
	addi	a3,a3,4
	bleu	a1,a3,.L105
.L110:
	lw	a2,0(a3)
	lw	a4,-4(a3)
	ble	a4,a2,.L108
	mv	a5,a3
	j	.L107
.L113:
	lw	a4,-4(a5)
	bge	a2,a4,.L109
.L107:
	sw	a4,0(a5)
	addi	a5,a5,-4
	bltu	a0,a5,.L113
.L109:
	sw	a2,0(a5)
	addi	a3,a3,4
	bgtu	a1,a3,.L110
.L105:
	ret
