# main.asm

.data
file:		.asciiz		"grid.txt"		# file to be read 
lwidth:		.word		80			# Width of each line
.globl grid
grid:		.space		4000			# Space for the grid (80x50)
buffer:		.space		4098			# stores data read
gridSize:	.word		4000			# size of grid
bufferSize:	.word		4098			# size of buffer
newLine:	.asciiz		"\n"
border:		.asciiz		"-"
HUD:		.asciiz		"\nStuff will go here when I know what to put here!"

.text
	j	main

#
# globl void readgrid:
# Reads in a grid pattern from a file.
#
readgrid:
  # save s registers to stack
	addi	$sp, $sp, -16		# Move stack pointer
	sw	$s0, 12($sp)		# Save $s0 to the stack
	sw	$s1, 8($sp)		# Save $s1 to the stack
	sw	$s2, 4($sp)		# Save $s2 to the stack
	sw	$s6, 0($sp)		# Save $s6 to the stack
  # open file
	li   	$v0, 13       		# open file syscall
	la   	$a0, file      		# board file name
	li   	$a1, 0        		# flags
	li   	$a2, 0		  	# open for reading
	syscall               		# open the file
	move 	$s6, $v0      		# save the file descriptor 

  # read from file
	li   	$v0, 14      	 	# read from file syscall
	move 	$a0, $s6      		# file descriptor 
	la   	$a1, buffer   		# address of buffer to store read data
	lw   	$a2, bufferSize		# max buffer length
	syscall            		# read from file
	
  # sifting through buffer
	move	$s0, $zero		# index of buffer
	lw	$s1, bufferSize		# $s1 stores size of buffer
	
	lw	$a1, gridSize		# #a1 size of array
	move	$a2, $zero		# index of grid (i)
	
  # initialize grid with values from text file
  r_loop:  
	bge 	$s0, $s1, r_exit	# if $s0 >= bufferSize, exit loop
	bge 	$a2, $a1, r_exit	# if $a2 >= grid size, exit loop
	
	la	$a0, grid		# load address of grid into $a0
	lbu 	$s2, buffer($s0)	# load byte from buffer into $s2

  r_if1:
	bne	$s2, '@', r_if2		# if cell is not alive, go to second if statement
	
	li	$t0, '1'		# $t0 = alive cell
	sb	$t0, grid($a2)		# store alive cell in grid[i]
	addiu	$a2, $a2, 1		# i++
	
  r_if2:	
	bne	$s2, ' ', r_inc		# if cell not dead, go to inc

	li	$t0, '0'		# $t0 = dead cell
	sb	$t0, grid($a2)		# store dead cell in grid[i]
	addiu	$a2, $a2, 1		# i++

  r_inc:
	addiu 	$s0, $s0, 1		# go to next byte in buffer
	j	r_loop			# iterate through loop again

  r_exit:	
	lw	$s0, 12($sp)		# Save $s0 to the stack
	lw	$s1, 8($sp)		# Save $s1 to the stack
	lw	$s2, 4($sp)		# Save $s2 to the stack
	lw	$s6, 0($sp)		# Save $s6 to the stack
	addi	$sp, $sp, 16		# Move stack pointer
	jr	$ra

#
# globl void printgrid:
# Prints the current contents of the grid.
#
printgrid:	
	lw 	$t2, lwidth 		# load the length of a row into $t2
	lw 	$t3, gridSize 		# load the total size of the grid into $t3
	li	$t0, 0			# initialize $t0, which counts current position in the row
	li	$t1, 0 			# initialize $t1, which counts current position in the grid
	j	g_loop			# start the loop
	
 g_loop:
	beq  	$t1, $t3, g_end		# exit if the current position is the last position in the grid
	beq  	$t0, $t2, g_newRow	# move to the next line if the current position is the last position in the row
	add 	$t4, $s6, $t1 		# add base address of array to $t1 to calculate the address of array[$t4]
	lb 	$t4, 0($t4) 		# $t4 = array[$t4]
	move 	$a0, $t4		# move the value to $a0
	li	$v0, 11			# syscall for print character
	syscall				# print the grid value
	addi 	$t0, $t0, 1		# increment the current position in the row
	addi 	$t1, $t1, 1		# increment the current position in the grid
	j 	g_loop			# jump back to the beginning of the loop
 g_newRow:
	li	$v0, 4			# syscall for print string
	la	$a0, newLine		# load a "\n" into $a0 to move to the next line
	syscall				# move to the next line
	li	$t0, 0			# reset the value of the row
	j 	g_loop			# jump back to the beginning of the loop
 g_end:
	li	$v0, 4			# syscall for print string
	la	$a0, newLine		# load a "\n" into $a0 to move to the next line
	syscall				# move to the next line
	li	$t0, 0			# $t0 will now record the current position in the line
	li	$t1, 80			# $t1 will now represent the last position in the line
g_printBorder:
	addi 	$t0, $t0, 1		# increment i
	li	$v0, 4			# syscall for print string
	la	$a0, border		# stick a "-" symbol in $a0
	syscall				# draw a single element of the border
	bne  	$t0, $t1, g_printBorder	# if the end of the line wasn't reached go back to the start of the loop
	li	$v0, 4			# syscall for print string
	la	$a0, HUD		#load the HUD into $a0
	syscall				# draw the HUD
	
	jr	$ra			# Return


#
# globl bool testdir:
# Tests a direction based on argument. For now, is split into several separate
# subroutines, each for one direction.
#
testup:
	move 	$t0, $s1	#put grid location into $t0. Shouldn't it be
				#received in $a0?
	lw	$t1, lwidth		#acquire line width

	slt	$t2, $t0, $t1		#check if location < line width
	beq	$t2, '0', checkUp	#branch to check above position
	li	$v0, 0			#up is not alive
	j	upExit			#jump to end of subroutine

checkUp:
	sub	$t0, $t0, $t1		#place $t0 above its original grid pos.
	lb	$v0, 0($t0)		#load life value into $v0
	j	upExit			#jump to end of subroutine

upExit:
	jr	$ra			#exit testup

testdown:
	move	$t0, $s1		#put grid location in $t0
	lw	$t1, lwidth		#stores line width in $t1
	lw	$t2, gridSize		#stores grid size in $t2

	sub	$t3, $t2, $t1		#subtract and see if position is less
	slt	$t4, $t0, $t3		#than the grid size minus line width
	bne	$t4, $zero, checkDown	#branch if position is not in last line
					#of grid
	li	$v0, 0			#down is not alive
	j	downExit		#jump to exit of subroutine

checkDown:
	add	$t0, $t0, $t1		#$t0 = position below current position
	lb	$v0, 0($t0)		#store life value in return register $v0
	j	downExit		#jump to exit of down subroutine

downExit:
	jr	$ra			#return to caller function

testleft:
	move	$t0, $s1		#store current position in $t0
	lw	$t1, lwidth		#store line width in $t1
	
	div	$t0, $t1		#modulus of current position to check if
	mfhi	$t3			#left is in grid
	bne	$t3, '0', checkLeft		
	li	$v0, 0			#left does not exist/is not alive
	j	leftExit

checkLeft:
	addi	$t0, $t0, -1		#$t0 = position left of current position
	lb	$v0, 0($t0)		#load life value into return register
	j	leftExit

leftExit:
	jr	$ra			#exit left subroutine

testright:
	move    $t0, $s1                #store current position in $t0
        lw      $t1, lwidth             #store line width in $t1

        div     $t0, $t1                #modulus of current position to check if
        mfhi    $t3                     #right is in grid
        bne     $t3, 79, checkLeft           
        li      $v0, 0                  #right does not exist/is not alive
        j       rightExit

checkRight:
        addi    $t0, $t0, 1		#$t0 = position right of current pos.
        lb      $v0, 0($t0)             #load life value into return register
        j       rightExit

rightExit:
	jr	$ra

testul:	
	move	$t0, $s1		#$t0 = current position
	lw	$t1, lwidth		#$t1 = line width

	div     $t0, $t1                #modulus of current position to check if
        mfhi    $t3                     #left is in grid
        bne     $t3, '0', ulLeftExists
        li      $t2, 0                  #left does not exist
	j	ulUpCheck		#jump to checking above current pos.

ulLeftExists:
	li	$t2, 1			#left exists
	
ulUpCheck:
	slt     $t3, $t0, $t1           #check if location < line width
        beq     $t3, '0', ulUpExists  #branch to check above position
        li      $t4, 0                  #up is not alive
        j       contUl                  #jump to end of subroutine

ulUpExists:
	li	$t4, 1			#up exists

contUl:
	and	$t3, $t2, $t4		#if above and left exist, $t3 = 1
	bne	$t3, '0', checkUl	#and ul position exists
	li	$v0, 0			#ul does not exist/ not alive
	j	ulExit			#jump to exit

checkUl:
	addi	$t0, $t0, -1		#moves $t0 left 1
	sub	$t0, $t0, $t1		#moves $t0 up a line
	lb	$v0, 0($t0)		#stores byte at $t0 into return register

ulExit:
	jr	$ra

testur:
	move    $t0, $s1		#$t0 = current position
        lw      $t1, lwidth		#$t0 = line width

        div     $t0, $t1                #modulus of current position to check if
        mfhi    $t3                     #right is in grid
        bne     $t3, 79, rightExists	#branches if pos. to right of $t0 exists
        li      $t2, 0                  #right does not exist
        j       urUpCheck		#jump to checking above $t0

rightExists:
        li      $t2, 1                  #right exists

urUpCheck:
        slt     $t3, $t0, $t1           #check if location < line width
        beq     $t3, '0', urUpExists  #branch to check above position
        li      $t4, 0                  #up is not alive
        j       contUr                  #jump to continuation of testing ur

urUpExists:
        li      $t4, 1                  #up exists

contUr:
        and     $t3, $t2, $t4		#verifies both up and right exist
        bne     $t3, '0', checkUr	#branch if up and right exist
        li      $v0, 0			#ur does not exist
        j       urExit			#jump to exit

checkUr:
	addi	$t0, $t0, 1		#moves $t0 right by 1
	sub	$t0, $t0, $t1		#moves $t0 up 1 line
	lb	$v0, 0($t0)		#stores byte in return register

urExit:
	jr	$ra

testdl:
	move    $t0, $s1		#$t0 = current position
        lw      $t1, lwidth		#$t1 = line width
	lw	$t5, gridSize		#$t5 = gridSize

        div     $t0, $t1                #modulus of current position to check if
        mfhi    $t3                     #left is in grid
        bne     $t3, '0', dlLeftExists
        li      $t2, 0                  #left does not exist
        j       dlDownCheck

dlLeftExists:
        li      $t2, 1                  #left exists

dlDownCheck:
        sub     $t5, $t5, $t1           #subtract and see if position is less
        slt     $t3, $t0, $t5           #than the grid size minus line width
        bne     $t3, '0', dlDownExists  #branch if position is not in last line
	li	$t4, 0			#down does not exist
	j	contDl			#jump to continuation of dl

dlDownExists:
        lb      $t4, 1                  #down exists

contDl:
        and     $t3, $t2, $t4		#verifies both down and left exist
        bne     $t3, '0', checkDl	#branch if both exist
        li      $v0, 0			#dl does not exist
        j       dlExit			#jump to exit

checkDl:
        addi    $t0, $t0, -1		#moves $t0 left by 1
        sub     $t0, $t0, $t1		#moves $t0 down 1 line
        lb      $v0, 0($t0)		#stores byte in return register

dlExit:
	jr	$ra
	
testdr:
	move    $t0, $s1		#$t0 = current position
        lw      $t1, lwidth		#$t1 = line width
        lw      $t5, gridSize		#$t5 = grid size

        div     $t0, $t1                #modulus of current position to check if
        mfhi    $t3                     #right is in grid
        bne     $t3, 79, drRightExists	
        li      $t2, 0                  #right does not exist
        j       drDownCheck		#jumps to checking below $t0

drRightExists:
        li      $t2, 1                  #right exists

drDownCheck:
        sub     $t5, $t5, $t1           #subtract and see if position is less
        slt     $t3, $t0, $t5           #than the grid size minus line width
        bne     $t3, '0', drDownExists  #branch if position is not in last line
        li      $t4, 0			#down does not exist
        j       contDr			#jump to continuation of dr

drDownExists:
        li      $t4, 1                  #down exists

contDr:
        and     $t3, $t2, $t4		#verifies both down and right exist
        bne     $t3, '0', checkDr	#branch if both exist
        li      $v0, 0			#dr does not exist
        j       drExit			#jump to exit

checkDr:
        addi    $t0, $t0, 1		#move $t0 right by 1
        sub     $t0, $t0, $t1		#move $t0 down 1 line
        lb      $v0, 0($t0)		#stores byte in return register

drExit:
	jr	$ra

#
# globl void process:
# Recursively processes the grid. Assumes that the first address of the grid is
# stored in $s6 and the first address after the grid is stored in $s7.
#

.globl	process
process:
	slt	$t0, $a0, $s7		# Test that we aren't past last address
	bne	$t0, $zero, p_start	# If we aren't, begin the routine
	jr	$ra			# If we are past, return without action

  p_start:
	addi	$sp, $sp, -16		# Make space in the stack
	sw	$ra, 12($sp)		# Push return address
	sw	$s0, 8($sp)		# Push $s0
	sw	$s1, 4($sp)		# Push $s1
	sw	$s3, 0($sp)		# Push $s3

	move	$s0, $zero		# Assign alive value to 0
	move	$s1, $a0		# Put current grid address in $s1

  p_up:
	jal	testup			# Test above
	bne	$v0, $zero, p_upleft	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_upleft:
	jal	testul			# Test above
	bne	$v0, $zero, p_left	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_left:
	jal	testleft		# Test above
	bne	$v0, $zero, p_downleft	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_downleft:
	jal	testdl			# Test above
	bne	$v0, $zero, p_down	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_down:
	jal	testdown		# Test above
	bne	$v0, $zero, p_downright	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_downright:
	jal	testdr			# Test above
	bne	$v0, $zero, p_right	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_right:
	jal	testright		# Test above
	bne	$v0, $zero, p_upright	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count
  p_upright:
	jal	testur			# Test above
	bne	$v0, $zero, p_endtest	# Branch to avoid adding to alive
	addi	$s0, $s0, 1		# Add one to alive count

  p_endtest:
	addi	$a0, $s1, 1		# Step the current grid address forward
	jal	process			# Recurse into process

	lb	$s3, 0($s1)		# Load the current grid value
	beq	$s3, $zero, p_dead	# Branch to dead if current is dead
  p_alive:
	slti	$t0, $s0, 4		# You ded with >3 live neighbors
	beq	$t0, $zero, p_die	# Die with >3 live neighbors
	slti	$t0, $s0, 2		# You ded with <2 live neighbors
	beq	$t0, $zero, p_exit	# If you're still alive, leave it alone
  p_die:
	li	$s3, '0'		# Kill the live cell
	j	p_exit
  p_dead:
	li	$t0, 3			# Load 3 into a temporary value
	bne	$s0, $t0, p_exit	# Stay dead if not 3 neighbors
  p_procreate:
	li	$s3, '1'		# Procreate if exactly 3 live neighbors

  p_exit:
	sb	$s3, 0($s1)		# Store the point in the grid
	lw	$s3, 0($sp)		# Pop $s3
	lw	$s1, 4($sp)		# Pop $s1
	lw	$s0, 8($sp)		# Pop $s0
	lw	$ra, 12($sp)		# Pop $s0
	addi	$sp, $sp, 16		# Return the stack to its previous state
	jr	$ra			# Jump back to the return address

# 
# void main subroutine:
# Starts the Game of Life.
#

.globl	main
main:
	lw	$s5, lwidth	# Load line width to $s8
	la	$s6, grid	# Load the first grid address to $s6
	lw	$t0, gridSize	# Load the size of the grid to $t0
	add	$s7, $s6, $t0	# Put the first address after the grid in $s7
  .globl breakpoint
  breakpoint:

	jal	readgrid
	jal	printgrid
	la	$a0, grid	# Pass the grid as the initial argument of process
	jal	process
	jal	printgrid

	li	$v0, 10		# Load exit syscall
	syscall			# Exit
