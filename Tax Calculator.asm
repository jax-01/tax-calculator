###			Tax Calculator
###			 MIPS Program
###		A CMSC 131 Requirement
###	Members:
###		Asoy, Andrei Luz B.
###		Castillo, John Albert A.
###		Merales, Ben Julian M.
###
### Brief Description:
###		This Tax Calculator was based on the official DOF Tax Calculator which is found here: https://taxcalculator.dof.gov.ph/
###		Due to time constraints, the option to input a spouse's MGI is omitted. Hence, 'Single' is the only option for Civil Status
###	
### Special Thanks to:
###		Amell Peralta
###		StackOverflow
### 	Kenn Acabal	






.data
	title:		.asciiz	"\t\t----------------\tTax Calculator (2023)\t----------------\n"
	civilStatus:	.asciiz	"Civil Status?\n\t1.) Single\n\t2.) Married\n"
	jobSector:	.asciiz	"\nYour Job Sector\n\t1.) Private\n\t2.) Government\n\t3.) Overseas Foreign Worker\n"
	input:		.asciiz	"Enter Input: "
	invalidInput:	.asciiz "Input Error: Please select a valid input\n"

	
	askYSS : .asciiz "Your Spouse's Sector"

	eMGI : .asciiz "\nEnter Monthly Gross Income: "
	eSMGI : .asciiz "Enter Spouse's MGI: "
	outOverseas: .asciiz "NOTE: The exemption of minimum wage earners and OFWs from Personal Income Tax is still valid."
	outRes: .asciiz "Results: "
	outIA9: .asciiz "Is Income Above Php 90000?"
	yes: .asciiz " YES"
	no: .asciiz " NO"
	outNPAT: .asciiz "\nNet Pay After Tax: "
	outT: .asciiz "Total"
	outMD: .asciiz "\nMonthly Deductions:\n"
	outII: .asciiz "Income 1 \t | \t Income 2"
	_newLine: .asciiz "\n"
	_tab: .asciiz "\t"
	
	zeroAsFloat: .float 0.0
	
.text
	main:
		# Print title
		li $v0, 4
		la $a0, title
		syscall
		
		# Prompt civil status
		li $v0, 4
		la $a0, civilStatus
		syscall
		# Get civil status
		jal getCivilStatus
		
		# Prompt job sector
		li $v0, 4
		la $a0, jobSector
		syscall
		# Get job sector
		jal getJobSector
		
		# get correct income
		jal getIncome
		
		# compute contributions
		jal startContributions
		
		# compute PHILHEALTH
		jal computePH
		
		# compute PAGIBIG
		jal computePI
		
		# compute Total
		jal addContributions

		# prompt disclaimer when user inputs married
		jal selectedMarried

		# Exit program
		jal exit
	
.text	
	getCivilStatus:
		# Loop until condition is satisfied
		cs_loop:
			li $v0, 4
			la $a0, input
			syscall
			
			# Get input
			li $v0, 5
			syscall
			# Store input to $s0
			move $s0, $v0
			
			# Check if input is > 2
			sgt $t1, $s0, 2
			# Check if input is < 1
			slti $t0, $s0, 1
			
			or $t0, $t0, $t1
			
			# If valid, end loop and return to caller
			beqz $t0, end_cs_loop
			
			li $v0, 4
			la $a0, invalidInput
			syscall
			
			b cs_loop
			
		end_cs_loop:
			jr $ra		# return to caller

.text		
	getJobSector:
		# Loop until condition is satisfied
		js_loop:
			li $v0, 4
			la $a0, input
			syscall
			
			# Get input
			li $v0, 5
			syscall
			
			
			# Store input to $s0
			move $s1, $v0
			
			# Check if input is > 2
			sgt $t1, $s1, 3
			# Check if input is < 1
			slti $t0, $s1, 1
			beq $s1, 2, selectedMarried
			
			or $t0, $t0, $t1
			
			# If valid, end loop and return to caller
			beqz $t0, end_js_loop
			
			li $v0, 4
			la $a0, invalidInput
			syscall
			
			b js_loop
			
			
			
		end_js_loop:
			move $s7, $s1
			
			jr $ra		# return to caller
			
		end_overseas:
			li $v0, 4
			la $a0, outOverseas
			syscall
			
			li $v0, 10
			syscall
.data
	_is90: .float 90000.0
.text
	getIncome:
				
		lwc1 $f13, zeroAsFloat
		
		# Display message to ask for income
		li $v0, 4
		la $a0, eMGI
		syscall
		
		#Get input from user
		li $v0, 6	
		syscall
		#User input to float
		add.s $f12, $f0, $f13
		
		# Store value to $f3
		mov.s $f3, $f12

		# Check Income
		li $v0, 4
		la $a0, outIA9
		syscall
		
		lwc1 $f19, _is90
		c.lt.s $f3, $f19
		
		bc1t lessThan90
		bc1f greaterThan90
		
		lessThan90:
			li $v0, 4
			la $a0, no
			syscall
			
			b endCheckIncome
		
		greaterThan90:
			li $v0, 4
			la $a0, yes
			syscall
		
			b endCheckIncome
			
		endCheckIncome:
			jr $ra

.data
	out_disclaimer: .asciiz "\nNOTE: For married couples, please run the program again to determine your spouse's taxes.\n"
.text
	selectedMarried:
		li $v0, 4
		la $a0, out_disclaimer
		syscall
		
		jr $ra
.text
	startContributions:
		li $v0, 4
		la $a0, outNPAT
		syscall
		
		li $v0, 2
		mov.s $f12, $f3
		syscall
		
		li $v0, 4
		la $a0, outMD
		syscall
		
		beq $s1, 3, end_overseas
		beq $s1, 2, computeGSIS
		beq $s1, 1, computeSSS
		
		jr $ra
	exit:	
		li $v0, 10
		syscall

.data
	SSS_text_0: .asciiz "\n\tSSS - "
	income:			.float	0.0
	oneThousandAsFloat:	.float	1000
	twentyFiveAsFloat:	.float	25
	lowerBound:		.float	0.0
	upperBound:		.float	1000.0
	payment:		.float	150.0

.text
	computeSSS: #reserve $f5 for sss
		#set GSIS to 0
		lwc1 $f0, zeroAsFloat
		add.s $f6, $f0, $f0

		lwc1 $f15, payment
		lwc1 $f16, lowerBound
		lwc1 $f17, upperBound
		
		lwc1 $f10, zeroAsFloat			# Reserved as 0
		lwc1 $f11, oneThousandAsFloat		# Reserved as 1000
		lwc1 $f25, twentyFiveAsFloat		# Reserved as 25
		
		lwc1 $f13, income
		
		start_loop:
			# Check if income is less than or equal to upperBound
			c.lt.s $f3, $f17
			bc1t end_loop
			
			#slt $t1, $f3, $f17	# upper bound
			#sgt $t0, $f3, $f2	# lower bound
			
			# Check if income is equal to upperBound
			
			
			# Increment lowerBound and upperBound by 1,000
			add.s $f17, $f17, $f11
			add.s $f16, $f16, $f11
			
			# Increment payment by 25
			add.s $f15, $f15, $f25
			
			
			# Loop back to start_loop
			b start_loop
		end_loop:
			# Print total payment
			li $v0, 4
			la $a0, SSS_text_0
			syscall

			li $v0, 2
			add.s $f12, $f15, $f10
			syscall
			
			#move to f5
			mov.s $f5, $f15
			jr $ra


.data
	# reserve $f6 for GSIS
	GSIS_factor : .float 0.09
	GSIS_text_0: .asciiz "Inputted Income: "
	GSIS_text_1: .asciiz "\tGSIS - "
.text
	computeGSIS:
		#set SSS to 0
		lwc1 $f0, zeroAsFloat
		add.s $f5, $f0, $f0
		
		lwc1 $f11, GSIS_factor		
		
		li $v0, 4						#\n
		la $a0, _newLine
		syscall 
		
		li $v0, 4						#print text
		la $a0, GSIS_text_1
		syscall
		

		mul.s $f6, $f3, $f11					#multiply
		
		li $v0, 2						#print 
		mov.s $f12, $f6
		syscall	
		
		jr $ra
		
.data
	# reserved $f7 for PI
	PI_range: .float 1500.00
	PI_factor_1: .float 0.01
	PI_factor_2: .float 0.02
	
	TFV: .float 1000.00
	
	PI_text_1: .asciiz "\tPagibig - "
	newLine: .asciiz "\n"
.text
	computePI:
		lwc1 $f9, PI_range
		
		li $v0, 4						#\n
		la $a0, _newLine
		syscall
		li $v0, 4
		la $a0, PI_text_1
		syscall
		
		
		
		c.le.s $f3, $f9
		bc1t PI_lowIncome
		bc1f PI_highIncome

		PI_lowIncome:
			lwc1 $f10, PI_factor_1
			mul.s $f7, $f10, $f3
			li $v0, 2
			mov.s $f12, $f7
			syscall
			b PI_next
			
		PI_highIncome:
			lwc1 $f10, PI_factor_2
			mul.s $f7, $f10, $f3
			li $v0, 2
			mov.s $f12, $f7
			syscall
			b PI_next
			
		PI_next:
			jr $ra

.data
	PH_range_1: .float 10000.00
	PH_range_2: .float 70000.00
	PH_min_pay: .float 400.00
	PH_max_pay: .float 2450.00
	PH_mid_factor: .float 0.035
	PH_text_1: .asciiz "\tPhilhealth - "

.text
	#reserve $f8 for Philhealth
	computePH:
		lwc1 $f11, PH_range_1
		lwc1 $f12, PH_range_2
		
		li $v0, 4						#\n
		la $a0, _newLine
		syscall 
		li $v0, 4
		la $a0, PH_text_1
		syscall
		
		
		
		c.le.s $f3, $f11
		bc1t lowIncome
		
		c.lt.s $f3, $f12
		bc1f highIncome
		
		b midIncome
	
	lowIncome:
		lwc1 $f8, PH_min_pay
		mov.s $f12, $f8
		li $v0, 2
		syscall
		b PH_next
		
	midIncome:
		lwc1 $f13, PH_mid_factor
		mul.s $f8, $f3, $f13
		li $v0, 2
		mov.s $f12, $f8
		syscall
		b PH_next
	
	highIncome:
		lwc1 $f8, PH_max_pay
		mov.s $f12, $f8
		li $v0, 2
		syscall
		b PH_next
		
	PH_next:
		jr $ra


.data
	outTC: .asciiz "\n\nTotal Contributions: "
	outNTHP: .asciiz "\nNet Take Home Pay: "
.text
	addContributions:
		li $v0, 4
		la $a0, outTC
		syscall
		
		lwc1, $f10 zeroAsFloat
		
		add.s $f4, $f10, $f10		#	0 + 0
			
		add.s $f4, $f5, $f6		#	SSS + GSIS
		
		add.s $f4, $f4, $f7		#	SSS + GSIS + PI
		
		add.s $f4, $f4, $f8		#	SSS + GSIS + PI + PH
		
		li $v0, 2
		mov.s $f12, $f4
		syscall
		
		li $v0, 4
		la $a0, outNTHP
		syscall
		
		sub.s $f0, $f3, $f4
		li $v0, 2
		mov.s $f12, $f0
		syscall
