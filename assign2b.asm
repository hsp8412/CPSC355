//Name: Sipeng He
//Tutorial: T03
//UCID: 30113342

//Program: An input sequence processor that can determine if the sequence is Fibonacci, triangular, or neither
//-macros are used in this version
//-test is at the bottom of the loop(still a pre-test one)

//Versions:
//May 20, 2021
//-the program can generate a random number
//-random number is limited to the range of 0-100
//-the program can print the prompt message and get an input from user
//-the loop test is set up
//May 21, 2021
//-the program can check if the input sequence is still fibonacci or triangular each turn
//-the program can store and update the two largest numbers in the sequence each turn
//-the program can check if the input matches the random number generated each turn
//May 22,2021
//-the loop ends when a negative input is made
//-the program can determine if the jackpot is won when the loop is finished
//-the program can determine if the input sequence is a fibonacci one or triangular one when the loop is finished
//-the program can print the length of the input sequence
//-the program can print the two largest numbers in the sequence when the loop is finished
//-the program can print messages acccording to the processing result of the input sequence
//May 23, 2021
//-macros are set for the frequently used registers(x19-x28)
//-test is moved to the end of the loop(but the loop is still a pre-test one)

//Limitations:
//-a sequence of 1 or 1,1 will not be counted as fibonacci sequence. The minimum length of fibonacci sequence is 3
//-a sequence of 1 will not be counted as triangular sequence. The minimum length of triangular sequence is 2
//-a fibonacci or triangular sequence that can be determined by the program can only start at 1, not in the middle
//-the largest number and the second largest number that determined by the program can be the same

define(counter, x19)	//define macro for the register that counts the number of inputs
define(last_turn_input, x20)	//define macro for the register that stores the input from last turn
define(current_input, x21)	//define macro for the register that stores the current input
define(correct_sequence_number, x22)	//define macro for the register that stores the correct fibonacci and triangular number of a specific turn
define(jackpot_flag, x23)	//define macro for the register that stores the flag that indicates if the jackpot is won 
define(jackpot_number, x24)	//define macro for the register that stores the randomly generated jackpot number
define(second_largest_number, x25)	//define macro for the register that stores the second largest number in the input sequence
define(largest_number, x26)	//define macro for the register that stores the largest number in the input sequence
define(fibo_flag, x27)	//define macro for the register that stores the flag that indicates if the input sequence is a fibonacci one
define(triangular_flag, x28)	//define macro for the register that stores the flag that indicates if the input sequence is a triangular one

.data	//declare n
n: .word	//declare n

.text	//declare format of input and messages
input: .string "%ld"	//the input format
prompt: .string "Please enter a number: "	//the format of prompt message
message1: .string "This sequence is a Fibonacci sequence. Length of sequence: %ld\n"	//the format of fibonacci sequence message
message2: .string "This sequence is a Triangular sequence. Length of sequence: %ld\n"	//the format of triangular sequence message
message3: .string "This sequence only contains one number: %ld\n"	//the format of single input message
message4: .string "The two largest numbers are %ld, %ld. Length of sequence: %ld\n"	//the format of the message that prints two largest numbers
message5: .string "You won the jackpot(%ld)!\n"	//the format of jackpot message
message6: .string "This sequence is empty\n"	//the format of empty sequence	

.align 4	//ensures instructions are properly aligned
.global main	//makes main visible to the linker

main: 

		stp x29, x30, [sp, -16]!	//saves state
		mov x29, sp	//saves state
	
		mov counter, 0	//initialize the counter that records how many numbers are entered to the sequence
		mov last_turn_input, 0	//initialize the register that stores the input from last turn
		mov current_input, 0	//initialize the register that stores the input of this turn
		mov correct_sequence_number, 1	//initialize the register that calculates and stores the correct fibonacci and triangular number of a turn
		mov jackpot_flag, 0	//initialize the flag that indicates if the jackpot is won
		mov second_largest_number, 0	//initialize the register that stores the second largest number in the sequence
		mov largest_number, 0	//initialize the register that stores the largest number in the sequence
		mov fibo_flag, 1	//initialize the flag that indicates if the sequence is a fibonacci sequence
		mov triangular_flag, 1	//initialize the flag that indicates if the sequence is a triangular sequence
	
		mov x0, 0	//initialize the x0 register in which the random number will be generated
		bl time	//return the current calendar time
		bl srand //use time as the seed to generate random number
		bl rand	//generate a random unsigned number
		mov jackpot_number, x0 //use x24 to store the random number
	
downsize: 

		cmp jackpot_number, 100	//compare the random number with 100
		b.lt test	//if the random number is less than 100, continue the program
		sub jackpot_number, jackpot_number, 100	//if the random number is not less than 100, subtract 100 from it
		b downsize	//compare the random number with 100 again
			
		b test	//go to test

top:	

		add counter, counter, 1	//add 1 to the number counter

checkIfFibo:

		cmp current_input, correct_sequence_number	//compare the current input number with the sum of last two input numbers
		b.ne notFibo	//if it's not equal, the sequence is not a fibonacci one anymore, set the fibonacci flag to 0

checkIfTriangular:

		add correct_sequence_number, last_turn_input, counter	//calculate the correct triangular number by adding the counter value and input from last turn
		cmp current_input, correct_sequence_number	//compare the current input number with the correct triangular number stored in x22
		b.ne notTriangular	//if not equal, this sequence is not a triangular one anymore, set the triangular flage to 0
	
updateMaximum:

		cmp current_input, second_largest_number	//compare the current input with the second largest number stored in x25
		b.gt updateLargest	//if it's greater than the second largest number, updates should be made

checkIfJackpot:

		cmp current_input, jackpot_number	//compare the current input with the random number
		b.eq jackpot	//if equal, set the jackpot flag to 1

storeInput:

		add correct_sequence_number, current_input, last_turn_input	//update x22, in which the sum of the last two input numbers are stored
		mov last_turn_input, current_input	//update x20, in which the input number of last turn is stored
		
test:

		ldr x0, =prompt	//load the prompt message
		bl printf	//print the prompt message
	
		ldr x0, =input	//load the input format
		ldr x1, =n	//n will get the input number
		bl scanf	//use scanf to get the input number
		ldr current_input, n	//use x21 to store the input number of the current turn
		
		cmp current_input, 0	//compare the input number of current turn with 0
		b.lt done	//if the input number is a negative one, end the loop
		b top	//if the input number is not a negative one, go to top and continue the loop

notFibo: 

		mov fibo_flag, 0	//set the fibonacci flag to 0
		b checkIfTriangular	//go to testIfTriangular and continue the loop

notTriangular:

		mov triangular_flag, 0 	//set the Triangular flag to 0
		b updateMaximum	//go to updateMaximum and continue the loop

jackpot: 

		mov jackpot_flag, 1 //set the jackpot flag to 1
		b storeInput	//go to storeInput to continue the loop
	
updateLargest: 

		cmp current_input, largest_number	//compare the current input with the largest input stored in x26
		b.gt updateFirstLargest	//if the current input is greater than the largest input, update the largest input
		b updateSecondLargest	//if the current input is not greater than the largest input, update the second largest input

updateFirstLargest:

		mov second_largest_number, largest_number	//move the largest input into the register that stores the second largest input
		mov largest_number, current_input	//store the current input in the register that stores the largest input
		b checkIfJackpot	//go to checkIfJackpot to continue the loop

updateSecondLargest:

		mov second_largest_number, current_input	//store the current input in the register that stores the second largest input
		b checkIfJackpot	//go to checkIfJackpot to continue the loop
	
done:

		cmp jackpot_flag, 1	//check if the jackpot flag is 1
		b.eq wonJackpot	//if the jackpot flag is equal to 1, the user win the jackpot

ifNoInput:

		cmp counter, 0	//check if the counter value is 0
		b.eq noInput	//if there is no input, print the no input message

ifSingleInput:

		cmp counter, 1	//check if the counter value is 1
		b.eq singleInput	//if there is only one input, print the single input message

		cmp triangular_flag, 1	//check if the flag for triangular sequence is 1
		b.eq triangular	//if the triangular flag equals 1, print the triangular message
	
		cmp fibo_flag, 1	//check if the flag for fibonacci sequence is 1
		b.eq fibo	//if the flag for fibonacci sequence equals 1, print the fibonacci message
	
		b largestNumbers	//if there are more than 1 input numbers, and the sequence is neither a fibonacci one or a triangular one, print the two largest numbers

wonJackpot: 

		ldr x0, =message5	//load the jackpot message to x0
		mov x1, jackpot_number	//load the random number stored in x24 to print it out
		bl printf	//print the message
		b ifNoInput	//go to ifNoInput to continue the result processing

fibo:

		cmp counter, 3	//compare the number of inputs with 3
		b.lt largestNumbers	//if the number of inputs is less than 3, this sequence is not a fibonacci sequence, print the largest 2 numbers
		ldr x0, =message1	//load the message for fibonacci sequence
		mov x1, counter	//assign the sequence length to the x1 register to print it out
		bl printf	//print the message for fibonacci sequence
		b end	//end the program running

triangular:

		ldr x0, =message2	//load the message for triangular sequence to register x0 to print it out
		mov x1, counter	//assign the sequence length to x1 to print it out
		bl printf	//print the message for triangular sequence
		b end	//end the program running

noInput:

		ldr x0, =message6	//load the no input message to x0
		bl printf	//print the no input message
		b end	//end the program running
	
singleInput:

		ldr x0, =message3	//load the single input message to x0
		mov x1, last_turn_input	//assign the single input number stored in x20 to x1 to print it out		
		bl printf	//print the single input message
		b end	//end the program running

largestNumbers:

		ldr x0, =message4	//load the message that shows the two largest numbers
		mov x1, largest_number	//assign the largest number stored in x26 to x1 to print it out
		mov x2, second_largest_number	//assign the second largest number stored in x25 to print it out
		mov x3, counter	//assign the sequence length stored in counter to x3 to print it out
		bl printf	//print the message that shows the two largest numbers
		b end	//end the program running
	
end:

		ldp x29, x30, [sp], 16	//restores state
		ret	//restores state
	
