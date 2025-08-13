# Assignment 2
# Question 2
# Semester Autumn
# Group Number - 28
# Group Members - Antariksh Das and Siddhant Singh

#####Data Segment##########

.data

first_number_prompt:
    .asciiz "Enter a non negative integer: "
second_number_prompt:
    .asciiz "Enter another non negative integer: "
error_message:
    .asciiz "The input is invalid. Please enter non negative integers."
output_message:
    .asciiz "GCD of the two given integers is: "
newline:
    .asciiz "\n"

#####Code Segment###########

.text
.globl main

main:
    # Input of first number
    la $a0, first_number_prompt
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $s0, $v0
    # Input of second number
    la $a0, second_number_prompt
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $s1, $v0
    # Checking if any of the numbers is less than zero
	bltz $s0, invalid
    bltz $s1, invalid
    # Checking if any of the numbers is 0 if one of them is zero and the other is non negative, then the GCD is the non negative number
    beqz $s0, if_s0_zero_exit
    beqz $s1, if_s1_zero_exit
    # Calling the recursive function
    move $a0, $s0
    move $a1, $s1
    jal find_gcd
    move $s2, $v0
    # Printing result
    la $a0, output_message
    li $v0, 4
    syscall
    move $a0, $s2
    li $v0, 1
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    li $v0, 10
    syscall

if_s0_zero_exit:
    # Function to handle if first number is zero (print second number)
    la $a0, output_message
    li $v0, 4
    syscall
    move $a0, $s1
    li $v0, 1
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    li $v0, 10
    syscall

if_s1_zero_exit:
    # Function to handle if second number is zero (print first number)
    la $a0, output_message
    li $v0, 4
    syscall
    move $a0, $s0
    li $v0, 1
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    li $v0, 10
    syscall

invalid:
    # Printing error message
	la $a0, error_message
	li $v0, 4
	syscall
    la $a0, newline
    li $v0, 4
    syscall
	li $v0, 10
	syscall

find_gcd:
    # Recursive function
    # Defining stack with 12 bytes
    # Return address, first number and second number are stored in stack
    sub $sp, $sp, 12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    # Check if $a1 is zero
    beqz $a1, gcd_base
    # Remainder taken from HI
    div $a0, $a1
    mfhi $t0
    # a0 loaded from stack where a1 was stored last time and remainder moved to a1
    lw $a0, 8($sp)
    move $a1, $t0
    # Recursive call
    jal find_gcd
    # Cleaning up the stack
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

gcd_base:
    # If a1 is zero, a0 is the answer and is stored in v0 and stack is cleaned up
    move $v0, $a0
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra
