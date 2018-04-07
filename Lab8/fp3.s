.data

num1:	.word 0x4b000000
num2:	.float 1.0
result:	.word 0
string: .asciiz "\n"

.text
main:
la $t0, num1
lwc1 $f2, 0($t0)
lwc1 $f4, 4($t0)

li $v0, 2
mov.s $f12, $f2
syscall

li $v0, 4
la $a0, string
syscall

li $v0, 2
mov.s $f12, $f4
syscall

li $v0, 4
la $a0, string
syscall
li $v0, 4
la $a0, string
syscall

add.s $f12, $f2, $f4
add.s $f12, $f12, $f4

swc1 $f12, 8($t0)
lw $s0, 8($t0)

li $v0, 2
syscall
li $v0, 4
la $a0, string
syscall

add.s $f12, $f2, $f2
add.s $f12, $f12, $f4

swc1 $f12, 8($t0)
lw $s0, 8($t0)

li $v0, 2
syscall
li $v0, 4
la $a0, string
syscall

add.s $f12, $f4, $f2
add.s $f12, $f12, $f4

swc1 $f12, 8($t0)
lw $s0, 8($t0)

li $v0, 2
syscall
li $v0, 4
la $a0, string
syscall
