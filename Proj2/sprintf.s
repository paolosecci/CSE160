#Paolo Secci
#CSE 31
#1 May 2017
#Project 2

.data
buffer:	.space	20000
format:	.asciiz "string: %s, unsigned dec: %u, hex: 0x%x, oct: 0%o, dec: %d\n"
str:	.asciiz "thirty-nine"
chrs:	.asciiz " characters:\n"
.text

main:
        addi	$sp,$sp,-32	#set aside stack space

        #sprint f
        #input: 7 args (buffer, format, str, 255, 255, 250, -255)
        #output $v0

        la      $a0, buffer     #arg0 == a0 = buffer
        la      $a1, format     #arg1 == a1 = format
        la      $a2, str        #arg2 == a2 = str

        addi	$a3,$0,255      #arg3 = 255
        sw      $a3,16($sp)     #arg4 = 255

        addi	$t0,$0,250      #arg5 = 250
        sw      $t0,20($sp)     #save arg5 to stack

        addi    $t0,$0,-255     #arg6 = -255
        sw      $t0,24($sp)     #save arg6 to stack

        sw      $ra,28($sp)     #save ra to stack
        jal     sprintf         #$v0 = sprintf(args)

        add     $a0,$v0,$0      #$a0 = $v0
        jal     putint          #putint()

        li      $v0, 4
        la     	$a0, chrs
        syscall                 #output string chrs

        li      $v0, 4
        la      $a0, buffer
        syscall                 #output string buffer

        addi	$sp,$sp,32      #reset stack
        li      $v0, 10
        syscall                 #terminate program

putint:	addi	$sp,$sp,-8      #reserve 2 words in stack
        sw      $ra,0($sp)      #save ra to stack

        remu	$t0,$a0,10      #t0 = a0 % 10
        addi	$t0,$t0,'0'     #t0 += '0'
        divu	$a0,$a0,10      #a0 /= 10

        beqz	$a0,onedig      #if(a0 != 0)
        #{
        sw      $t0,4($sp)      #save t0 to stack
        jal     putint          #putint()
        lw      $t0,4($sp)      #get updated t0 from stack
        #}

onedig:	move	$a0, $t0
        li      $v0, 11
        syscall

        lw      $ra,0($sp)      #get ra from stack
        addi	$sp,$sp, 8      #reset stack
        jr      $ra             #return

sprintf:move    $v0, $0         #set counter v0 = 0
        move    $t3, $sp        #t3 = movable sp
        addi    $t3,$t3, +8     #skip the buffer and str
        addi    $sp, $sp, -16   #reserve 4 words in stack
        sw      $ra, 0($sp)     #save ra to stack
        sw      $s1, 4($sp)
        sw      $s2, 8($sp)
        sw      $s3, 12($sp)
        sw      $a2, 0($t3)
        sw      $a3, 4($t3)
        move    $s1, $a0
        move    $s2, $a0
        move    $s3, $a1

mainf:
        lb      $t0, 0($s3)     #load next byte in string
        beqz    $t0, Endf       #if a1 == NULL, end
        beq     $t0,'%',finder  #if %,          finder
        sb      $t0, 0($s1)     #save byte
        addi    $s1, $s1, 1     #s1++
        addi    $s3, $s3, 1     #s3++
        addi    $v0, $v0, 1     #counter v0++
        j       mainf           #loop until a1 == NULL

Endf:
        sub     $v0, $s1,$s2    #decrement v0
        lw      $ra, 0($sp)
        lw      $s1, 4($sp)
        lw      $s2, 8($sp)
        lw      $s3, 12($sp)
        addi    $sp, $sp, 4     #reset stack
        jr      $ra             #return

finder:
        addi    $s3, $s3, 1     #find a0 on stack
        lb      $t0, 0($s3)     #load next byte in string
        lw      $a0, 0($t3)
        addi    $t3, $t3, 4     #increment temporary stack pointer
        addi    $s3, $s3, 1     #s3++

        beq     $t0, 'd', decsign   #signed decimal
        beq     $t0, 'u', decunsign #unsigned decimal
        beq     $t0, 'x', hexunsign #unsigned hex
        beq     $t0, 'o', octunsign #unsigned octal
        beq     $t0, 's', word      #string and chars
        j       Endf

decsign:
        slt     $t0, $a0, $0
        beq     $t0, $0, pos        #if a0 > 0, pos

        li      $t0, '-'            #get negative sign
        sb      $t0, 0($s1)         #save temp on buffer
        addi    $v0, $v0, 1         #count++
        addi    $s1, $s1, 1         #buffer++
        li      $t5, -1
        mult    $t5, $a0
        mflo    $a0

pos:
        jal     putintsigdec
        j       mainf

putintsigdec:
        addi	$sp, $sp, -8        #reserve 2 words in stack
        sw      $ra, 0($sp)         #save ra
        remu	$t0, $a0, 10        #t0 = a0 % 10
        addi	$t0, $t0, '0'
        divu	$a0, $a0, 10        #a0 = a0 / 10

        beqz	$a0, onedigsigdec   #if a0 != 0, onedigsigdec
        sw      $t0, 4($sp)         #save t0 to stack
        jal     putintsigdec
        lw      $t0, 4($sp)         #get updated t0 from stack

onedigsigdec:
        sb      $t0, 0($s1)     #temp on the buffer
        addi    $v0, $v0, 1     #count++
        addi    $s1, $s1, 1     #buffer++

        lw      $ra,0($sp)      #get ra from stack
        addi	$sp,$sp, 8      #reset stack
        jr      $ra             #return

decunsign:
        jal     putintundec
        j       mainf

putintundec:
        addi	$sp,$sp,-8      #reserve two words in stack
        sw      $ra,0($sp)      #save ra to stack
        remu	$t0,$a0,10      #t0 = a0 % 10
        addi	$t0,$t0,'0'
        divu	$a0,$a0,10      #a0 = a0 / 10

        beqz	$a0,onedigundec	#if a0 != 0
        sw      $t0,4($sp)      #save t0 to stack
        jal     putintundec
        lw      $t0,4($sp)      #reset stack

onedigundec:
        sb      $t0, 0($s1)     #temp on the buffer
        addi    $v0, $v0, 1     #count++
        addi    $s1, $s1, 1     #buffer++

        lw      $ra,0($sp)      #get ra from stack
        addi	$sp,$sp, 8      #reset stack
        jr      $ra             #return

hexunsign:
        jal     putintunhex
        j       mainf

putintunhex:
        addi	$sp,$sp,-8      #reserve two words in stack
        sw      $ra,0($sp)      #save ra to stack
        remu	$t0,$a0,16      #t0 = a0 / 16
        li      $t7, 9
        slt     $t1,$t7,$t0
        beq     $t1,$0, intchar

        li      $t7, 10
        beq     $t0,$t7,a
        li      $t7, 11
        beq     $t0,$t7,b
        li      $t7, 12
        beq     $t0,$t7,c
        li      $t7, 13
        beq     $t0,$t7,d
        li      $t7, 14
        beq     $t0,$t7,e
        li      $t7, 15
        beq     $t0,$t7,f

a:
        li $t0, 'a'
        j hexchar

b:
        li $t0, 'b'
        j hexchar

c:
        li $t0, 'c'
        j hexchar

d:
        li $t0, 'd'
        j hexchar

e:
        li $t0, 'e'
        j hexchar

f:
        li $t0, 'f'
        j hexchar

intchar:
        addi	$t0, $t0, '0'	#t0 set to digit char

hexchar:
        divu	$a0, $a0, 16	#a0 = a0 / 16
        beqz	$a0, onedigunhex#if a0 != 0, onedigunhex
        sw      $t0,4($sp)      #save t0 to stack
        jal     putintunhex
        lw      $t0,4($sp)      #reset stack

onedigunhex:
        sb      $t0, 0($s1)
        addi    $v0, $v0, 1     #v0++
        addi    $s1, $s1, 1     #s1++

        lw      $ra, 0($sp)     #get ra from stack
        addi	$sp, $sp, 8     #reset stack
        jr      $ra             #return

octunsign:
        jal     putintunoct
        j       mainf

putintunoct:
        addi	$sp, $sp, -8	#reserve 2 words in stack
        sw      $ra, 0($sp)     #save ra to stack
        remu	$t0, $a0, 8     #t0 = a0 % 8
        addi	$t0, $t0, '0'
        divu	$a0, $a0, 8     #a0 = a0 / 8
        beqz	$a0,onedigunoct #if a0 != 0, onedigunoct
        sw      $t0, 4($sp)     #save t0 to stack
        jal     putintunoct
        lw      $t0, 4($sp)     #get updated t0 from stack

onedigunoct:
        sb      $t0, 0($s1)
        addi    $v0, $v0, 1
        addi    $s1, $s1, 1

        lw      $ra, 0($sp)     #get ra from stack
        addi	$sp, $sp, 8     #reset stack
        jr      $ra             #return

word:
        lb      $t7, 0($a0)     #load next byte in string
        beqz    $t7, mainf      #if byte = NULL, mainf

        #else
        sb      $t7, 0($s1)     #store byte
        addi    $s1, $s1, 1     #s1++
        addi    $v0, $v0, 1     #v0++
        addi    $a0, $a0, 1     #a0++
        j word
