/*
Name: Sipeng He 
UCID: 30113342
Program: BCD to binary number converter
Date: May 30, 2021
Features:
-prompt for a BCD number from the user
-convert the BCD number to corresponding binary number and print it out
Limitations:
-the negative sign "-" from the input BCD is represented by "1111" in the most significant bits in corresponding binary number
-no validity check function is provided by the program
*/


.text								//declare the format of messages and output
prompt: 		.string 	"Please enter a BCD: "	//the format of prompt message
message: 		.string 	"The binary number: "	//the format output message
output: 		.string 	"%d"			//the format of output digit
finish: 		.string 	"\n"			//the newline control character when the program ends

.align 4							//ensures instructions are properly aligned
.global main							//makes main visible to the linker

main:			stp		x29, x30, [sp, -16]!	//saves state
			mov		x29, sp			//saves state
			
			mov		x28, 1			//flag for printing the output message
			mov 		x27, 4			//counter for printing negative sign(1111)
			mov 		x26, 1			//1 is stored in x26 for printing negative sign
			ldr		x0, =prompt		//load the prompt message to x0 register				
			bl 		printf			//print the prompt message
			
test:			bl		getchar			//get the ascii of one input digit
			mov 		x19, x0			//stored the ascii of the input digit in x19
			cmp		x19, 10			//check if the input is a newline control character
			b.eq 		done			//if the input is a newline control character, finish the loop
			
			cmp 		x28, 1			//check the flag for printing the output message
			b.eq		printM			//if the flag is 1, go to the printM to print the message
			
checkNega:		cmp		x19, 45			//compare the input ascii with the ascii of "-"
			b.eq		negative		//if the input is a "-", go to negative to print the negative sign(1111)
			
calculate: 		sub		x19, x19, 48		//subtract 48(ascii of "0") from the input ascii to get the decimal value of the input digit
			
			mov		x20, 8			//x20 stores the value that is used to mask the digits(1000)
			mov 		x21, 3			//x21 stores the number of lsr that should be made to the masked value to print the bit
			
			and		x22, x19, x20		//mask the value to get the first digit of the input value
			lsr		x22, x22, x21		//do lsr 3 times to move the digit to the least significant bit to print it out
			
			ldr		x0, =output		//load the output formate to x0
			mov		x1, x22			//load the bit value(already moved to the least significant bit) to x1 to print it out
			bl 		printf			//print the digit out
			
			lsr		x20, x20, 1		//do 1 time of lsr to the mask to get the next bit of the input value(1000->0100)
			sub		x21, x21, 1		//subtract 1 from the number of lsr that should be made to print the next bit(3-1=2)
			
			and		x22, x19, x20		//mask the value to get the second digit of the input value
			lsr		x22, x22, x21		//do lsr 2 times to move the digit to the least significant bit to print it out
			
			ldr		x0, =output		//load the output formate to x0
			mov		x1, x22			//load the bit value(already moved to the least significant bit) to x1 to print it out
			bl 		printf			//print the digit out
			
			lsr		x20, x20, 1		//do 1 time of lsr to the mask to get the next bit of the input value(0100->0010)
			sub		x21, x21, 1		//subtract 1 from the number of lsr that should be made to print the next bit(2-1=1)
			
			and		x22, x19, x20		//mask the value to get the third digit of the input value
			lsr		x22, x22, x21		//do lsr 1 time to move the digit to the least significant bit to print it out
			
			ldr		x0, =output		//load the output formate to x0
			mov		x1, x22			//load the bit value(already moved to the least significant bit) to x1 to print it out
			bl 		printf			//print the digit out
			
			lsr		x20, x20, 1		//do 1 time of lsr to the mask to get the next bit of the input value(0010->0001)
			sub		x21, x21, 1		//subtract 1 from the number of lsr that should be made to print the next bit(1-1=0)
			
			and		x22, x19, x20		//mask the value to get the third digit of the input value
			lsr		x22, x22, x21		//do lsr 0 time to move the digit to the least significant bit to print it out
			
			ldr		x0, =output		//load the output formate to x0
			mov		x1, x22			//load the bit value(already moved to the least significant bit) to x1 to print it out
			bl 		printf			//print the digit out
			
			mov 		x20, 8			//restore the mask value to 8(1111)for next input digit
			mov		x21, 3			//restore the number of lsr to move the bit to the least significant bit
			b		test			//go to test to take next input digit
			
printM:			ldr		x0, =message		//load the message to x0 to print it out
			bl 		printf			//print the message out
			mov 		x28, 0			//set the flag for printing message to 0(no need to do it again)
			b 		checkNega		//go to checkNega to continue the loop
			
negative: 		ldr 		x0, =output		//load the output format to x0
			mov		x1, x26			//assign the value stored in x26(1) to print the negative sign(1111)
			bl 		printf			//print a "1"
			
			sub		x27, x27, 1		//subtract 1 from the counter value for printing negative sign 
			cmp		x27, 0			//compare the counter value with 0
			b.eq	        test			//if the counter value equals to 0, go back to test to get next input
			b 		negative		//if the counter value doesn't equal to 0, go to negative to print "1" again
		
done:			ldr		x0, =finish		//load the newline control character to register x0 to print it out
			bl 		printf			//print the newline control character out

			ldp 		x29, x30, [sp], 16	//restores state
			ret					//restores state
			
			
			
			
			
			
			
			
