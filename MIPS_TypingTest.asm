.eqv KEY_CODE 0xFFFF0004 		# Keyboard
.eqv KEY_READY 0xFFFF0000 		
.eqv DISPLAY_CODE 0xFFFF000C 		# Display
.eqv COUNTER 0xFFFF0013 		# Time Counter
.eqv MASK_CAUSE_COUNTER 0x00000400 	# Bit 10: Counter interrupt
.eqv MASK_CAUSE_KEYBOARD 0x00000100 	# Bit 8: Keyboard interrupt
.eqv SEVENSEG_LEFT 0xFFFF0011 		# 7-seg left
.eqv SEVENSEG_RIGHT 0xFFFF0010		# 7-seg right
.data 
string: .asciiz "Nguyen Gia Tung Duong"
thongbao: .asciiz "Da hoan thanh.\nThoi gian (ms): "
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAIN Procedure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.text
main:
		la	$a2, string
		li 	$s1, KEY_CODE
		li 	$s2, DISPLAY_CODE
#---------------------------------------------------------
# Enable interrupts you expect
#---------------------------------------------------------
# Enable the interrupt of Keyboard
		li 	$s0, KEY_READY
		li 	$t0, 0x2 		
		sb 	$t0, 0($s0)
# Enable the interrupt of TimeCounter of Digital Lab Sim
 		li 	$t1, COUNTER 
 		sb 	$t1, 0($t1)
#---------------------------------------------------------
# Loop and print result
#---------------------------------------------------------
Loop: 		nop
 		nop
 		nop 
sleep: 		addi 	$v0,$zero,32 				# Set Time Counter interval
		li 	$a0,100 				# sleep 100 ms
		syscall
		nop 						
 		j 	Loop
print:		mul	$s7, $s7, 100
		li 	$v0, 56 
 		la 	$a0, thongbao
 		la 	$a1, 0($s7)
 		syscall 
terminate:	li 	$v0, 10
 		syscall
end_main:
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENERAL INTERRUPT SERVED ROUTINE for all interrupts
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ktext 0x80000180
IntSR: 
#--------------------------------------------------------
# Temporary disable interrupt
#--------------------------------------------------------
dis_int:	li 	$t1, COUNTER 				# BUG: must disable with Time Counter
 		sb 	$zero, 0($t1)
# no need to disable keyboard matrix interrupt
#--------------------------------------------------------
# Processing
#--------------------------------------------------------
get_cause:	mfc0 	$k0, $13   				# $t1 = Coproc0.cause
		andi 	$k1, $k0, 0x00007c  			# Mask all but the exception code (bits 2 - 6) to zero
		srl  	$k1, $k1, 2				# Shift two bits to the right to get the exception code
		bnez 	$k1, resume_from_exception		# The exception code is zero for an interrupt and none zero for all exceptions
IsCount:	andi 	$k1, $k0, MASK_CAUSE_COUNTER		# if Cause value confirm Counter..
 		beq  	$k1, MASK_CAUSE_COUNTER, Counter_Intr 
IsKeyMa:	andi 	$k1, $k0, MASK_CAUSE_KEYBOARD		# if Cause value confirm Key..
    		beq  	$k1, MASK_CAUSE_KEYBOARD, Keyboard_Intr 
others:		j 	end_process 				# other cases
Keyboard_Intr: 	lw 	$t0, 0($s1) 				# Processing Keyboard Interrupt
		sw 	$t0, 0($s2)				# Print to Display
 		nop
 		
 		add 	$t2, $t3, $a2 				# $t2 = $t1 + $a1 = i + string[0]
 								#     = address of string[i]
		lb 	$v0, 0($t2) 				# $v0 = string[i]
		add	$t3, $t3, 1				# i++
		bne	$v0, $t0, display			# if char = string[i], digit++
		
correct:	bne	$s3, 9, add_digit			# if digit < 9, digit++
add_ten:	addi	$s3, $s3, -9				# else digit -= 9
		addi	$s4, $s4, 1				# 	ten++
		j	display		
add_digit:	addi	$s3, $s3, 1	

display:
get_digit:	beq	$s3, 0, zero
		beq	$s3, 1, one
		beq	$s3, 2, two
		beq	$s3, 3, three
		beq	$s3, 4, four
		beq	$s3, 5, five
		beq	$s3, 6, six
		beq	$s3, 7, seven
		beq	$s3, 8, eight
		beq	$s3, 9, nine

get_ten:	beq	$s4, 0, zero
		beq	$s4, 1, one
		beq	$s4, 2, two
		beq	$s4, 3, three
		beq	$s4, 4, four
		beq	$s4, 5, five
		beq	$s4, 6, six
		beq	$s4, 7, seven
		beq	$s4, 8, eight
		beq	$s4, 9, nine
		
zero:		addi	$s5, $s5, 0x3F				# assign value
		bnez	$s6, show_ten				# if $s6 = 0, show digit
		j	show_digit				# else show ten
one:		addi	$s5, $s5, 0x06
		bnez	$s6, show_ten
		j	show_digit
two:		addi	$s5, $s5, 0x5B
		bnez	$s6, show_ten
		j	show_digit
three:		addi	$s5, $s5, 0x4F
		bnez	$s6, show_ten
		j	show_digit
four:		addi	$s5, $s5, 0x66
		bnez	$s6, show_ten
		j	show_digit
five:		addi	$s5, $s5, 0x6D
		bnez	$s6, show_ten
		j	show_digit
six:		addi	$s5, $s5, 0x7D
		bnez	$s6, show_ten
		j	show_digit
seven:		addi	$s5, $s5, 0x07
		bnez	$s6, show_ten
		j	show_digit
eight:		addi	$s5, $s5, 0x7F
		bnez	$s6, show_ten
		j	show_digit
nine:		addi	$s5, $s5, 0x6F
		bnez	$s6, show_ten

show_digit:	jal 	SHOW_7SEG_RIGHT
		nop
		j	get_ten
show_ten:	j 	SHOW_7SEG_LEFT

SHOW_7SEG_RIGHT:li 	$t2, SEVENSEG_RIGHT
		sb 	$s5, 0($t2)				# assign value 
 		nop
 		and 	$s5, $s5, $zero				# $s5 =0
 		addi	$s6, $s6, 1				# $s6=1
 		jr 	$ra
		nop

SHOW_7SEG_LEFT:	li 	$t2, SEVENSEG_LEFT
		sb 	$s5, 0($t2)				# assign value 
 		nop
 		and 	$s5, $s5, $zero				# $s5 =0
 		and 	$s6, $s6, $zero				# $s6 =0

next:
		beq	$t3, 21, print				# if i=n, print
 		j 	end_process 
		
Counter_Intr: 	addi 	$s7,$s7,1				# time++
		j 	end_process 				
end_process: 
 		mtc0 	$zero, $13 				# Must clear cause reg 
en_int:  
#--------------------------------------------------------
# Re-enable interrupt
#--------------------------------------------------------
 		li 	$t1, COUNTER
 		sb 	$t1, 0($t1) 
		j	return					# Return from interrupt
#--------------------------------------------------------
# Evaluate the return address of main routine
# epc <= epc + 4
#--------------------------------------------------------
resume_from_exception:
		li 	$t1, COUNTER
 		sb 	$t1, 0($t1) 
next_pc:	mfc0 	$at, $14 				# $at <= Coproc0.$14 = Coproc0.epc
 		addi 	$at, $at, 4 				# $at = $at + 4 (next instruction)
 		mtc0 	$at, $14 				# Coproc0.$14 = Coproc0.epc <= $at
return:		eret 						
