/*
Name: Sipeng He
UCID: 30113342
Tutorial: T03
Program: Binary to BCD converter
Date: May 30, 2021
Features:
-get an input of binary number from the user
-convert the binary number into BCD form and print it out
Limitations:
-negative binary number should be expressed by the negative sign(1111) in the most significant bits
-the number of digits of input binary numbers must be a multiple of 4
-not all binary numbers have corresponding BCD number
-no input validity check function is provided in the program
*/

.text
prompt: 		.string 	"Enter binary number: "	//format of prompt message	
print: 			.string 	"%d"			//format of output digit
minus: 			.string 	"-"			//format of minus sign "-"
finish: 		.string 	"\n"			//format of newline control character printed when the program ends
message: 		.string 	"The BCD number: "	//format of output message

.align 4							//ensures instructions are properly aligned
.global main							//makes main visible to the linker

main:			stp		x29, x30, [sp, -16]!	//saves state
			mov		x29, sp			//saves state
			
			mov		x20, 0			//count the number of input digits(0-4)
			mov		x21, 0			//accumulated decimal value
			mov		x22, 1			//pow_2 base to calculate 2^i
			mov		x23, 4			//i, the number of lsl that should be made
			mov 		x24, 1			//the flag for printing the output message
			
			ldr 		x0, =prompt		//load the prompt message to the x0 register
			bl 		printf			//print the prompt message
			
test:			bl 		getchar			//use getchar to get the ascii of one degit
			mov		x19, x0			//use x19 to store the input digit
			cmp		x19, 10			//check if the input digit is a newline control character
			b.eq		end			//if the input digit is a newline control character, finish the loop
			
top:			add 		x20, x20, 1		//accumulate the number counter
			
			cmp		x19, 48			//compare the ascii of the input with 48
			b.eq		setZero			//if the input ascii is 48, the input digit is 0
			
			cmp 		x19, 49			//compare the ascii of the input with 49
			b.eq 		setOne			//if the input ascii is 49, the input digit is 1
			
calculate:		sub		x23, x23, x20		//subtract the counter value from 4 to get i, which is the number of lsl that should be made
			lsl		x22, x22, x23		//calculate 2^i
			
			mul		x19, x19, x22		//calculate the decimal value of the input digit
			add		x21, x21, x19		//add the decimal value of input digit to the accumulate value of BCD digit
			
			mov     	x22, 1			//restore the pow_2 value for the next turn of input
			mov 		x23, 4			//restore i for the next turn of input
			
			cmp 		x24, 1			//if the flag for printing the output message is 1, go to printM to print it
			b.eq		printM
			
checkIfPrint:		cmp		x20, 4			//compare the counter value with 4
			b.eq		output			//if equal, print the bcd digit
			b		test			//if not equal to 4, return to the test to get next input
			
setZero: 		mov 		x19, 0			//the input digit is 0
			b 		calculate		//go to calculate to continue the loop

setOne:			mov 		x19, 1			//the input digit is 1
			b		calculate		//go to calculate to continue the loop
			
output:			mov 		x20, 0			//restore the counter
			cmp 		x21, 15			//check if the accumulated value is 15, which indicates that the number is negative
			b.eq 		negative		//if the number is negative, print "-"
			
			ldr 		x0, =print		//load the output format to the x0 register
			mov 		x1, x21			//assign the accumulated value stored in x21 to x1 to print it out
			bl 		printf			//print the digit
			mov 		x21, 0			//clear the accumulated value stored in x21 to calculate next bcd digit
			b 		test			//go back to the test to get another input digit
			
negative:		ldr 		x0, =minus		//load the "-" format to the x0 register
			bl 		printf			//print the "-" out
			mov		x21, 0			//clear the accumulated value stored in x21 to calculate next bcd digit
			b 		test			//go back to the test to get another input digit

printM: 		ldr  		x0, =message		//load the output message to x0
			bl 		printf			//print the output message
			mov		x24, 0			//set the flag for printing output message to 0(don't need to print it again)
			b		checkIfPrint		//go back to checkIfPrint to continue the loop
			
end: 			ldr		x0, =finish		//load the newline control character to register x0 to print it out
			bl 		printf			//print the newline control character out
			
			ldp 		x29, x30, [sp], 16	//restores state
			ret					//restores state
