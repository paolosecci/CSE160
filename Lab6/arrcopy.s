	.file	1 "arrcopy.c"
	.globl	source
	.data
	.align	2
source:
	.word	3
	.word	1
	.word	4
	.word	1
	.word	5
	.word	9
	.word	0
	.rdata
	.align	2
$LC0:
	.ascii	"%d values copied\n\000"
	.text
	.align	2
	.globl	main
	.ent	main
main:
	.frame	$sp,24,$31		# vars= 0, regs= 1/0, args= 16, extra= 0
	.mask	0x80000000,-8
	.fmask	0x00000000,0
	subu	$sp,$sp,24
	sw	$31,16($sp)
	jal	__main
	la	$9,source
	lw	$2,0($9)
	move	$8,$0
	beq	$2,$0,$L8
	move	$7,$0
	la	$10,dest
$L6:
	addu	$8,$8,1
	sll	$3,$8,2
	addu	$5,$7,$9
	addu	$2,$3,$9
	addu	$6,$7,$10
	lw	$4,0($2)
	move	$7,$3
	lw	$3,0($5)
	#nop
	sw	$3,0($6)
	bne	$4,$0,$L6
$L8:
	la	$4,$LC0
	move	$5,$8
	jal	printf
	lw	$31,16($sp)
	move	$2,$0
	addu	$sp,$sp,24
	j	$31
