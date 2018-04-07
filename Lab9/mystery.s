Paolo Secci
Lab9

	.text

main:
	li $a0, 0
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall
	
	li $a0, 1
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall
	
	li $a0, 196
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall
	
	li $a0, -1
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall
	
	li $a0, -452
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall
	
	li $a0, 2
	jal mystery
	move $a0, $v0
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall

	li $a0, 3
	jal mystery
	move $a0, $v0
	jal putDec
	li $a0, '\n'
	li $v0, 11
	syscall

	li 	$v0, 10		# terminate program
	syscall

putDec: 
    slt 	$t6, $0, $a0	#if a0 is positive, then $t6 == 1
    bne 	$t6, $0, call	#if t6 != 0 then skip "negative: "


    negative:
    beq	$a0, $0, call
    sub	$t5, $0, $a0
    li $a0, '-'
    li $v0, 11
    syscall
    move	$a0, $t5

    call:
    li 	$t0, 10             #set divisor to 10
    li 	$t1, 0              #counter starts at 0

    loop:
    div 	$a0, $t0        #divide a0 by t0
    mfhi	$t2             #move hi(remainder) into t2
    add 	$sp, $sp, -4    #allocate space in stack
    sw      $t2, 0($sp)     #save the remainder to the stack through pointer
    addi 	$t1, $t1, 1     #increment counter
    mflo 	$a0             #move lo(quotient) into $a0
    bne 	$a0, $0, loop	#if a0 != 0, loop

    print:
    lw      $t3, 0($sp)     #get remainder from stack, load into t3
    add     $sp, $sp, 4     #reallocate space in stack
    li      $a0, '0'		#load the ascii '0' into $a0
    add 	$a0, $a0, $t3   #add (ascii '0' -aka- NULL) to t3
    li      $v0, 11
    syscall
    addi	$t1, $t1, -1
    bne 	$t1, $0, print  #loop until t1 = 0

    jr      $ra             #returnv

mystery: bne $0, $a0, recur #
 	li $v0, 0               #
 	jr $ra                  #
recur: sub $sp, $sp, 8      #
 	sw $ra, 4($sp)          #
 	sub $a0, $a0, 1         #
 	jal mystery             #
 	sw $v0, 0($sp)          #
 	jal mystery             #
 	lw $t0, 0($sp)          #
 	addu $v0, $v0, $t0      #
 	addu $v0, $v0, 1        #
 	add $a0, $a0, 1         #
 	lw $ra, 4($sp)          #
 	add $sp, $sp, 8         #
 	jr $ra                  #
