.data
input_prompt: .asciiz "Enter the number: "
output_message: .asciiz "F(n) = "

.text
.globl main
main:
    la $a0,input_prompt
    li $v0,4
    syscall

    li $v0,5
    syscall
    move $a0,$v0

    li $t0,1
    li $t1,1
    li $t2,3

fib:
    li $t3, 1
    beq $a0,$t3, exit_loop
    li $t3, 2
    beq $a0,$t3, exit_loop
fib_loop:
    add $t3,$t0,$t1
    move $t0,$t1
    move $t1,$t3
    beq $t2,$a0,exit_loop
    addi $t2,$t2,1
    j fib_loop
exit_loop:
    la $a0,output_message
    li $v0,4
    syscall
    move $a0,$t1
    li $v0,1
    syscall
    li $v0,10
    syscall