    .data
n:  .word 13

    .text
main:
    addi    $s0, $zero, 1
    addi    $s1, $zero, 2

sum:
    add	$t0, $zero, $s0
    add	$t1, $zero, $s1
    add	$t2, $t0, $t1
    add	$t3, $t1, $t2
    add	$t4, $t2, $t3
    add	$t5, $t3, $t4
    add	$t6, $t4, $t5
    add	$t7, $t5, $t6

finish:
    addi    $a0, $t7, 0
    li      $v0, 1
    syscall
    li      $v0, 10
    syscall
