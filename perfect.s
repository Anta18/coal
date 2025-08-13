# Assignment 1
# Question 2
# Semester Autumn
# Group Number - 28
# Group Members - Antariksh Das and Siddhant Singh

#####Data Segment##########
.data
# Declaring message prompts
number_prompt:
	.asciiz "Enter a positive integer: "
error_invalid_input:
	.asciiz "Invalid input. Please enter a positive integer.\n"
output_message_true:
	.asciiz "Entered number is a perfect number."
output_message_false:
	.asciiz "Entered number is not a perfect number."
newline:
	.asciiz "\n"

#####Code Segment###########
.text
.globl main
main:
    la $a0, number_prompt
    li $v0, 4
    syscall
    
	# Taking number as input
	li $v0, 5
    syscall
    move $t0, $v0

	# Checking if number is positive
	blez $t0, invalid

	# Jumping to isPerfect function
	move $a0, $t0
	jal isPerfect

	# Using return value to print corresponding message
	beqz $v0, printFalse
	bnez $v0, printTrue

printFalse:
	la $a0, output_message_false
	li $v0, 4
	syscall

	la $a0, newline
    li $v0, 4
    syscall

	j exit

printTrue:
	la $a0, output_message_true
	li $v0, 4
	syscall
	
	la $a0, newline
    li $v0, 4
    syscall
	
	j exit

exit:
	li $v0, 10
	syscall

invalid:
	la $a0, error_invalid_input
    li $v0, 4
    syscall

.globl isPerfect

# isPerfect function
isPerfect:
	addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)

	move $s0, $a0
	# t1 refers to numbers that are incremented and checked if they are factors of the given number
	# t2 refers to sum of divisors
    li   $t1, 1
    li   $t2, 0

# Loop to find divisors
findDivisors:
	bge $t1, $s0, endOfLoop
	# Checking if remainder ($t3) of number ($s0) and ($t1) is zero
	rem $t3, $s0, $t1
	bnez  $t3, skipAdd
	# Adding the value of divisor to sum
	addu $t2, $t2, $t1

# Skipping addition if remainder is not zero
skipAdd:
	addi $t1, $t1, 1
	j findDivisors

# Setting return value ($v0) as 0 if not perfect number and 1 if perfect number
endOfLoop:
	li   $v0, 0
    beq  $t2, $s0, makeV0True
    j completed

makeV0True:
	li $v0, 1

completed:
	lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra