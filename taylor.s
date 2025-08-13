# Assignment 2
# Question 1
# Semester Autumn
# Group Number - 28
# Group Members - Antariksh Das and Siddhant Singh

#####Data Segment##########

.data

# Declaring input prompts

input_prompt:
    .asciiz "Enter an integer x: "
output_message:
    .asciiz "Approximation of e raised to the power x (e^x) is: "
decimal_point:
    .asciiz "."
newline:
    .asciiz "\n"

#####Code Segment###########

.text
.globl main

main:
    la $a0, input_prompt
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $s0, $v0
    # Defining registers for various values
    # $s1 for recurring sum
    # $s2 for current term
    # $t0 for current iteration number which is used for calculating factorials in the current term
    li $s1, 100
    li $s2, 100
    li $t0, 1

loop:
    # The below lines of code form the new term from the previous term
    # Multiply previous term by value of x stored in $s0
    mult $s2, $s0
    # Storing product of mutiplication into $t1 from $LO
    mflo $t1
    # Dividing by current iteration number to get the required factorial
    div $t1, $t0
    # Storing quotient of division into $s2 from $LO
    mflo $s2
    # Checking if the current term is zero to break
    beqz $s2, end
    # Adding to the recurring sum
    add $s1, $s1, $s2
    # Incrementing $t0
    addi $t0, $t0, 1
    j loop
    
end:
    # Printing output message
    la $a0, output_message
    li $v0, 4
    syscall
    # Dividing answer by 100
    li $t1, 100
    div $s1, $t1
    # Printing integral part
    mflo $a0
    li $v0, 1
    syscall
    # Printing decimal point
    la $a0, decimal_point
    li $v0, 4
    syscall
    # Printing fractional part
    mfhi $a0
    move $s3, $a0
    # If fractional part is less than 10 (for example the below code helps to print 20.05 instead of 20.5 for x is equal to 3)
    blt $a0, 10, zero_printing
    li $v0, 1
    syscall
    # Printing newline character
    la $a0, newline
    li $v0, 4
    syscall
    # Exit command
    li $v0, 10
    syscall

zero_printing:
    li $a0, 0
    li $v0, 1
    syscall
    move $a0, $s3
    li $v0, 1
    syscall
    # Printing newline character
    la $a0, newline
    li $v0, 4
    syscall
    # Exit command
    li $v0, 10
    syscall