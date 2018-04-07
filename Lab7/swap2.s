	.text
main:
	la	$a0,n1	#$a0 is equal to n1=14
	la	$a1,n2	#$a1 is equal to n2=27
	jal	swap
	li	$v0,1	# print n1 and n2; should be 27 and 14
	lw	$a0,n1
	syscall
	li	$v0,11
	li	$a0,' '
	syscall
	li	$v0,1
	lw	$a0,n2
	syscall
	li	$v0,11
	li	$a0,'\n'
	syscall
	li	$v0,10	# exit
	syscall

swap:	addi $t0,$sp,-8	#make space for stack
	sw   $t0,0($sp)	#save the address the pointers point to 
	addi $sp,$sp,4	#de-allocate mem for stack
	addi $sp,$sp,-4	#allocate mem for the stack and functions
	lw   $t0,0($a0)	#$t0=14
	lw   $t3,0($sp) #find what the temp pointer points to 
	sw   $t0,0($t3) #save the a0 to the address the pointer points to
	lw   $t1,0($a1) #load $a1 to $t1
	sw   $t1,0($a0) #save #t1 to $a0
	lw   $t2,0($t3)	# dereference from the address temp points to
	sw   $t2,0($a1)	#save $t2 into $a1
	addiu $sp,$sp,4 #clear the space
	jr $ra

	.data
n1:	.word	14
n2:	.word	27
