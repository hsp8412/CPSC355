/*	Name: Sipeng He
	UCID: 30113342
	Tutorial: T03
	Date: June 14, 2021
	Program: A simple memory card game
	Features:
	-display function to print the game board
	-randomNum function to generate random number within the input boundary
	-the initialize function to initialize the game board
	-shuffle function to shuffle the cards generated
	-swap function to swap the two specified cards
	-findDistance function to find the distance of the two specific cards
	-game routine control in the main function
	-validity check
	-logFile function to keep a record of player's name and score
	Limitations:
	-There shouldn't be any space between the input player name
*/
define(input_n, x19)					//store the N value
define(board_arr, x20)					//store the base address of board array
define(ifReveal_arr, x21)				//store the base address of ifReveal array
define(temp_card, w22)					//store the card that the player is looking for a match
define(match_x, x23)					//store the row value of a matched card
define(match_y, x24)					//store the colume value of a matched card
define(distance, x25)					//store the distance between the chosen card and the correct matched card
define(offset, x26)						//store the offset value 
define(i, x27)							//store i
define(j, x28)							//store j
define(fp, x29)							//frame pointer
define(lr, x30)							//link register

.data
n: .word 0								//catch the input n value through scanf
score: .word 0							//store the score value
reveal_num: .word 0						//count the number of cards that have been revealed
input_x: .word 0						//catch input x value
input_y: .word 0						//catch input y value
catch: .dword 0							//catch the input name through scanf
name: .dword 0							//store the name
input: .dword 0							//store the input string

q_align = -16							//quadword align

.text
msg_prompt_name: 	.string 	"Please enter your name: "												//prompt for name				
msg_prompt_n: 		.string 	"Please enter a valid n(n>0): "											//prompt for n
fmt_n: 				.string 	"%ld"																	//n input format
fmt_name: 			.string 	"%s"																	//name input format
revealed:			.string 	"%d\t"																	//format to print revealed card
unrevealed:			.string 	"X\t"																	//format to print unrevealed card
new_line: 			.string 	"\n"																	//new line
msg_title:			.string 	"The current game board: \n"											//game board title
msg_pause: 			.string 	"Press Enter to continue....\n"											//pause message
clear_screen: 		.string 	"clear"																	//clear system call to clear the screen
msg_prompt_guess:	.string 	"Enter the coordinates of a card(Enter Q/q to exit the game): "			//prompt for a guess from user
msg_score: 			.string 	"Your current score: %d\n"												//current score display format
msg_target: 		.string 	"The card you are looking for is: %d\n"									//format for displaying the card that the player should be looking for
input_fmt:			.string 	"%[^\n]"																//format to take an input string for a guess
guess_fmt: 			.string 	"%d %d"																	//format to get the two coordinates from the input string
display_input: 		.string 	"The coordinates you pick are: (%d,%d)\n"								//format to show the chosen coordinates
msg_already_reveal: .string 	"This card has already been revealed, please select another card\n"		//message when choosing a card that is already revealed
msg_invalid_input:	.string 	"Invalid input. Please try again\n"										//invalid input notice
msg_hint:			.string 	"You are %d card(s) away!\n"											//hint message
msg_correct_guess: 	.string 	"It's a match!"															//message when a matched card is found
msg_game_over: 		.string 	"Game over.\n"															//game over message
msg_name_report:	.string 	"Player name: %s\n"														//display player name
msg_score_report: 	.string 	"Final score: %d\n"														//display final score
file_name:			.string 	"assign5.log"															//name of the log file
open_mode:			.string 	"a+"																	//opening mode of the log file
q_input: 			.string 	"q"																		//see if user wants to quit
Q_input: 			.string 	"Q"																		//see if user wants to quit

.balign 4														//ensure alignment
.global main													//makes main visible to the linker

main:			stp		fp, lr, [sp, -16]!						//save states
				mov		fp, sp 									//save states	
				
				cmp 	x0, 3									//check if the command line contains a input n and a name
				b.lt	name_prompt								//if any argument is missing, go to input_prompt to prompt the user for it
				
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				
				mov 	x11, x1									//give the address of command line arguments to x11
				ldr 	x10, [x11, 8]							//load the 2nd argument(name) to x10
				str 	x10, [x9]								//store the second argument(name) to name
				
				
				ldr 	x0, [x11, 16]							//load the 3rd argument(N) to x0
				bl 		atoi									//call the c function atoi to change N from string to int value
				mov 	input_n, x0								//get the int N value

				b 		input_test								//go to input_test to check the validity
			
name_prompt:	ldr 	x0, =msg_prompt_name					//load the prompt message for name to x0
				bl 		printf									//print the prompt message
				
				ldr		x0, =fmt_name							//load the input name format to x0
				ldr 	x1, =catch								//load the address of catch to get the input name
				bl 		scanf									//call scanf to get the input name
				
				bl		getchar									//clear buffer
				
				ldr 	x9, =catch								//load the input name to x9
				
				adrp 	x10, name								//calculate the address of name
				add 	x10, x10, :lo12:name					//calculate the address of name
				str 	x9, [x10]								//store input name to name
				
				
n_prompt:		ldr 	x0, =msg_prompt_n						//load the prompt message for n to x0
				bl 		printf									//print the message
		
				ldr 	x0, =fmt_n								//load the input n format to x0
				ldr 	x1, =n									//use n to catch the input N
				bl 		scanf									//get an input N from the user
				ldr 	input_n, n								//load the input N to x19
				
				bl		getchar									//clear buffer
			
input_test:		cmp 	input_n, 0								//check if the input N value is positive
				b.le 	n_prompt								//if negative or equal to 0, prompt for an input again
				
				lsl 	x9, input_n, 1							//x9 = 2*N
				adrp 	x10, score								//calculate the address of score
				add 	x10, x10, :lo12:score					//address of score now in x10
				str 	x9, [x10]								//store 2*N to score
				
				mul 	x9, input_n, input_n					//x9 = N*N
				lsl 	x9, x9, 2								//x9 = 2*N*2*N
				lsl		x9, x9, 2								//x9 = 2N*2N*4
				mov		x10, -1									//x10 = -1
				mul 	x9, x9, x10								//x9 = -2N*2N*4
				
				and 	x9, x9, q_align							//clear the first 4 bits to ensure quadword align
				
				add 	sp, sp, x9								//allocate the memory for board array
				mov 	board_arr, sp							//give the address of sp to board_arr
				
				bl 		initialize								//call the initialize function to initialize the game board
				
				mul 	x9, input_n, input_n					//x9 = N*N
				lsl 	x9, x9, 2								//x9 = 2*N*2*N
				lsl 	x9, x9, 2								//x9 = 4*2*N*2*N
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//x9 = -4*2*N*2*N
				and 	x9, x9, q_align							//clear the first 4 bits to ensure quadword align
				
				add 	sp, sp, x9								//allocate the memory for ifReveal array
				mov 	ifReveal_arr, sp						//give the address of sp to ifReveal_arr
				
				mov 	i, 0									//set i to 0		
				mov 	j, 0									//set j to 0
				mov 	offset, 0								//set offset to 0
				
ifReveal_ini: 	mov 	w9, 1									//x9 = 1
				lsl		x10, input_n, 1							//x10 = 2*N
				mul 	offset, i, x10							//offset = i*2*N
				add 	offset, offset, j						//offset = (i*2*N)+j
				lsl 	offset, offset, 2						//offset = ((i*2*N)+j)*4
				str 	w9, [ifReveal_arr, offset]				//store the value 1 to ifReveal array
				
				add 	j, j, 1									//j++
				cmp 	j, x10									//check if j reaches 2*N 
				b.lt 	ifReveal_ini							//if j is less than 2*N, go back to ifReveal_ini to continue
				
				add 	i, i, 1									//i++
				mov 	j, 0									//reset j to 0
				cmp 	i, x10									//check if i reaches 2*N
				b.lt  	ifReveal_ini							//if i is less than 2*N, go back to ifReveal_ini to continue
				
				bl 		display									//call the display function
				
				ldr 	x0, =msg_pause							//load the pause message to x0
				bl 		printf 									//print the pause message
				
				bl 		getchar									//pause
				
				ldr		x0, =clear_screen						//clear the screen
				bl		system									//clear the screen
				
				mov 	i, 0									//reset i to 0
				mov		j, 0									//reset j to 0
				
reset_reveal:	mov 	w9, 0									//x9 = 0
				lsl		x10, input_n, 1							//x10 = 2*N
				mul 	offset, i, x10							//offset = i*2*N
				add 	offset, offset, j						//offset = (i*2*N)+j
				lsl 	offset, offset, 2						//offset = ((i*2*N)+j)*4
				str 	w9, [ifReveal_arr, offset]				//store the value 0 to ifReveal array
				
				add 	j, j, 1									//j++
				cmp 	j, x10									//check if j reaches 2*N 
				b.lt 	reset_reveal							//if j is less than 2*N, continue to next round of loop
				
				add 	i, i, 1									//i++
				mov 	j, 0									//reset j to 0
				cmp 	i, x10									//check if i reaches 2*N
				b.lt  	reset_reveal							//if i is less than 2*N, continue to next round of loop
				
game_test: 		ldr 	x0, =new_line							//load new line string
				bl		printf									//print a new line
				
				ldr 	w9, reveal_num							//w9 = reveal_num
				mul 	x10, input_n, input_n					//x10 = N*N
				lsl 	x10, x10, 2								//x10 = 2*N*2*N
				sxtw 	x9, w9									//signed extended word
				cmp 	x9, x10									//chech if all the cards have been revealed
				b.eq  	done									//if all the cards have been revealed, end the loop
				
				ldr  	w9, score								//w9 = score
				cmp 	w9, 0									//chech if score has been reduced to less than 0
				b.le	done									//if score is negative, end the loop
				
print_score: 	ldr 	x0, =msg_score							//load the score message
				ldr 	w1, score								//load the socre
				bl 		printf									//print the score message
				
				ldr  	w9, reveal_num							//load the number of cards that have been revealed
				lsr 	w10, w9, 1								//x10 = reveal_num/2
				lsl		w11, w10, 1								//x11 = reveal_num/2*2
				
				cmp 	w9, w11									//check if the number of cards revealed is odd
				b.eq 	print_board								//if the number of cards is even, skip print_target to continue

print_target: 	ldr 	x0, =msg_target							//load the target message
				mov 	w1, temp_card							//load the card that the player is currently looing for 
				bl 		printf									//print the target message
				
print_board:	bl 		display									//call the display function
				
prompt_guess: 	ldr 	x0, =msg_prompt_guess					//load the guess prompt message
				bl		printf									//print the prompt message
				
				ldr 	x0, =input_fmt							//load the input format
				ldr 	x1, =input								//load the address of input
				bl 		scanf									//call scanf to get the input string
				
				bl 		getchar									//clear buffer
				
				ldr 	x0, =input								//load the input string to x0
				ldr 	x1, =Q_input							//load the string "Q" to x1
				bl 		strcmp									//call the c function strcmp to see if input equals "Q"
				cmp 	x0, 0									//check if user input is 'Q'
				b.eq	done									//if user input is Q/q, end the game loop
					
				ldr 	x0, =input								//load the input string to x0
				ldr 	x1, =q_input							//load the string "q" to x1
				bl 		strcmp									//call the c function strcmp to see if input equals "q"
				cmp 	x0, 0									//check if user input is 'q'
				b.eq	done									//if user input is Q/q, end the game loop
				
				ldr 	x0, =input								//load the user input
				ldr 	x1, =guess_fmt							//load the format of coordinates
				ldr 	x2, =input_x							//load the address of input_x
				ldr		x3, =input_y							//load the address of input_y
				bl 		sscanf									//call sscanf
				
				cmp 	x0, 2									//check if input successfully
				b.lt	invalid_input							//if input not successful, go to invalid_input
				
				ldr 	w9, input_x								//load input_x
				cmp 	w9, 0									//check if x is less than 0
				b.lt	invalid_input							//if x is less than 0, prompt again
				
				ldr 	w9, input_y								//load input y
				cmp		w9, 0									//check if y is less than 0
				b.lt	invalid_input							//if y is less than 0, prompt again
					
				lsl 	x10, input_n, 1							//x10 = 2*N
				sub 	x10, x10, 1								//x10 = 2*N-1
				
				ldr 	w9, input_x								//load input_x
				sxtw 	x9, w9									//signed extend word
				cmp 	x9, x10									//check if x is equal or larger than 2*N
				b.gt 	invalid_input							//if x is equal or larger than 2*N, prompt again
				
				ldr 	w9, input_y								//load input y
				sxtw 	x9, w9									//signed extend word
				cmp 	x9, x10									//check if y is equal or larger than 2*N
				b.gt 	invalid_input							//if y is equal or larger than 2*N, prompt again
				
				b 		print_input								//if the input is valid, continue
				
invalid_input: 	ldr 	x0, =msg_invalid_input					//load the invalid input message to x0
				bl 		printf									//print the message
				b 		prompt_guess							//prompt again
				
print_input:	ldr 	x0, =display_input						//load the display input message
				ldr 	x1, input_x								//load the input x
				ldr 	x2, input_y								//load the input y
				bl 		printf									//print the input message
				
				lsl 	offset, input_n, 1						//offset = 2*N
				ldr 	w10, input_x							//load input_x to x10
				sxtw	x10, w10								//signed extend word
				ldr 	w11, input_y							//load input_y to x11
				sxtw	x11, w11								//signed extend word
				mul		offset, offset, x10						//offset = 2*N*x
				add 	offset, offset, x11						//offset = 2*N*x+y
				lsl 	offset, offset, 2						//offset = (2*N*x+y)*4
				
				ldr 	w10, [ifReveal_arr, offset]				//check if the selected card has been revealed
				
				cmp 	w10, 1									//check if the selected card has been revealed
				b.eq	already_reveal							//if already revealed, go to already_reveal
				
				b 		reveal_card								//if the card is not revealed, continue									
				
already_reveal: ldr 	x0, =msg_already_reveal					//load the already revealed message to x0
				bl 		printf									//print the already revealed message
				b 		prompt_guess							//prompt for a guess again
				
reveal_card:	mov 	w9, 1									//x9 = 1
				ldr 	w10, input_x							//x10 = input_x
				sxtw	x10, w10								//signed extend word
				ldr  	w11, input_y							//x11 = input_y
				sxtw	x11, w11								//signed extend word
				lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, x10						//offset = 2*N*x
				add 	offset, offset, x11						//offset = 2*N*x+y
				lsl 	offset, offset, 2						//offset = (2*N*x+y)*4
				str 	w9, [ifReveal_arr, offset]				//change the status of the selected card to revealed
				
				bl 		display									//display the board
				
check_turn:		ldr  	w9, reveal_num							//load the number of cards that have been revealed
				lsr 	w10, w9, 1								//x10 = reveal_num/2
				lsl		w11, w10, 1								//x11 = reveal_num/2*2
				cmp 	x9, x11									//check if the number of cards revealed is odd
				b.eq	reveal_even								//if it is even, continue
				b	  	reveal_odd								//if it is odd, print the target message
				
reveal_even: 	ldr 	w10, input_x							//x10 = input_x
				sxtw 	x10, w10								//signed extend word
				ldr  	w11, input_y							//x11 = input_y
				sxtw	x10, w10								//signed extend word
				lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, x10						//offset = 2*N*x
				add 	offset, offset, x11						//offset = 2*N*x+y
				lsl 	offset, offset, 2						//offset = (2*N*x+y)*4

				ldr 	temp_card, [board_arr, offset]			//load the selected card value to temp_card
				
				mov 	i, 0									//reset i to 0
				mov 	j, 0									//reset j to 0

match_loop:		lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, i						//offset = 2*N*i
				add 	offset, offset, j						//offset = 2*N*i+j
				lsl  	offset, offset, 2						//offset = (2*N*i+j)*4
				
				ldr 	w25, [board_arr, offset]				//load the card value to w25
				
				cmp 	w25, temp_card							//check if the value in x25 is equal to the temp_card value
				b.eq	check_if_match							//if the value in x25 is equal to the temp_card value, continue to check if it is a match card
				
match_test:		add 	j, j, 1									//j++
				
				lsl 	x9, input_n, 1							//x9 = 2*N
				cmp 	j, x9									//check if j has reached 2*N
				b.lt 	match_loop								//if j is less than 2*N, continue next loop
				
				add 	i, i, 1									//i++
				mov 	j, 0									//reset j to 0
				b 		match_loop								//go back to match_loop to continue searching
				
check_if_match: ldr 	w9, input_x								//load the input x value
				sxtw  	x9, w9									//signed extend word
				
				cmp 	i, x9									//check if x equal to i
				b.gt	set_match								//if x is not equal to i, it is a match
				
				cmp 	i, x9									//check if x equal to i
				b.lt	set_match								//if x is not equal to i, it is a match
				
				ldr 	w9, input_y								//load the input y value
				sxtw 	x9, w9									//signed extend word
				
				cmp 	j, x9									//check if y equal to j
				b.gt 	set_match								//if y is not equal to j, it is a match
				cmp 	j, x9									//check if y equal to j
				b.lt 	set_match								//if y is not equal to j, it is a match
				
				b		match_test								//if both x and y are equal to i and j, it is the same card, continue to loop

set_match:		mov 	match_x, i								//set the x of the matched card
				mov 	match_y, j								//set the y of the matched card	
				
				ldr 	w9, reveal_num							//x9 = reveal_num
				add 	w9, w9, 1								//x9 = reveal_num+1
				adrp 	x10, reveal_num							//calculate the address of reveal_num
				add 	x10, x10, :lo12:reveal_num				//address is in x10
				str 	w9, [x10]								//reveal_num++
				
				b 		game_test								//continue to next round of game loop
				
reveal_odd: 	ldr 	w9, input_x								//load input x to w9
				sxtw 	x9, w9									//signed extend word
				ldr 	w10, input_y							//load input y to w10
				sxtw 	x10, w10								//signed extend word
				lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, x9						//offset = 2*N*x
				add 	offset, offset, x10						//offset = 2*N*x+y
				lsl 	offset, offset, 2						//offset = (2*N*x+y)*4
				ldr 	w11, [board_arr, offset]				//load the chosen card value to w11
				
				cmp 	w11, temp_card							//check if the chosen card is a match for the previously chosen one
				b.eq	correct_guess							//if it is a match, go to correct_guess to continue
				
wrong_guess: 	mov 	w9, 0									//x9 = 0
				ldr 	w10, input_x							//x10 = input_x
				sxtw 	x10, w10								//signed extend word
				ldr  	w11, input_y							//x11 = input_y
				sxtw	x11, w11								//signed extend word
				lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, x10						//offset = 2*N*x
				add 	offset, offset, x11						//offset = 2*N*x+y
				lsl 	offset, offset, 2						//offset = (2*N*x+y)*4
				str 	w9, [ifReveal_arr, offset]				//change the status of the selected card to unrevealed
				
				ldr 	w9, score								//load the score to x9
				sub 	w9, w9, 1								//x9 = score-1
				adrp 	x10, score								//calculate the address of score
				add 	x10, x10, :lo12:score					//address is in x10
				str 	w9, [x10]								//score--
				
				bl 		find_distance							//call the fine_distance function
				
				mov 	distance, x0							//store the distance
				
				ldr 	x0, =msg_hint							//load the hint message
				mov 	x1, distance							//load the distance
				bl 		printf									//print the hint message
				
				ldr		x0, =msg_pause							//load the pause message
				bl 		printf									//print the pause message
				
				bl 		getchar									//call the getchar function to continue
				b 		game_test								//continue to next game loop
				
correct_guess:	ldr 	x0, =msg_correct_guess					//load the correct guess message
				bl 		printf									//print the message
				
				ldr 	w9, reveal_num							//load the number of revealed cards
				add 	w9, w9, 1								//add 1 to the number of revealed cards
				adrp 	x10, reveal_num							//calculate the address of reveal_num
				add 	x10, x10, :lo12:reveal_num				//calculate the address of reveal_num
				str		w9, [x10]								//reveal_num++
				
				ldr 	w9, score								//load the score to x9
				add 	w9, w9, w19								//x9 = score+N
				adrp 	x10, score								//calculate the address of score
				add 	x10, x10, :lo12:score					//address is in x10
				str 	w9, [x10]								//score = score + N
				
				ldr 	x0, =new_line							//load the new line control character
				bl 		printf									//print the new line
				
				b 		game_test								//go to game_test to check if continue to next game loop
				
done: 			ldr 	x0, =msg_game_over						//load the game over message
				bl 		printf									//print the game over message
				
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				ldr 	x0, =msg_name_report					//load the report name message
				ldr		x1, [x9]								//load the name
				bl 		printf									//print the message
				
				ldr 	x0, =msg_score_report					//load the socre report message
				ldr 	w1, score								//load the score
				bl 		printf									//print the message

				bl 		log_file								//go to log_file to write the log file
				
				mul 	x9, input_n, input_n					//x9 = N*N
				lsl 	x9, x9, 2								//x9 = 2*N*2*N
				lsl 	x9, x9, 2								//x9 = (2*N*2*N)*4
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9,	x10 							//x9 = -(2*N*2*N)*4
				mov 	x11, -16								//x10 = -16
				and 	x9, x9, x11								//quadword align
				mul 	x9, x9, x10								//negate the amount
				add 	sp, sp, x9								//deallocate the memory for ifReveal array
				
				mul 	x9, input_n, input_n					//x9 = N*N
				lsl 	x9, x9, 2								//x9 = 2*N*2*N
				lsl 	x9, x9, 2								//x9 = (2*N*2*N)*4
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9,	x10 							//x9 = -(2*N*2*N)*4
				mov 	x11, -16								//x10 = -16
				and 	x9, x9, x11								//quadword align
				mul 	x9, x9, x10								//negate the amount
				add 	sp, sp, x9								//deallocate the memory for board array
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
			
display: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr 	x0, =msg_title							//load the title of board array
				bl 		printf									//print the title
				
				mov 	i, 0									//reset i to 0
				mov 	j, 0									//reset j to 0
				
dis_loop:		lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, i						//offset = 2*N*i 
				add 	offset, offset, j						//offset = 2*N*i+j
				lsl 	offset, offset, 2						//offset = (2*N*i+j)*4
				
				ldr 	w9, [ifReveal_arr, offset]				//load the value of element (i,j) of the ifReveal array to x9
				sxtw 	x9, w9									//signed extend word
				cmp 	x9, 0									//check if the card has been revealed
				b.eq	dis_unreaveal							//if the card is not revealed, go to dis_unreaveal to display an X
				
				ldr  	x0, =revealed							//load the revealed format to x0
				ldr  	x1, [board_arr, offset]					//give x1 the card value
				bl 		printf									//print the card
				
				b 		dis_test								//go to dis_test to continue
				
dis_unreaveal: 	ldr 	x0, =unrevealed							//load the format of unrevealed card to x0 
				bl 		printf									//print the unrevealed "X"
				
dis_test: 		add 	j, j, 1									//j++
				lsl 	x9, input_n,1							//x9 = 2*N
				cmp		j, x9									//check if j reaches 2*N
				b.lt 	dis_loop								//if j is less than 2*N, go back to dis_loop to continue
				
				add  	i, i, 1									//i++
				mov		j, 0									//reset j to 0
				
				ldr 	x0, =new_line							//load the format of newline control character to x0
				bl 		printf									//print the new line

				lsl 	x9, input_n,1							//x9 = 2*N
				cmp 	i, x9									//check if i reaches 2*N
				b.lt	dis_loop								//if i is less than 2*N, go back to dis_loop to continue
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
initialize: 	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mul 	x9, input_n, input_n					//x9 = N*N
				lsl 	x9, x9, 1								//x9 = 2*N*N
				
				mov		x23, x9									//x23 = 2*N*N
				
				lsl 	x9, x9, 2								//x9 = 4*2*N*N
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//x9 = -4*2*N*N
				
				and 	x9, x9, q_align							//quadword align
				
				add 	sp, sp, x9								//allocate memory for card array
				
				mov 	x22, sp									//give the base address of card array to x22
				
				mov 	i, 0									//reset i to 0
				
ini_loop:		lsl 	offset, i, 2							//offset = 4*i
				str 	w27, [x22, offset]						//store the value i to the ith card in the card array
				
				add 	i, i, 1									//i++
				cmp 	i, x23									//check if i reaches 2*N*N
				b.lt	ini_loop								//if i is less than 2*N*N, go back of ini_loop to continue
				
				bl		shuffle									//call the shuffle function
				
				mov 	i, 0									//reset i to 0
				mov 	j, 0									//reset j to 0
				
copy_1st_half: 	lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, i						//offset = 2*N*i
				add 	offset, offset, j						//offset = 2*N*i+j
				lsl 	offset, offset, 2						//offset = (2*N*i+j)*4
				
				ldr 	w9, [x22, offset]						//load the (i,j) element in cards array to x9
				
				str 	w9, [board_arr, offset]					//store the card to board array
				
				add 	j, j, 1									//j++
				lsl 	x9, input_n, 1							//x9 = 2*N
				
				cmp 	j, x9									//check if j reaches 2*N
				b.lt 	copy_1st_half							//if j is less than 2*N, go to copy_1st_half to continue
				
				add 	i, i, 1									//i++
				mov 	j, 0									//reset j to 0
				cmp 	i, input_n								//check if i reaches N
				b.lt 	copy_1st_half							//if i is less than N, go to copy_1st_half to continue
				
				bl		shuffle									//call shuffle function
				
				mov 	i, 0									//reset i to 0
				mov 	j, 0									//reset j to 0
				
copy_2nd_half: 	lsl 	offset, input_n, 1						//offset = 2*N
				mul 	offset, offset, i						//offset = 2*N*i
				add 	offset, offset, j						//offset = 2*N*i+j
				lsl 	offset, offset, 2						//offset = (2*N*i+j)*4
				
				ldr 	w9, [x22, offset]						//load the (i,j) element in cards array to x9
				
				lsl 	x10, x23, 2								//x10 = 2*N*N*4
				add 	offset, offset, x10						//point to second half of the board array
				
				str 	w9, [board_arr, offset]					//store the card to board array
				
				add 	j, j, 1									//j++
				lsl 	x9, input_n, 1							//x9 = 2*N
				cmp 	j, x9									//check if j reaches 2*N
				b.lt 	copy_2nd_half							//if j is less than 2*N, go to copy_2nd_half to continue
				
				add 	i, i, 1									//i++
				mov 	j, 0									//reset j to 0
				cmp 	i, input_n								//check if i reaches N
				b.lt 	copy_2nd_half							//if i is less than N, go to copy_2nd_half to continue
				
				lsl 	x9, x23, 2								//x9 = 2*N*N*4
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//x9 = -2*N*N*4
				and 	x9, x9, q_align							//quadword align
				mul 	x9, x9, x10								//dealloc = -alloc
				
				add		sp, sp, x9								//deallocate the memory for card array
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
shuffle: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	i, 0									//reset i to 0
				mov		j, 0									//reset j to 0
				
shuff_loop:		sub 	x9, x23, 1								//x9 = 2*N*N-1
				mov 	x0, x9									//set first argument(upper bound)
				bl 		randNum									//call the randNum function to generate a random number
				
				mov 	j, x0									//use j to store the random number
				
				bl 		swap									//call the swap function to swap the two cards
				
				add 	i, i, 1									//i++
				sub 	x9, x23, 2								//x9 = 2*N*N-2
				cmp 	i, x9									//check if i reaches 2*N*N-2
				b.lt	shuff_loop								//if i is less than 2*N*N-2, go to shuff_loop to continue
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
swap: 			stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
		
				lsl 	offset, i, 2							//offset = i*4, point to the ith card
				ldr 	w9, [x22, offset]						//load the value of ith card to w9	
				
				lsl 	offset, j, 2							//offset = j*4, point to the jth card	
				ldr 	w10, [x22, offset]						//load the value of jth card to w10
				
				mov 	w11, w10								//give the jth card value to x11
				str 	w9, [x22, offset]						//store the ith card to the jth place
				
				lsl 	offset, i, 2							//offset = i*4, point to the ith card
				str 	w11, [x22, offset]						//store the jth card to ith place

				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
randNum: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	x24, x0									//x24 = 2*N*N-1, max
				
				mov 	x0, 0									//clear the x0 register
				bl 		clock									//get the current time
				bl 		srand									//use the current time as the seed for generating random number
				bl 		rand									//generate random number
				mov 	x9, x0									//store the generated random number to the x9 register
				
				sub 	x10, x24, i								//x10 = max-min
				add 	x10, x10, 1								//x10 = max-min + 1
				
				udiv	x11, x9, x10							//x11 = randNum/(max-min+1)
				mul 	x12, x11, x10							//x11 = randNum/(max-min+1) * (max-min+1)
				sub		x13, x9, x12					    	//get the result of randNum%(max-min+1)
				add 	x0, x13, i								//x0 = randNum%(max-min+1)+min
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
find_distance:	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp 									//save state
				
				ldr 	w9, input_x								//load input x to x21
				sxtw	x9, w9									//signed extend word
				
				
				sub 	x0, match_x, x9							//x0 = match_x - input_x
				bl 		abs										//call the abs function to get the absolute distance
				mov 	x27, x0									//store the x distance in x27
			
				ldr 	w9, input_y								//load input y to x22
				sxtw 	x9, w9									//signed extend word
				
				sub 	x0, match_y, x9							//x0 = match_y - input_y
				bl 		abs										//call the abs function to get the absolute distance
				mov 	x28, x0									//store the y distance in x28
				
				
				cmp 	x27, x28								//compare x distance and y distance
				b.gt	x_distance								//if x distance is greater or equal to y distance, return x distance
				b.eq 	x_distance								//if x distance is greater or equal to y distance, return x distance
				b.lt	y_distance								//if x distance is lesser than y distance, return y distance
				
x_distance: 	mov		x0, x27									//give the value of x distance to x0
				b 		return_dis								//go to return_dis to finish the function
				
y_distance: 	mov 	x0, x28									//give the value of y distance to x0

return_dis: 	ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state

log_file: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
					
				ldr		x0, =file_name							//load the log file name
				ldr 	x1, =open_mode							//load the open mode
				bl 		fopen									//call the c fopen function
				
				mov 	x21, x0									//store the file pointer to x21
				
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				ldr 	x10, [x9]								//load the address of name to x9
				
				mov		x0, x21									//give the file pointer to x0
				ldr		x1, =msg_name_report					//load the format of name report
				mov		x2, x10									//load the name
				bl		fprintf									//call the c fprintf function
				
				mov 	x0, x21									//give the file pointer to x0
				ldr		x1, =msg_score_report					//load the format of score report
				ldr 	x2, score								//load the score
				bl 		fprintf									//call the c fprintf function
				
				mov 	x0, x21									//give the file pointer to x0
				bl 		fclose									//call the c fclose function
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				