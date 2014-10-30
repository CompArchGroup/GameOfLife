# main.asm

.data
lwidth:	.word	80		# Width of each line
grid:	.space	400		# Space for the grid (80x50)

.text
	j	main

#
# globl void readgrid:
# Reads in a grid pattern from a file.
#
readgrid:
	jr	$ra

#
# globl void printgrid:
# Prints the current contents of the grid.
#
printgrid:
	jr	$ra

#
# globl bool testdir:
# Tests a direction based on argument. For now, is split into several separate
# subroutines, each for one direction.
#
testup:
	jr	$ra
testdown:
	jr	$ra
testleft:
	jr	$ra
testright:
	jr	$ra
testul:
	jr	$ra
testur:
	jr	$ra
testdl:
	jr	$ra
testdr:
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
	li	$s3, 0			# Kill the live cell
	j	p_exit
  p_dead:
	li	$t0, 3			# Load 3 into a temporary value
	bne	$s0, $t0, p_exit	# Stay dead if not 3 neighbors
  p_procreate:
	li	$s3, 1			# Procreate if exactly 3 live neighbors

  p_exit:
	sb	$s3, 0($s1)		# Store the point in the grid
	lw	$s3, 0($sp)		# Pop $s3
	lw	$s1, 4($sp)		# Pop $s1
	lw	$s0, 8($sp)		# Pop $s0
	lw	$ra, 12($sp)		# Pop $s0
	addi	$sp, 16			# Return the stack to its previous state
	jr	$ra			# Jump back to the return address

# 
# void main subroutine:
# Starts the Game of Life.
#

.globl	main
main:
	lw	$s5, lwidth	# Load line width to $s8
	la	$s6, grid	# Load the first grid address to $s6
	add	$s6, $s7, 400	# Put the first address after the grid in $s7

	jal	process

	li	$v0, 10		# Load exit syscall
	syscall			# Exit
