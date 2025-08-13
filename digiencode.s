.data
encode_table: .byte '4','6','9','5','0','3','1','8','7','2'
input_buf: .space 50
output_buf: .space 50
test_buf: .space 50
input_prompt: .asciiz "Enter input string"
further_prompt: .asciiz "Do you wish to enter further strings?"
output_msg: .asciiz "Encoded string: "
output_success: .asciiz "Test case passed!"
output_failure: .asciiz "Test case failed!"
newline: .asciiz "\n"

.text
.globl main
main:
    li $t9,0
main_loop:
    li $t0,10
    beq		$t9, $t0, exit
    
    la $a0, input_prompt
    li $v0,4
    syscall

    la $a0,input_buf
    li $a1, 50
    li $v0,8
    syscall

    la $a0,input_buf
    la $a1,output_buf
    la $a2, encode_table
    jal encode_string
    jal print_results

    la $a0,output_buf
    la $a1,test_buf
    jal encode_string
    la $a0,input_buf
    la $a1, test_buf
    jal test_results

    la $a0, further_prompt
    li $v0,4
    syscall

    li $v0,5
    syscall
    move $t1,$v0
    li $t0, 'y'
    beq $t0,$t1,exit
    li $t0, 'Y'
    beq $t0,$t1,exit
    addi $t9, $t9, 1
    j main_loop

encode_string:
    li $t0,'9'
    lb $t1, 0($a0)
    beq $t1, $zero, exit_loop
    bgt		$t1, $t0, non_num
    li $t0, '\n'
    beq $t1, $t0, exit_loop
    li $t0,'0'
    blt		$t1, $t0, non_num
    sub $t1,$t1,$t0
    add $t2,$a2,$t1
    lb $t0, 0($t2)
    sb $t0,0($a1)
    j increment
non_num:
    sb $t1, 0($a1)
increment:
    addi $a0,$a0,1
    addi $a1,$a1,1
    j encode_string
exit_loop:
    sb $zero,0($a1)
    jr $ra
print_results:
    la $a0, output_msg
    li $v0,4
    syscall
    la $a0, output_buf
    li $v0,4
    syscall
    la $a0, newline
    li $v0,4
    syscall
    jr $ra
test_results:
    lb    $t0, 0($a0)
    lb    $t1, 0($a1)
    bne   $t0, $t1, not_eq
    beq   $t0, $zero, eq_end  
    addi  $a0, $a0, 1
    addi  $a1, $a1, 1
    j test_results
eq_end:
    la $a0, output_success
    li $v0,4
    syscall
    la $a0, newline
    li $v0,4
    syscall
    jr $ra
not_eq:
    la $a0, output_failure
    li $v0,4
    syscall
    la $a0, newline
    li $v0,4
    syscall
    jr $ra

exit:
    li $v0, 10
    syscall