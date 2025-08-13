.data
input_prompt:
    .asciiz "Enter number: "
output_message:
    .asciiz "The sum is: "

number:
    .space 11

newline:
    .asciiz "\n"

.text
.globl main
main:
    la $a0, input_prompt
    li $v0,4
    syscall

    la $a0, number
    li $a1, 11
    li $v0,8
    syscall

    la $t0, number
    li $t1,0

loop_digits:
    lb $t2,($t0)
    and $t2, $t2, 0x0F	
    beq $t2,0xA,exit_loop 	
    beqz $t2,exit_loop
    add $t1,$t1,$t2
    addi $t0,$t0,1
    b loop_digits

exit_loop:
    la $a0, newline
    li $v0,4
    syscall  

    la $a0, output_message
    li $v0,4
    syscall    

    move $a0,$t1
    li $v0,1
    syscall

    la $a0, newline
    li $v0,4
    syscall  

    li $v0,10
    syscall

    