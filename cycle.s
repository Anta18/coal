# Assignment 3
# Question 1
# Semester Autumn
# Group Number - 28
# Group Members - Antariksh Das (23CS10086) and Siddhant Singh (23CS10085)

#####Data Segment##########

.data
permutation_prompt_1:
    .asciiz "Enter number of cycles in first permutation: "
prompt_length:
    .asciiz "\nEnter length of cycle: "
prompt_cycle_letters:
    .asciiz "\nEnter cycle (all letters) (a to f) without spaces: "
permutation_prompt_2:
    .asciiz "\nEnter number of cycles in second permutation: "
output_message:
    .asciiz "\nProduct permutation is as follows: "
space:
    .asciiz " "
newline:
    .asciiz "\n"
first_array:
    .word 'a','b','c','d','e','f'
second_array:
    .word 'a','b','c','d','e','f'
array_result:
    .space 24

#####Code Segment###########

.text
.globl main
main:
    la $a0, permutation_prompt_1
    li $v0, 4; syscall
    li $v0, 5; syscall
    move $s0, $v0
    li $s1, 0

# Taking input of first permutation
perm1_loop:
    beq $s1, $s0, after_p1
    la $a0, prompt_length
    li $v0, 4; syscall
    li $v0, 5; syscall
    move $t0, $v0

    la $a0, prompt_cycle_letters
    li $v0, 4; syscall
    li $v0, 12; syscall
    move $t1, $v0
    subu $t2, $t1, 'a'
    move $s4, $t1
    move $s5, $t2

    li $t3, 1

perm1_read_loop:
    beq $t3, $t0, perm1_close
    li $v0, 12; syscall
    move $t4, $v0
    subu $t5, $t4, 'a'

    sll $t6, $t2, 2
    la $t7, first_array
    add $t7, $t7, $t6
    sw $t4, 0($t7)

    move $t2, $t5
    addi $t3, $t3, 1
    j perm1_read_loop

perm1_close:
    sll $t6, $t2, 2
    la $t7, first_array
    add $t7, $t7, $t6
    sw $s4, 0($t7)

    addi $s1, $s1, 1
    j perm1_loop

after_p1:
    la $a0, permutation_prompt_2
    li $v0, 4; syscall
    li $v0, 5; syscall
    move $s2, $v0
    li $s3, 0

# Taking input of second permutation
perm2_loop:
    beq $s3, $s2, compute

    la $a0, prompt_length
    li $v0, 4; syscall
    li $v0, 5; syscall
    move $t0, $v0

    la $a0, prompt_cycle_letters
    li $v0, 4; syscall
    li $v0, 12; syscall
    move $t1, $v0
    subu $t2, $t1, 'a'
    move $s4, $t1
    move $s5, $t2

    li $t3, 1

perm2_read_loop:
    beq $t3, $t0, perm2_close
    li $v0, 12; syscall
    move $t4, $v0
    subu $t5, $t4, 'a'

    sll $t6, $t2, 2
    la $t7, second_array
    add $t7, $t7, $t6
    sw $t4, 0($t7)

    move $t2, $t5
    addi $t3, $t3, 1
    j perm2_read_loop

perm2_close:
    sll $t6, $t2, 2
    la $t7, second_array
    add $t7, $t7, $t6
    sw $s4, 0($t7)

    addi $s3, $s3, 1
    j perm2_loop

# Computation step
compute:
    li $t0, 0

comp_loop:
    bgt $t0, 5,  print

    # f = first_array[t0]
    sll $t6, $t0, 2
    la $t7, first_array
    add $t7, $t7, $t6
    lw $t1, 0($t7)
    subu $t2, $t1, 'a'

    # g(f) = second_array[t2]
    sll $t6, $t2, 2
    la $t7, second_array
    add $t7, $t7, $t6
    lw $t4, 0($t7)

    # store result[t0] = g(f)
    sll $t6, $t0, 2
    la $t7, array_result
    add $t7, $t7, $t6
    sw $t4, 0($t7)

    addi $t0, $t0, 1
    j comp_loop

# Printing the final permutation
print:
    la $a0, output_message
    li $v0, 4
    syscall

    li $t0, 0

print_loop:
    bgt $t0, 5,  done
    sll $t6, $t0, 2
    la $t7, array_result
    add $t7, $t7, $t6
    lw $a0, 0($t7)
    li $v0, 11
    syscall
    la $a0, space
    li $v0, 4
    syscall

    addi $t0, $t0, 1
    j print_loop

done:
    la $a0, newline
    li $v0, 4
    syscall
    li $v0, 10
    syscall
