# Assignment 1
# Question 1
# Semester Autumn
# Group Number - 28
# Group Members - Antariksh Das and Siddhant Singh

#####Data Segment##########
.data
# Declaring input prompts
first_number_prompt:
	.asciiz "Enter the first positive integer: "
second_number_prompt:
	.asciiz "Enter the second positive integer: "
error_invalid_input:
	.asciiz "Invalid input. Please enter positive integers.\n"
output_message:
	.asciiz "GCD of the two given integers is: "
newline:
	.asciiz "\n"

#####Code Segment###########
.text
.globl main
main:
    la $a0, first_number_prompt
    li $v0, 4
    syscall
    
	# Taking input of first number
	li $v0, 5
    syscall
    move $t0, $v0

    la $a0, second_number_prompt
    li $v0, 4
    syscall

	# Taking input of second number
    li $v0, 5
    syscall
    move $t1, $v0

	# Checking if both numbers are positive
	bgtz $t0, check_t1
    j invalid

invalid:
	la $a0, error_invalid_input
	li $v0, 4
	syscall
	li $v0, 10
	syscall

check_t1:
    bgtz $t1, gcd_loop
    j invalid

# Loop to calculate GCD
gcd_loop:
	# Checking if t1 is equal to zero
    beqz $t1, gcd_completed
	# Subtracting the smaller number from larger number
    ble $t0, $t1, subtract_b
    sub $t0, $t0, $t1
    j gcd_loop

subtract_b:
    sub $t1, $t1, $t0
    j gcd_loop

# Printing output
gcd_completed:
    la $a0, output_message
    li $v0, 4
    syscall

    move $a0, $t0
    li $v0, 1
    syscall

    la $a0, newline
    li $v0, 4
    syscall

    li $v0, 10
    syscall