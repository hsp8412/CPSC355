/*	Name: Sipeng He
	UCID: 30113342
	Tutorial: T03
	Date: June 23, 2021
	Program: MindMaster in assembly
	Features:
	-user can specify the size of the game board by using command line parameters
	-random colors(alphabets) are generated and assigned to the game board grids
	-take guesses from user
	-give hint, score, time and other information to users
	-finished the game or not, an entry will be created to the logfile.log
	-for each game ends with win or loss, a transcript is created, the name of which is the player's name and time it was created
	-user can choose to see the top n scores and bottom n scores at the begining and the end of each game
	-some level of input validation is provided
*/

define(hidden_code_r, x19)
define(trials_r, x20)
define(response_r, x21)
define(tempboard_r, x22)
define(buf_base_r, x24)
define(fd_r, w25)
define(i_r, x26)
define(j_r, x27)
define(offset_r, x28)
define(fp, x29)
define(lr, x30)


.data
input: 			.word 0											//store the input code
pos_infi: 		.dword 999999999								//positive infinite
flag_quit: 		.dword 0										//flag to indicate that the player choose to quit
flag_timeup: 	.dword 0										//flag to indicate that the time is used up
flag_failed: 	.dword 0										//flag to indicate that the player failed to crack the code
flag_cracked: 	.dword 0										//flag to indicate that the hidden code has been cracked
name: 			.dword 0										//player name
N: 				.dword 0										//number of rows
M: 				.dword 0										//number of columns
C: 				.dword 0										//number of colors
R: 				.dword 0										//limitation for number of trials
mode: 			.dword 0										//game mode
trial_count: 	.dword 0										//record the number of trials made
B: 				.dword 0										//number of matches
W: 				.dword 0										//number of mismatches
time_limit: 	.dword 0										//time limitation
timer: 			.dword 0										//record the time remaining 
previous_time: 	.dword 0										//record previous time
time_used: 		.dword 0										//the time used
trans_time: 	.dword 0										//time the transcript is made
trans_name: 	.dword 0										//name of transcript file
line: 			.dword 0										//the line read
entry_num: 		.dword 0										//number of entries required by the user
entry_count: 	.dword 0										//record the number of entries in logfile
two: 			.double 0r2.0									//2
one_thousand: 	.double 0r1000.0								//1000
score: 			.double 0r0.0									//record the score
minus_one: 		.double 0r-1.0									//-1
neg_infi: 		.double 0r-99999999.0							//negative infinite
q_align 	= 		-16											//quadword align
buf_size 	= 		8											//buffer size																	
alloc 		= 		-(16 + buf_size) & -16						//amount of memory to allocate for buffer
dealloc 	= 		-alloc										//amount of memory to deallocate for buffer
buf_s 		= 		16											//used to calculate the buf_base address
AT_FDCWD 	= 		-100										//current working directory

.text
msg_inv_exit:	.string 	"Invalid arguments in the command line. Please try again!\n"											//invalid command line argument message
msg_hello: 		.string		"Hello %s!\n"																							//hello message
msg_play_mode:	.string 	"Running MasterMind in play mode\n"																		//play mode message
msg_test_mode: 	.string 	"Running MasterMind in test mode\n"																		//test mode message
msg_start: 		.string 	"Start Cracking......\n"																				//start cracking message
hidden_title: 	.string 	"Hidden Code is: \n"																					//hidden code title
fmt_pt_code: 	.string 	"%c "																									//format to print a char and a space
fmt_pt_code_t:	.string 	"%c\t"																									//format to print a char and a tab
fmt_pt_hint_d: 	.string 	"%ld\t"																									//format to print long int
fmt_pt_hint_lf: .string 	"%.2lf\t"																								//format to print score
fmt_pt_hint_T:  .string  	"%d:%02d\n"																								//print time format
fmt_newline:	.string 	"\n"																									//new line
hyphen_space:	.string 	"- "																									//hyphen and space
hyphen_tab:		.string 	"-\t"																									//hyphen and tab
hint_header: 	.string 	"B\tW\tR\tS\tT\n"																						//header of response array
fmt_input: 		.string 	"%c"																									//format to get a char
msg_inv_input:	.string 	"Invalid input. Please try again!\n"																	//invalid input message
fmt_clear: 		.string 	"%*[^\n]%*c"																							//clear buffer
msg_quit:		.string 	"You chose to quit. Game over.\n"																		//quit message
msg_cracked: 	.string 	"Cracked!\n"																							//cracked message
msg_failed:		.string 	"You lost!\n"																							//fail to crack the code message
msg_timeup:		.string 	"Time's up!\n"																							//time up message
msg_score: 		.string 	"Final score: %.2lf\n"																					//report score format
msg_timeUsed: 	.string 	"Time(seconds): %d\n"																					//report time format
msg_name: 		.string 	"Name: %s\n"																							//report name format
fname_log:		.string 	"logfile.txt"																							//logfile name
msg_log_fail:	.string 	"Fail to open the log file.\n"																			//fail to open log file
fmt_log_name:	.string 	"Name: "																								//word to write in the logfile
fmt_log_score:	.string 	"Score: "																								//word to write in the logfile
fmt_log_time: 	.string 	"Time: "																								//word to write in the logfile
fmt_int:		.string 	"%d"																									//format to get an int
fmt_long_int:	.string 	"%ld"																									//format to get a long int
fmt_trans_time:	.string 	"%H-%M-%S-"																								//format to get the time from the raw time struct
open_mode: 		.string  	"a+"																									//append mode for fopen
file_type: 		.string 	".txt"																									//type of transcript file
read_mode: 		.string 	"r"																										//read mode for fopen
read_name: 		.string 	"Name: %s"																								//format to read name from file
read_score: 	.string 	"Score: %lf"																							//format to read score from file
read_time: 		.string 	"Time: %d"																								//format to read time from file
msg_top_fail: 	.string 	"There aren't so many entries in the log file!\n"														//request entry number too big
msg_btm_fail: 	.string 	"There aren't so many entries with score not equal to negative infinite in the log file!\n"				//request entry number too big
msg_trans_fail:	.string 	"Failed to create the transcript file!\n"																//fail to create transcript file
interface1:		.string 	"Please select one from the following options:\n"														//user interface message
interface2: 	.string 	"T - Display the top scores\n"																			//user interface message
interface3: 	.string 	"B - Display the bottom scores\n"																		//user interface message
interface4: 	.string 	"C - Continue to the game\n"																			//user interface message
interface5: 	.string 	"Your choice: "																							//prompt for a choice
interface6: 	.string 	"The number of entries you want to see: "																//prompt for entry number
interface7: 	.string 	"Invalid input! Input number should be greater than 0.\n\n"												//invalid input for entry numbers
interface8: 	.string 	"E - End the game\n"																					//user interface message				
debug: .string "The result is %d\n"
.balign 4														//ensure alignment
.global main													//makes main visible to the linker

main: 			stp		fp, lr, [sp, -16]!						//save state				
				mov 	fp, sp									//save state
				
				cmp 	x0, 7									//check if there are enough arguments in the command line
				b.lt	invalid_exit							//if there aren't enough arguments in the command line, exit the game
				
				ldr 	x19, [x1, 8]							//load the first argument(name)
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				str 	x19, [x9]								//store the name
				
				ldr 	x19, [x1, 16]							//load the second argument(N)
				ldr 	x20, [x1, 24]							//load the third argument(M)
				ldr 	x21, [x1, 32]							//load the fourth argument(C)
				ldr 	x22, [x1, 40]							//load the fifth argument(R)
				ldr 	x23, [x1, 48]							//load the sixth argument(mode)
				
				mov 	x0, x19									//x0 = N
				bl 		atoi									//call the C function atoi to convert N to int
				adrp 	x9, N									//calculate the address of N
				add 	x9, x9, :lo12:N							//calculate the address of N
				str 	x0, [x9]								//store N
				
				mov 	x0, x20									//x0 = M
				bl 		atoi									//call the C function atoi to convert M to int
				adrp 	x9, M									//calculate the address of M
				add 	x9, x9, :lo12:M							//calculate the address of M
				str 	x0, [x9]								//store M
				
				mov 	x0, x21									//x0 = C
				bl 		atoi 									//call the C funtion atoi to convert C to int
				adrp 	x9, C									//calculate the address of C
				add 	x9, x9, :lo12:C							//calculate the address of C
				str 	x0, [x9]								//store C
				
				mov  	x0, x22									//x0 = R
				bl 		atoi									//call the C funtion atoi to covert R to int
				adrp 	x9, R									//calculate the address of R
				add 	x9, x9, :lo12:R							//calculate the address of R
				str 	x0, [x9]								//store R
				
				mov  	x0, x23									//x0 = mode
				bl 		atoi									//call the C funtion atoi to convert mode to int
				adrp 	x9, mode								//calculate the address of mode
				add 	x9, x9, :lo12:mode						//calculate the address of mode
				str 	x0, [x9]								//store mode
				
				ldr 	x9, N									//load N
				cmp 	x9, 1									//check if N is larger than or equal to 1
				b.lt 	invalid_exit							//if N is less than 1, exit
				
				ldr 	x9, M									//load M
				cmp 	x9, 1									//check if M is larger than or equal to 1
				b.lt 	invalid_exit							//if M is less than 1, exit
				
				ldr 	x9, C									//load C
				cmp 	x9, 5									//check if C is larget than or equal to 5
				b.lt 	invalid_exit							//if C is less than 5, exit
				cmp 	x9, 24									//check if C is larger than 24
				b.gt	invalid_exit							//if C is larger than 24, exit
				
				ldr 	x9, R									//load R
				cmp 	x9, 1									//check if R is larger than or equal to 1
				b.lt 	invalid_exit							//if R is less than 1, exit
				
				ldr 	x9, M									//load M
				ldr 	x10, C									//load C
				cmp 	x9, x10									//check if M is less than C
				b.gt 	invalid_exit							//if M is greater than C, exit
				
				ldr		x9, mode								//load mode
				cmp 	x9, 0									//check if mode is equal to 0
				b.ne	check_mode								//if mode is not equal to 0, continue to check mode
				
				b		interface								//if mode is equal to 0, mode is valid

check_mode: 	ldr 	x9, mode								//load mode
				cmp 	x9, 1									//check if mode is equal to 1
				b.ne	invalid_exit							//if mode is not equal to 1, exit
				b 		interface								//if mode is equal to 1, mode is valid
				
invalid_exit: 	ldr 	x0, =msg_inv_exit						//load the invalid argument exit message
				bl 		printf									//print the message
				b 		exit									//exit
				
interface:		ldr 	x0, =interface1							//load interface message
				bl		printf									//print
				ldr 	x0, =interface2							//load interface message
				bl		printf									//print
				ldr 	x0, =interface3							//load interface message
				bl		printf									//print
				ldr 	x0, =interface4							//load interface message
				bl		printf									//print
				ldr 	x0, =interface5							//load interface message
				bl		printf									//print
				
get_input:		bl		getchar									//get an input from user
				
				mov 	x9, x0									//give the input to x9
				cmp 	x9, 'T'									//if input = 'T'
				b.eq	show_top								//show top scores
				
				cmp 	x9, 't'									//if input = 't'
				b.eq	show_top								//show top scores
				
				cmp 	x9, 'B'									//if input = 'B'
				b.eq 	show_btm								//show bottom scores
				
				cmp 	x9, 'b'									//if input = 'b'
				b.eq 	show_btm								//show bottom scores
				
				cmp		x9, 10									//if input = '\n'
				b.eq 	get_input								//get the next input
				
				b 		arrays_ini								//if the input is not T/t or B/b, continue to game
				
show_top:		ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x0, =interface6							//load the interface message
				bl		printf									//print
				
				ldr 	x0, =fmt_long_int						//load the format to get number of entries from user
				ldr 	x1, =entry_num							//load the address of entry_num
				bl		scanf									//get the entry_num
				
				ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x9, entry_num							//x9 = entry_num
				cmp 	x9, 0									//check if entry_num is valid
				b.le	inv_entry_num							//if it is less than or equal to 0, it is invalid
				
				bl 		display_top								//display top scores
				
				b 		arrays_ini								//continue to game
				
show_btm: 		ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone

				ldr 	x0, =interface6							//load the interface message
				bl		printf									//print
				
				ldr 	x0, =fmt_long_int						//load the format to get number of entries from user
				ldr 	x1, =entry_num							//load the address of entry_num
				bl		scanf									//get the entry_num
				
				ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x9, entry_num							//x9 = entry_num
				cmp 	x9, 0									//check if entry_num is valid
				b.le	inv_entry_num							//if it is less than or equal to 0, it is invalid
				
				bl 		display_btm								//display bottom scores
				
				b 		arrays_ini								//continue to game
				
inv_entry_num: 	ldr 	x0, =interface7							//load the interface message
				bl		printf									//print
				
				b 		interface								//go back to the interface
				
arrays_ini: 	ldr 	x9, N									//load N
				ldr 	x10, M									//load M
				mneg 	x9, x9, x10								//x9 = -N*M
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for hidden code array
				mov 	hidden_code_r, sp						//store the base address
				
				bl 		initialize								//call the initialize function
				
				ldr 	x9, N									//load N
				ldr 	x10, R									//load R
				mul 	x9, x9, x10								//x9 = N*R
				ldr 	x10, M									//x10 = M
				mneg 	x9, x9,	x10								//x9 = -N*R*M
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for trials array
				mov 	trials_r, sp							//store the base address
				
				ldr 	x9, R									//x9 = R
				mov 	x10, 5									//x10 = 5
				mul 	x9, x9, x10								//x9 = 5*R
				mov 	x10, 8									//x10 = 8
				mneg 	x9, x9, x10								//x9 = -5*R*8
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for response array
				mov 	response_r, sp							//store the base address
				
				ldr  	x9, N									//load N
				ldr 	x10, M									//load M
				mneg 	x9, x9, x10								//x9 = -N*M
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for temp board array
				mov 	tempboard_r, sp							//store the base address of temp board array
				
				mov 	x0, 0									//x0 = 0
				bl 		time									//get the current time
				
				mov 	x9, x0									//give the current time to x9										
				adrp 	x10, previous_time						//calculate the address of previous time
				add 	x10, x10, :lo12:previous_time			//calculate the address of previous time
				str 	x9, [x10]								//store the current time to previous_time
				
				ldr 	x9, N									//x9 = N
				mov 	x10, 5									//x10 = 5
				mul 	x9, x9, x10								//x9 = 5*N
				mov 	x10, 60									//x10 = 60
				mul 	x9, x9, x10								//x9 = 5*N*60
				adrp 	x10, timer								//calculate the address of timer
				add 	x10, x10, :lo12:timer					//calculate the address of timer
				str 	x9, [x10]								//store the value to timer		
				adrp 	x10, time_limit							//calculate the address of time_limit							
				add 	x10, x10, :lo12:time_limit				//calculate the address of time_limit
				str 	x9, [x10]								//store the value to time_limit

				ldr 	x0, =msg_hello							//load the hello message
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				ldr 	x1, [x9]								//load name
				bl 		printf									//print the hello message
													 
				ldr 	x10, mode								//load the mode flag
				cmp 	x10, 1									//check if mode = 1
				b.eq 	test_mode								//if mode = 1, test mode
				
				ldr 	x0, =msg_play_mode						//if mode != 1, load the play mode message
				bl 		printf									//print the play mode message
				b		start_msg								//go to start_msg to continue
				
test_mode: 		ldr		x0, =msg_test_mode						//load the test mode message
				bl		printf									//print the message
				
				bl 		print_hidden							//print the hidden code
				
start_msg: 		ldr 	x0, =msg_start							//load the start message
				bl 		printf									//print the message
				
				mov 	i_r, 0									//reset i to 0
				
hyphen_loop: 	ldr 	x0, =hyphen_space						//print the hyphens on the header
				bl 		printf									//print the hyphens
				
				add 	i_r, i_r, 1								//i++
				ldr 	x9, M									//x9 = M
				cmp 	i_r, x9									//check if i reaches M
				b.lt	hyphen_loop								//if i is less than M, continue the loop
				
				ldr 	x0, =hint_header						//load the hint header
				bl 		printf									//print the hint header
				
game_test:		ldr 	x9, timer								//load timer
				cmp 	x9, 0									//check if time is run up
				b.lt	set_timeup_flag							//if time is run up, set the timeup flag
				
				ldr 	x9, B									//load B
				ldr 	x10, N									//load N
				ldr 	x11, M									//load M
				mul 	x10, x10, x11							//x10 = N*M
				cmp 	x9, x10									//check if the hidden code has been cracked
				b.eq	set_crack_flag							//if the hidden code has been cracked, set the cracked flag

				ldr 	x9, trial_count							//load trial_count
				ldr 	x10, R									//load R
				cmp 	x9, x10									//check if trial_count has reached R
				b.eq 	set_fail_flag							//if trial_count has reached R, set the failed flag
				
				mov 	x9, 0									//x9 = 0
				adrp 	x10, B									//calculate the address of B
				add 	x10, x10, :lo12:B						//calculate the address of B
				str 	x9, [x10]								//reset B to 0
				
				mov 	x9, 0									//x9 = 0
				adrp 	x10, W									//calculate the address of W
				add 	x10, x10, :lo12:W						//calculate the address of W
				str 	x9, [x10]								//reset W to 0
				
				
game_loop: 		bl 		get_trial								//get the user input

				ldr 	x9, flag_quit							//load quit flag
				cmp 	x9, 1									//check if quit flag is set
				b.eq 	done									//if quit flag is set, end the game loop
				
				bl 		cal_response							//calculate the hints and response
					
				ldr 	x9, trial_count							//load trial_count
				add 	x9, x9, 1								//x9 = trial_count+1
				adrp 	x10, trial_count						//calculate the address of trial_count
				add 	x10, x10, :lo12:trial_count				//calculate the address of trial_count
				str 	x9, [x10]								//trial_count++
				
				bl 		display_hints							//display hints
				b 		game_test								//go to the game test to check if continue the game loop
				
set_crack_flag: adrp 	x9, flag_cracked						//calculate the address of flag_cracked
				add 	x9, x9, :lo12:flag_cracked				//calculate the address of flag_cracked
				mov 	x10, 1									//x10 = 1
				str 	x10, [x9]								//set the cracked flag
				
				b 		done									//end the game loop
				
set_fail_flag: 	adrp 	x9, flag_failed							//calculate the address of flag_failed
				add 	x9, x9, :lo12:flag_failed				//calculate the address of flag_failed
				mov 	x10, 1									//x10 = 1
				str 	x10, [x9]								//set the failed flag
				
				b  		done									//end the game loop
				
set_timeup_flag:adrp 	x9, flag_timeup							//calculate the address of flag_timeup
				add 	x9, x9, :lo12:flag_timeup				//calculate the address of flag_timeup
				mov 	x10, 1									//x10 = 1
				str 	x10, [x9]								//set the timeup flag
				
				b 		done									//end the game loop
				
done: 			bl 		cal_score								//calculate the score

				bl 		cal_timeUsed							//calculate the time used
				
				bl 		exit_game								//exit the game
				
				bl		log_score								//log the score
				
				bl		transcripe								//transcripe the game
				
				ldr  	x9, N									//load N
				ldr 	x10, M									//load M
				mneg 	x9, x9, x10								//x9 = -N*M
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value
				add 	sp, sp, x9								//deallocate the memory for temp board array

				ldr 	x9, R									//x9 = R
				mov 	x10, 5									//x10 = 5
				mul 	x9, x9, x10								//x9 = 5*R
				mov 	x10, 8									//x10 = 8
				mneg 	x9, x9, x10								//x9 = -5*R*8
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value in x9
				add 	sp, sp, x9								//deallocate the memory for response array
				
				ldr 	x9, N									//load N
				ldr 	x10, R									//load R
				mul 	x9, x9, x10								//x9 = N*R
				ldr 	x10, M									//x10 = M
				mneg 	x9, x9,	x10								//x9 = -N*R*M
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value in x9
				add 	sp, sp, x9								//deallocate the memory for trials array
				
				ldr 	x9, N									//load N
				ldr 	x10, M									//load M
				mneg 	x9, x9, x10								//x9 = -N*M
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value in x9
				add 	sp, sp, x9								//deallocate the memory for hidden code array
				
interface_e:	ldr 	x0, =interface1							//load interface message
				bl		printf									//print
				ldr 	x0, =interface2							//load interface message
				bl		printf									//print
				ldr 	x0, =interface3							//load interface message
				bl		printf									//print
				ldr 	x0, =interface8							//load interface message
				bl		printf									//print
				ldr 	x0, =interface5							//load interface message
				bl		printf									//print
				
get_input2:	 	bl		getchar									//get a user input 
				
				mov 	x9, x0									//give the input character to x0
				cmp 	x9, 'T'									//if it is 'T'
				b.eq	show_top2								//display top scores
				
				cmp 	x9, 't'									//if it is 't'
				b.eq	show_top2								//display top scores
				
				cmp 	x9, 'B'									//if it is 'B'
				b.eq 	show_btm2								//display bottom scores
				
				cmp 	x9, 'b'									//if it is 'b'
				b.eq 	show_btm2								//display bottom scores
				
				cmp		x9, 10									//if it is '\n'
				b.eq 	get_input2								//get the next input
				
				b 		exit									//if others, end the game
				
show_top2:		ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x0, =interface6							//load interface message
				bl		printf									//print
				
				ldr 	x0, =fmt_long_int						//load the format to get entry_num
				ldr 	x1, =entry_num							//load the address of entry_num
				bl		scanf									//get entry_num
				
				ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x9, entry_num							//load the entry number
				cmp 	x9, 0									//check if it is valid
				b.le	inv_entry_num2							//if it is less or equal to 0, invalid
				
				bl 		display_top								//display top scores
				
				b 		exit									//end
				
show_btm2: 		ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone

				ldr 	x0, =interface6							//load interface message
				bl		printf									//print
				
				ldr 	x0, =fmt_long_int						//load the format to get entry_num
				ldr 	x1, =entry_num							//load the address of entry_num
				bl		scanf									//get entry_num
				
				ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				ldr 	x9, entry_num							//load the entry number
				cmp 	x9, 0									//check if it is valid
				b.le	inv_entry_num2							//if it is less or equal to 0, invalid
				
				bl 		display_btm								//display bottom scores
				
				b 		exit									//end
				
inv_entry_num2:	ldr 	x0, =interface7							//load the invalid entry number message
				bl		printf									//print
				
				b 		interface_e								//go back to interface_e

exit:			ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
exit_game: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr 	x9, flag_quit							//load flag_quit
				cmp 	x9, 1									//check if quit flag is set
				b.eq	choose_quit								//if quit flag is set, go to choose_quit
				
				ldr 	x9, flag_cracked						//load flag_cracked
				cmp 	x9, 1									//check if cracked flag is set
				b.eq 	cracked_quit							//if cracked flag is set, go to cracked_quit
				
				ldr 	x9, flag_timeup							//load flag_timeup
				cmp 	x9, 1									//check if timeup flag is set
				b.eq 	timeup_quit								//if timeup flag is set, go to timeup_quit
				
				ldr 	x9, flag_failed							//load flag_failed
				cmp 	x9, 1									//check if failed flag is set
				b.eq 	failed_quit								//if failed flag is set, go to failed_quit
				
choose_quit: 	ldr 	x0, =msg_quit							//load the choose to quit message
				bl		printf									//print the message
					
				b		report_score							//finish exiting
				
cracked_quit: 	ldr 	x0, =msg_cracked						//load cracked message
				bl		printf									//print message
				
				b 		report_score							//go to report_score
				
timeup_quit: 	ldr 	x0, =msg_timeup							//load the timeup message
				bl 		printf									//print message
				
				b 		report_score							//go to report_score
				
failed_quit: 	ldr 	x0, =msg_failed							//load the failed message
				bl 		printf									//print the message
				
				b 		report_score							//go to report_score
				
report_score: 	ldr 	x0, =msg_score							//load the report score message
				ldr 	d0, score								//load the score
				bl		printf									//print the score

exit_done: 		ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state

				
cal_score: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr		x9, flag_quit							//load flag_quit
				cmp 	x9, 1									//check if flag_quit is set
				b.eq 	quit_score								//if flag_quit is set, go to quit_score
				
				ldr 	d8, score								//d8 = score
				ldr		x9, trial_count							//x9 = trial_count
				scvtf 	d9, x9									//d9 = trial_count
				ldr 	x9, timer								//x9 = timer
				scvtf	d10, x9									//d10 = timer
				fdiv 	d8, d8, d9								//d8 = score/trial_count
				fmul 	d8, d8, d10								//d8 = score/trial_count*timer
				ldr 	d9, one_thousand						//d9 = 1000.0
				fmul 	d8, d8, d9								//d8 = score/trial_count*timer*1000.0
				
				adrp 	x9, score								//calculate the address of score
				add 	x9, x9, :lo12:score						//calculate the address of score
				str 	d8, [x9]								//store the score
				
				ldr 	x10, flag_failed						//load flag_failed
				cmp 	x10, 1									//check if failed flag has been set
				b.eq	fail_score								//if failed flag has been set, go to fail_score
				
				b 		score_done								//finish calculating score

fail_score:		ldr 	d8, score								//load score
				ldr 	d9, minus_one							//load -1.0
				fmul 	d8, d8, d9								//negate the score
				
				adrp 	x9, score								//calculate the address of score
				add 	x9, x9, :lo12:score						//calculate the address of score
				str 	d8, [x9]								//str the negated score
				
				b 		score_done								//finish calculating score
				
quit_score: 	ldr 	d8, neg_infi							//load the negative infinity
				adrp 	x9, score								//calculate the address of score
				add 	x9, x9, :lo12:score						//calculate the address of score
				str 	d8, [x9]								//store the negative infinity as the score
				
score_done: 	ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state


cal_timeUsed: 	stp 	fp, lr, [sp, -16]!						//save state
				mov  	fp, sp									//save state
				
				ldr 	x9, flag_quit							//load flag_quit
				cmp		x9, 1									//check if quit flag has been set
				b.eq 	quit_timeUsed							//if quit flag has been set, go to quit_timeUsed
				
				ldr  	x9, time_limit							//load time_limit
				ldr 	x10, timer								//load timer
				sub		x9, x9, x10								//x9 = time_limit - timer
				adrp 	x10, time_used							//calculate the address of time_used
				add 	x10, x10, :lo12:time_used				//calculate the address of time_used
				str		x9, [x10]								//store the time_used
				b		timeUsed_done							//end the calculation for timeUsed
				
quit_timeUsed:	ldr 	x9, pos_infi							//load positive infinity
				adrp 	x10, time_used							//calculate the address of time_used
				add 	x10, x10, :lo12:time_used				//calculate the address of time_used
				str 	x9, [x10]								//store positive infinity as the time used
				
				b 		timeUsed_done							//finish calculation
				
timeUsed_done: 	ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
display_hints: 	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state

				ldr 	x0, =fmt_newline						//load the newline 
				bl 		printf									//print the newline
				
				mov 	i_r, 0									//reset i to 0
				
dis_hyphen:		ldr 	x0, =hyphen_space						//print the hyphens on the header
				bl 		printf									//print the hyphens
				
				add 	i_r, i_r, 1								//i++
				ldr 	x9, M									//x9 = M
				cmp 	i_r, x9									//check if i reaches M
				b.lt	dis_hyphen								//if i is less than M, continue the loop
				
				ldr 	x0, =hint_header						//load the hint header
				bl 		printf									//print the hint header
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0

pt_char_loop:	ldr 	offset_r, M								//offset = M				
				mul 	offset_r, offset_r, i_r					//offset = M*i
				add 	offset_r, offset_r, j_r					//offset = M*i+j
				
				ldr 	x0, =fmt_pt_code						//load the format of printing code
				ldrb 	w1, [trials_r, offset_r]				//load the character stored trials
				bl 		printf									//print the code
				
				add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, x9									//check if j reaches M
				b.lt 	pt_char_loop							//if j is less than M, continue the loop
				
				mov 	x9, i_r									//x9 = i
				add 	x9, x9, 1								//x9 = i+1
				ldr 	x10, N									//x10 = N
				udiv 	x11, x9, x10							//x11 = (i+1)/N
				mul 	x12, x11, x10							//x12 = ((i+1)/N)*N
				sub 	x12, x9, x12							//x12 = (i+1)-((i+1)/N)*N
				
				cmp 	x12, 0									//check if it is the right row to print the response message
				b.ne	next_line								//if it is not the right row to print the response message, print a new line
				
				mov 	offset_r, i_r							//offset = i	
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5*8
				
				ldr 	x0, =fmt_pt_hint_d						//load the format for printing int
				ldr 	x1, [response_r, offset_r]				//load the value of B
				bl 		printf									//print B
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 1					//offset = ((i+1)/N-1)*5+1
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+1))*8
				
				ldr 	x0, =fmt_pt_hint_d						//load the format of printing int
				ldr 	x1, [response_r, offset_r]				//load the value of W
				bl 		printf									//print W
				
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 2					//offset = ((i+1)/N-1)*5+2
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+2))*8
				
				ldr		x0, =fmt_pt_hint_d						//load the format of printing int
				ldr 	x1, [response_r, offset_r]				//load R
				bl 		printf									//print R
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 3					//offset = ((i+1)/N-1)*5+3
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+3))*8
				
				ldr 	x0, =fmt_pt_hint_lf						//load the format of printing double
				ldr 	d0, [response_r, offset_r]				//load S
				bl 		printf									//print S
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 4					//offset = ((i+1)/N-1)*5+4
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+4))*8
				
				ldr 	x9, [response_r, offset_r]				//load T
				cmp 	x9, 0									//check if remaining time is positive
				b.lt	timeup_zero								//if remaining time is negative
				
				mov 	x10, 60									//x10 = 60
				udiv 	x11, x9, x10							//x11 = T/60, which is the minute
				mul 	x12, x11, x10							//x12 = T/60*60
				sub 	x12, x9, x12							//x12 = T-T/60*60, which is the second
				
				ldr 	x0, =fmt_pt_hint_T						//load the format of printing T
				mov 	x1, x11									//load minute
				mov 	x2, x12									//load second
				bl 		printf									//print T
				
				b 		hint_loop_test							//go to the hint_loop_test to continue
				
timeup_zero:	ldr 	x0, =fmt_pt_hint_T						//load the format of printing T
				mov 	x1, 0									//load minute, which is 0 because time has been used up
				mov 	x2, 0									//load second, which is 0 because time has been used up
				bl 		printf									//print T

				b 		hint_loop_test							//go to the hint_loop_test to continue		
				
				
next_line: 		ldr 	x0, =fmt_newline						//load new line format
				bl 		printf									//print new line
				
				b 		hint_loop_test							//go to hint_loop_test to continue
				
hint_loop_test: add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				ldr 	x10, trial_count						//load trial_count
				mul 	x9, x9, x10								//x9 = N*trial_count
				cmp 	i_r, x9									//check if i reaches N*trial_count
				b.lt 	pt_char_loop							//if i is less than N*trial_count, continue the loop

				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state

cal_response: 	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0
				
copy_loop:		ldr 	offset_r, M								//offset = M
				mul 	offset_r, offset_r, i_r					//offset = i*M
				add 	offset_r, offset_r, j_r					//offset = i*M+j
				ldrb 	w9, [hidden_code_r, offset_r]			//load the corresponding hidden code
				strb 	w9, [tempboard_r, offset_r]				//store the hidden code to temp board array
				
				add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, x9									//check if j reaches M
				b.lt 	copy_loop								//if j hasn'r reached M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				cmp 	i_r, x9									//check if i reaches N
				b.lt 	copy_loop								//if i is less than N, continue the loop
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0
			
B_loop: 		ldr 	offset_r, trial_count					//offset = trial_count
				ldr 	x9, N									//load N
				mul 	offset_r, offset_r, x9					//offset = N*trial_count
				add 	offset_r, offset_r, i_r					//offset = N*trial_count+i 
				ldr 	x9, M									//load M
				mul 	offset_r, offset_r, x9					//offset = (N*trial_count+i)*M
				add 	offset_r, offset_r, j_r					//offset = (N*trial_count+i)*M+j
				
				ldrb 	w23, [trials_r, offset_r]				//load the input character
				
				ldr 	offset_r, M								//offset = M
				mul 	offset_r, offset_r, i_r					//offset = M*i
				add 	offset_r, offset_r, j_r					//offset = M*i+j
				
				ldrb 	w24, [tempboard_r, offset_r]			//load the hidden code
				
				cmp 	w23, w24								//compare if the trial charater and the hidden code matches
				b.eq 	match_found								//if it is a match
				
B_loop_test:	add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, X9									//check if j reaches M
				b.lt 	B_loop									//if j is less than M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				cmp 	i_r, x9									//check if i reaches N
				b.lt 	B_loop									//if i is less than N, continue the loop
				
				b 		W_calculate								//go to W_calculate to continue
				
match_found: 	ldr 	x9, B									//load B
				add 	x9, x9, 1								//add 1 to B
				
				adrp 	x10, B									//calculate the address of B
				add 	x10, x10, :lo12:B						//calculate the address of B
				str 	x9, [x10]								//B++
				
				mov 	w9, '0'									//w9 = '0'
				strb 	w9, [tempboard_r, offset_r]				//change the character on the temp board to '0' to inidicate that a match is found

				b 		B_loop_test								//go back to the loop_test to continue
				
W_calculate:	mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0

W_loop: 		ldr 	offset_r, M								//offset = M
				mul 	offset_r, offset_r, i_r					//offset = M*i
				add		offset_r, offset_r, j_r					//offset = M*i+j
				
				
				ldrb 	w9, [tempboard_r, offset_r]				//load the corresponding character in temp board to w9
				cmp 	w9, '0'									//check if the character is '0'
				b.eq	W_loop_test								//if the character is '0', go to W_loop_test to increment the indexes and continue
				
				ldr 	offset_r, trial_count					//offset = trial_count
				ldr 	x9, N									//load N
				mul 	offset_r, offset_r, x9					//offset = N*trial_count
				add 	offset_r, offset_r, i_r					//offset = N*trial_count+i 
				ldr 	x9, M									//load M
				mul 	offset_r, offset_r, x9					//offset = (N*trial_count+i)*M
				add 	offset_r, offset_r, j_r					//offset = (N*trial_count+i)*M+j
				
				ldrb 	w25, [trials_r, offset_r]				//load the corresponding character in trials
				
				
				mov 	x23, 0									//reset x23(u) to 0
				mov 	x24, 0									//reset x24(v) to 0
				
W_sub_loop: 	ldr 	offset_r, M								//offset = M
				mul 	offset_r, offset_r, x23					//offset = M*u
				add		offset_r, offset_r, x24					//offset = M*u+v
				
				ldrb 	w10, [tempboard_r, offset_r]			//load the corresponding character in temp board
				cmp 	w25, w10								//check if the characters are the same
				b.eq 	mis_match								//if it is the same, a mismatch is found
				

W_sub_test: 	add 	x24, x24, 1								//v++
				ldr 	x10, M									//load M
				cmp 	x24, x10								//check if v reaches M
				b.lt 	W_sub_loop								//if v is less than M, continue the loop
				
				add 	x23, x23, 1								//u++
				mov 	x24, 0									//reset v to 0
				ldr 	x10, N									//load N
				cmp 	x23, x10								//check if u reaches N
				b.lt 	W_sub_loop								//if u is less than N, continue the loop
				
				b  		W_loop_test								//sub_loop ends without a mismatch found, increment i, j

mis_match: 		ldr 	x10, W									//x10 = W
				add 	x10, x10, 1								//x10 = W+1
				adrp 	x11, W									//calculate the address of W
				add 	x11, x11, :lo12:W						//calculate the address of W
				str 	x10, [x11]								//W++
				
				mov 	w10, '1'								//w10 = '1'
				strb 	w10, [tempboard_r, offset_r]			//reset the corresponding letter in temp board to '1' to indicate that a mismatch is found
				
				b 		W_loop_test								//go to the W_loop_test to increment i,j
						
W_loop_test:	add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, x9									//check if j reaches M
				b.lt 	W_loop									//if j is less than M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				cmp 	i_r, x9									//check if i reaches N
				b.lt 	W_loop									//if i is less than N, continue the loop
				
				
				ldr 	offset_r, trial_count					//offset = trial_count
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = trial_count*5
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = trial_count*5*8
				ldr 	x9, B									//x9 = B
				str 	x9, [response_r, offset_r]				//store B to the corresponding place in response array
				
				
				
				ldr 	offset_r, trial_count					//offset = trial_count
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = trial_count*5
				add 	offset_r, offset_r, 1					//offset = trial_count*5+1
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (trial_count*5+1)*8
				ldr 	x9, W									//x9 = W
				str 	x9, [response_r, offset_r]				//store W to the corresponding place in response array
				
						
				
				ldr 	offset_r, trial_count					//offset = trial_count
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = trial_count*5
				add 	offset_r, offset_r, 2					//offset = trial_count*5+2
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (trial_count*5+2)*8
				ldr 	x9, trial_count							//x9 = trial_count
				add 	x9, x9, 1								//x9 = trial_count+1
				str 	x9, [response_r, offset_r]				//store the value of trial_count+1 to response array
				
				
				ldr 	offset_r, trial_count					//offset = trial_count
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = trial_count*5
				add 	offset_r, offset_r, 3					//offset = trial_count*5+3
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (trial_count*5+3)*8
				
				
				ldr 	x9, W									//x9 = W
				scvtf 	d8, x9									//d8 = W
				
				
				ldr 	d9, two									//d9 = 2.0
				fdiv	d8, d8, d9 								//d8 = W/2.0
				
				
				ldr 	x9, B									//x9 = B
				scvtf 	d9, x9									//d9 = B
				fadd 	d8, d8, d9								//d8 = W/2.0 + B
				
				
				ldr 	x9, trial_count							//x9 = trial_count
				add 	x9, x9, 1								//x9 = trial_count+1
				scvtf 	d9, x9									//d9 = trial_count+1
				fdiv 	d8, d8, d9								//d8 = (W/2.0 + B)/(trial_count+1)
				
				
				ldr 	d9, score								//d9 = score
				fadd 	d8, d8, d9								//d8 = score + (W/2.0 + B)/(trial_count+1)
				str 	d8, [response_r, offset_r]				//store the accumulated score to the response array
				adrp 	x9, score								//calculate the address of score
				add 	x9, x9, :lo12:score						//calculate the address of score
				str 	d8, [x9]								//store the new score
				
				
				
				ldr 	offset_r, trial_count					//offset = trial_count
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = trial_count*5
				add 	offset_r, offset_r, 4					//offset = trial_count*5+4
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (trial_count*5+4)*8
				
				mov 	x0, 0									//x0 = 0
				bl 		time									//get the current time
				mov 	x9, x0									//give the current time to x9
				ldr 	x10, previous_time						//load previous_time
				sub		x10, x9, x10							//x10 = current_time - previous_time, time_difference	
				ldr 	x11, timer								//load the timer
				sub 	x11, x11, x10							//x11 = timer - time_difference			
				
				adrp 	x12, timer								//calculate the address of timer
				add 	x12, x12, :lo12:timer					//calculate the address of timer
				str 	x11, [x12]								//store the new timer value
				
				adrp 	x12, previous_time						//calculate the address of previous_time
				add 	x12, x12, :lo12:previous_time			//calculate the address of previous_time
				str 	x9, [x12]								//store the current_time as the new previous_time
			
				str 	x11, [response_r, offset_r]				//store the timer to the response array
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
get_trial: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	i_r, 0									//i = 0
				mov 	j_r, 0									//j = 0
								
input_loop: 	ldr 	x0, =fmt_input							//load input format
				ldr 	w1, =input								//load the address of input
				bl 		scanf									//get the input character
				
				adrp 	x10, input								//calculate the address of input
				add 	x10, x10, :lo12:input					//calculate the address of input
				ldrb 	w9, [x10]								//load the input character
				
				cmp 	w9, '$'									//check if the user choose to quit
				b.eq 	set_quit_flag							//if user choose to quit, end the game loop
				
				cmp 	w9, ' '									//check if the input character is a space
				b.eq 	input_loop								//if it is a space, continue to next round of loop
				
				cmp 	w9, '\n'								//check if the input character is a newline control character
				b.eq 	input_loop								//if it is a newline control character, continue to next round of loop
				
				cmp 	w9, 'A'									//check if the ascii of input character is less than the ascii of 'A'
				b.lt	invalid_input							//if it is, input is invalid
			
				cmp 	w9, 'Z'									//check if the ascii of input character is greater than the ascii of 'Z'
				b.gt	invalid_input							//if it is, input is invalid
				
				ldr 	x10, N									//load N
				ldr 	x11, trial_count						//load trial_count
				mul 	offset_r, x10, x11						//offset = N*trial_count
				add 	offset_r, offset_r, i_r					//offset = N*trial_count+i
				ldr 	x10, M									//load M
				mul 	offset_r, offset_r, x10					//offset = (N*trial_count+i)*M
				add 	offset_r, offset_r, j_r					//offset = (N*trial_count+i)*M+j
				
				strb 	w9, [trials_r, offset_r]				//store the input character into trials array
				
				add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, x9									//check if j reaches M
				b.lt 	input_loop								//if j is less than M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				cmp 	i_r, x9									//check if i reaches N
				b.lt 	input_loop								//if i is less than N, continue the loop
				b		input_done								//loop end
				
				
invalid_input:	ldr 	x0, =msg_inv_input						//load invalid input message
				bl 		printf									//print the message
				mov 	j_r, 0									//reset j to 0
				
				ldr 	x0, =fmt_clear							//clear the buffer zone
				bl 		scanf									//clear the buffer zone
				
				b 		input_loop								//continue the loop
				
set_quit_flag: 	adrp	x9, flag_quit
				add 	x9, x9, :lo12:flag_quit
				mov 	x10, 1
				str 	x10, [x9]
				
input_done: 	ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
print_hidden: 	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr 	x0, =hidden_title						//load title message
				bl 		printf									//print title message
				
				mov 	i_r, 0									//reset i = 0
				mov 	j_r, 0									//reset j = 0
				
pt_hidden_loop:	mov 	offset_r, i_r							//offset = i
				adrp 	x9, M									//calculate the address of M
				add 	x9, x9, :lo12:M							//calculate the address of M
				ldr 	x10, [x9]								//x10 = M
				mul	 	offset_r, offset_r, x10					//offset = i*M
				add 	offset_r, offset_r, j_r					//offset = i*M + j
				
				ldr 	x0, =fmt_pt_code						//load the format of printing code
				ldrb 	w1, [hidden_code_r, offset_r]			//load the hidden code
				bl 		printf									//print the code
				
				add 	j_r, j_r, 1								//j++
				adrp 	x9, M									//calculate the address of M
				add 	x9, x9, :lo12:M							//calculate the address of M
				ldr 	x10, [x9]								//x10 = M
				cmp 	j_r, x10								//check if j reaches M
				b.lt 	pt_hidden_loop							//if j is less than M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				
				ldr 	x0, =fmt_newline						//load the new line format
				bl 		printf									//print the new line
				
				adrp 	x9, N									//calculate the address of N
				add 	x9, x9, :lo12:N							//calculate the address of N
				ldr 	x10, [x9]								//x10 = N
				cmp 	i_r, x10								//check if i reaches N
				b.lt 	pt_hidden_loop							//if i is less than N, continue the loop
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
	
				
initialize:  	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0
				
				
ini_loop:		mov 	x0, 0									//first argument
				mov 	x1, 100									//second argument
				mov 	x2, 0									//third argument
				
				bl 		randNum									//call the randNum function
				
				bl 		color									//call the color function
				
				mov 	offset_r, i_r							//offset = i
				ldr 	x10, M									//x10 = M
				mul 	offset_r, offset_r, x10					//offset = i*M
				add 	offset_r, offset_r, j_r					//offset = i*M + j
				
				strb 	w0, [hidden_code_r, offset_r]			//store the generated color to the corresponding place in hidden code array
				
				add 	j_r, j_r, 1								//j++
				ldr 	x10, M									//x10 = M
				
				cmp 	j_r, x10								//check if j reaches M
				b.lt 	ini_loop								//if j hasn't reached M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x10, N									//x10 = N
				cmp 	i_r, x10								//check if i reaches N
				b.lt 	ini_loop								//if i hasn't reached N, continue the loop
				
				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
	

randNum: 		stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	x20, x0									//x20 = min
				mov		x21, x1									//x21 = max
				mov 	x22, x2									//x22 = positive or negative
				
				mov 	x0, 0									//clear the x0 register
				bl 		clock									//get the current time
				bl 		srand									//use the current time as the seed for generating random number
				bl 		rand									//generate random number
				mov 	x9, x0									//store the generated random number to the x9 register
				
				sub 	x10, x21, x20							//x10 = max-min
				add 	x10, x10, 1								//x10 = max-min + 1
				
				udiv	x11, x9, x10							//x11 = randNum/(max-min+1)
				mul 	x11, x11, x10							//x11 = randNum/(max-min+1) * (max-min+1)
				sub		x9, x9, x11					    		//x9 = randNum%(max-min+1)
				add 	x9, x9, x20								//x9 = randNum%(max-min+1)+min
				
				cmp 	x22, 1									//compare the negative flag with 1
				b.eq	randNum_neg								//if the negative flag is 1, negate the random number generated
				b 		randNum_ret								//if it is not, return the random number
				
randNum_neg: 	mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the random number generated
				
randNum_ret:	mov 	x0, x9									//assign the random number to x0 to return it back

				ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
color: 			stp		fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				mov 	x9, x0									//x9 = randNum
				
				ldr 	x10, C									//x10 = C
				
				udiv   	x11, x9, x10							//x11 = randNum / C
				mul 	x11, x11, x10							//x11 = (randNum / C)*C
				sub 	x9, x9, x11								//x9 = randNum % C
				add 	x9, x9, 65								//x9 = randNum % C + 65(ascii of A)
				
				mov 	x0, x9									//x0 = color to return 
				
				stp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
log_score: 		stp		x29, x30, [sp, alloc]!					//save state
				mov 	x29, sp									//restore state
				
				mov 	w0, AT_FDCWD 							//dirfd, -100 means current directory
				ldr 	x1, =fname_log							//pathname, "logfile.txt" 			
				mov  	w2, 02 | 0100 | 02000 					//flags: read/write, create if not exist, append
				mov	 	w3, 0666								//mode, 0666 means rw for all
				mov 	x8, 56 									//openat I/O request
				svc 	0 										//call system function
				mov 	fd_r, w0 								//record file decriptor
				
				cmp 	fd_r, 0 								//check if the file has been opened properly
				b.ge 	openok									//if the file has been opened properly, start writing

				ldr 	x0, =msg_log_fail						//if failed to open the file, load the fail message
				bl 		printf									//print message
				mov 	w0, -1									//w0 = -1
				b 		exit_log								//exit the log file function

openok: 		add 	buf_base_r, x29, buf_s 					//calculate buf base
				
				adrp 	x9, fmt_log_name						//calculate the address of fmt_log_name
				add 	x9, x9, :lo12:fmt_log_name				//calculate the address of fmt_log_name
				
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 6 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				mov 	x0, 0									//x0 = 0
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				ldr 	x0, [x9]								//load name
				bl 		strlen									//calculate the length of the name string 
				
				mov 	w23, w0									//w23 = length of the string 
				
				ldr 	x9, =name								//load name
				mov 	w0, fd_r 								//fd
				ldr		x1, [x9] 		 						//buf
				mov		w2, w23 								//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	x9, =fmt_newline						//load the newline format 
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 1 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	x9, =fmt_log_score						//load the format for log score
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 7 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	d0, score								//load score to d0
				mov		w0, buf_size							//BUFSIZE
				mov 	x1, buf_base_r							//buf
				bl 		gcvt									//convert the double to a string
				
				mov		x0, 0									//x0 = 0
				mov		x0, buf_base_r							//buf
				bl		strlen									//calculate the length of the string
				mov		w23, w0									//store it in w23
				
				mov 	w0, fd_r 								//fd
				mov		x1, buf_base_r 							//buf
				mov		w2, w23 								//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	x9, =fmt_newline						//load the newline format
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 1 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	x9, =fmt_log_time						//load the format for log time
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 6 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
			
				ldr		x9, time_used							//load the time used
				mov	 	x0, buf_base_r							//buf
				mov		x1, buf_size							//BUFSIZE
				ldr 	x2, =fmt_int							//load the convert format
				mov 	x3, x9									//x3 = time_used
				bl 		snprintf								//convert the int to a string
				
				mov		x0, 0									//x0 = 0
				mov		x0, buf_base_r							//buf
				bl		strlen									//calculate the length of the string
				mov		w23, w0									//store the length of a string in w23
				
				mov 	w0, fd_r 								//fd
				mov		x1, buf_base_r 							//buf
				mov		w2, w23 								//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
				ldr 	x9, =fmt_newline						//load the newline format
				mov 	w0, fd_r 								//fd
				mov		x1, x9 		 							//buf
				mov		w2, 1 									//BUFSIZE
				mov 	x8, 64 									//write I/O request
				svc 	0 										//call system function
				
close_file:		mov		w0, fd_r								//w0 = fd
				mov		x8, 57									//close I/O request
				svc 	0										//call system function

exit_log:  		ldp		x29, x30, [sp], dealloc					//restore state
				ret												//restore state
				
transcripe: 	stp 	fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr 	x9, flag_quit							//load flag_quit
				cmp 	x9, 1									//check if quit flag is set
				b.eq	end_trans								//if quit flag is set, no transcript created
				
				adrp 	x9, trans_time							//calculate the address of trans_time
				add 	x9, x9, :lo12:trans_time				//calculate the address of trans_time
				mov 	x0, x9									//use trans_time to catch the time								
				bl		time									//get the time
				
				adrp 	x9, trans_time							//calculate the address of trans_time
				add 	x9, x9, :lo12:trans_time				//calculate the address of trans_time
				mov 	x0, x9							 		//raw time as an argument
				bl		localtime								//get the time struct
			
				mov  	x3, x0									//4th arg, original time struct
				adrp 	x9, trans_name							//calculate the address of trans_name
				add 	x9, x9, :lo12:trans_name				//calculate the address of trans_name
				mov  	x0, x9									//1st arg, destination string
				mov 	x1, 80									//2nd arg, maximum number of characters
				ldr 	x2, =fmt_trans_time						//3rd arg, format
				
				bl		strftime								//call the strftime method
			
				adrp 	x9, name								//calculate the address of name
				add 	x9, x9, :lo12:name						//calculate the address of name
				
				adrp 	x10, trans_name							//calculate the address of trans_name
				add		x10, x10, :lo12:trans_name				//calculate the address of trans_name
				
				mov  	x0, x10									//x0 = address of trans_name
				ldr 	x1, [x9]								//load name to x1
				bl 		strcat									//connect them together
				
				adrp 	x10, trans_name							//calculate the address of trans_name
				add		x10, x10, :lo12:trans_name				//calculate the address of trans_name
				
				mov  	x0, x10									//x0 = address of trans_name
				ldr 	x1, =file_type							//load file_type to x1
				bl 		strcat									//connect them together
				
				ldr 	x0, =trans_name							//load the name of the transcript
				ldr 	x1, =open_mode							//load the open mode
				bl 		fopen									//create a transcript file
				
				mov 	x24, x0									//fp 
				
				mov 	x0, x24									//fp
				ldr 	x1, =hidden_title						//load the title of the hidden code
				bl		fprintf									//print
				
				mov 	i_r, 0									//reset i = 0
				mov 	j_r, 0									//reset j = 0
				
hidden_loop_t:	mov 	offset_r, i_r							//offset = i
				adrp 	x9, M									//calculate the address of M
				add 	x9, x9, :lo12:M							//calculate the address of M
				ldr 	x10, [x9]								//x10 = M
				mul	 	offset_r, offset_r, x10					//offset = i*M
				add 	offset_r, offset_r, j_r					//offset = i*M + j
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_code_t						//load the format of printing code
				ldrb 	w2, [hidden_code_r, offset_r]			//load the hidden code
				bl 		fprintf									//print the code
				
				add 	j_r, j_r, 1								//j++
				adrp 	x9, M									//calculate the address of M
				add 	x9, x9, :lo12:M							//calculate the address of M
				ldr 	x10, [x9]								//x10 = M
				cmp 	j_r, x10								//check if j reaches M
				b.lt 	hidden_loop_t							//if j is less than M, continue the loop
				
				add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_newline						//load the new line format
				bl 		fprintf									//print the new line
				
				adrp 	x9, N									//calculate the address of N
				add 	x9, x9, :lo12:N							//calculate the address of N
				ldr 	x10, [x9]								//x10 = N
				cmp 	i_r, x10								//check if i reaches N
				b.lt 	hidden_loop_t							//if i is less than N, continue the loop
				
				mov 	i_r, 0									//reset i to 0
				
dis_hyphen_t:	mov 	x0, x24									//fp
				ldr 	x1, =hyphen_tab							//print the hyphens on the header
				bl 		fprintf									//print the hyphens
				
				add 	i_r, i_r, 1								//i++
				ldr 	x9, M									//x9 = M
				cmp 	i_r, x9									//check if i reaches M
				b.lt	dis_hyphen_t							//if i is less than M, continue the loop
				
				mov 	x0, x24									//fp
				ldr 	x1, =hint_header						//load the hint header
				bl 		fprintf									//print the hint header
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0

char_loop_t:	ldr 	offset_r, M								//offset = M				
				mul 	offset_r, offset_r, i_r					//offset = M*i
				add 	offset_r, offset_r, j_r					//offset = M*i+j
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_code_t						//load the format of printing code
				ldrb 	w2, [trials_r, offset_r]				//load the character stored trials
				bl 		fprintf									//print the code
				
				add 	j_r, j_r, 1								//j++
				ldr 	x9, M									//load M
				cmp 	j_r, x9									//check if j reaches M
				b.lt 	char_loop_t								//if j is less than M, continue the loop
				
				mov 	x9, i_r									//x9 = i
				add 	x9, x9, 1								//x9 = i+1
				ldr 	x10, N									//x10 = N
				udiv 	x11, x9, x10							//x11 = (i+1)/N
				mul 	x12, x11, x10							//x12 = ((i+1)/N)*N
				sub 	x12, x9, x12							//x12 = (i+1)-((i+1)/N)*N
				
				cmp 	x12, 0									//check if it is the right row to print the response message
				b.ne	next_line_t								//if it is not the right row to print the response message, print a new line
				
				mov 	offset_r, i_r							//offset = i	
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5*8
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_hint_d						//load the format for printing int
				ldr 	x2, [response_r, offset_r]				//load the value of B
				bl 		fprintf									//print B
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 1					//offset = ((i+1)/N-1)*5+1
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+1))*8
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_hint_d						//load the format of printing int
				ldr 	x2, [response_r, offset_r]				//load the value of W
				bl 		fprintf									//print W
				
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 2					//offset = ((i+1)/N-1)*5+2
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+2))*8
				
				mov 	x0, x24									//fp
				ldr		x1, =fmt_pt_hint_d						//load the format of printing int
				ldr 	x2, [response_r, offset_r]				//load R
				bl 		fprintf									//print R
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 3					//offset = ((i+1)/N-1)*5+3
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+3))*8
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_hint_lf						//load the format of printing double
				ldr 	d0, [response_r, offset_r]				//load S
				bl 		fprintf									//print S
				
				mov 	offset_r, i_r							//offset = i
				add 	offset_r, offset_r, 1					//offset = i+1
				ldr 	x9, N									//x9 = N
				udiv	offset_r, offset_r, x9					//offset = (i+1)/N
				sub 	offset_r, offset_r, 1					//offset = (i+1)/N-1
				mov 	x9, 5									//x9 = 5
				mul 	offset_r, offset_r, x9					//offset = ((i+1)/N-1)*5
				add 	offset_r, offset_r, 4					//offset = ((i+1)/N-1)*5+4
				mov 	x9, 8									//x9 = 8
				mul 	offset_r, offset_r, x9					//offset = (((i+1)/N-1)*5+4))*8
				
				ldr 	x9, [response_r, offset_r]				//load T
				cmp 	x9, 0									//check if remaining time is positive
				b.lt	timeup_zero_t							//if remaining time is not positive
				
				mov 	x10, 60									//x10 = 60
				udiv 	x11, x9, x10							//x11 = T/60, which is the minute
				mul 	x12, x11, x10							//x12 = T/60*60
				sub 	x12, x9, x12							//x12 = T-T/60*60, which is the second
				
				mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_hint_T						//load the format of printing T
				mov 	x2, x11									//load minute
				mov 	x3, x12									//load second
				bl 		fprintf									//print T
				
				b 		hint_test_t								//go to the hint_loop_test to continue

timeup_zero_t: 	mov 	x0, x24									//fp
				ldr 	x1, =fmt_pt_hint_T						//load the format of printing T
				mov 	x2, 0									//remaining time is 0
				mov 	x3, 0									//remaining time is 0
				bl 		fprintf									//print T			
						
				b 		hint_test_t								//go to the hint_loop_test to continue
				
next_line_t: 	mov 	x0, x24									//fp
				ldr 	x1, =fmt_newline						//load new line format
				bl 		fprintf									//print new line
				
				b 		hint_test_t								//go to hint_loop_test to continue
				
hint_test_t: 	add 	i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				ldr 	x9, N									//load N
				ldr 	x10, trial_count						//load trial_count
				mul 	x9, x9, x10								//x9 = N*trial_count
				cmp 	i_r, x9									//check if i reaches N*trial_count
				b.lt 	char_loop_t								//if i is less than N*trial_count, continue the loop
				
				ldr 	x9, flag_cracked						//load flag_cracked
				cmp 	x9, 1									//check if cracked flag is set
				b.eq 	cracked_quit_t							//if cracked flag is set, go to cracked_quit
				
				ldr 	x9, flag_timeup							//load flag_timeup
				cmp 	x9, 1									//check if timeup flag is set
				b.eq 	timeup_quit_t							//if timeup flag is set, go to timeup_quit
				
				ldr 	x9, flag_failed							//load flag_failed
				cmp 	x9, 1									//check if failed flag is set
				b.eq 	failed_quit_t							//if failed flag is set, go to failed_quit
				
cracked_quit_t: mov 	x0, x24									//fp
				ldr 	x1, =msg_cracked						//load cracked message
				bl		fprintf									//print message
				
				b 		report_score_t							//go to report_score
				
timeup_quit_t: 	mov		x0, x24									//fp
				ldr 	x1, =msg_timeup							//load the timeup message
				bl 		fprintf									//print message
				
				b 		report_score_t							//go to report_score
				
failed_quit_t: 	mov 	x0, x24									//fp
				ldr 	x1, =msg_failed							//load the failed message
				bl 		fprintf									//print the message
				
				b 		report_score_t							//go to report_score
				
report_score_t: mov 	x0, x24									//fp
				ldr 	x1, =msg_score							//load the report score message
				ldr 	d0, score								//load the score
				bl		fprintf									//print the score
				
				mov 	x0, x24									//give the file pointer to x0
				bl 		fclose									//call the c fclose function

end_trans:		ldp 	fp, lr, [sp], 16						//restore state
				ret												//restore state
				
display_top:	stp		fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				ldr  	x22, entry_num							//use x22 to store entry_num							
				mov 	x23, 0									//use x23 to store entry_count
				
				ldr 	x0, =fname_log							//load the file name
				ldr 	x1, =read_mode							//load the open mode
				bl		fopen									//open the file
				
				cmp 	x0, 0									//check if fp = null
				b.eq 	t_open_fail								//if fp = null, open failed
				
				mov 	x19, x0									//store fp in x19
				
				mov 	x9, -960								//x9 = -960
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for the structure
				mov 	x20, sp									//store the base address of the structure to x20
				
				
top_read_lp: 	ldr 	x0, =line								//load the address of line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				cmp 	x0, 0									//check if the reading finished
				b.eq 	top_check								//if the reading finished, break the loop
				
				mov 	offset_r, x23							//offset = entry_count
				mov		x9, 32									//x9 = 32
				mul		offset_r, offset_r, x9					//offset = entry_count*32
					
				ldr		x0, =line								//load the line
				ldr 	x1, =read_name							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
				
				ldr 	x0, =line								//load the line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				add 	offset_r, offset_r, 16					//offset = entry_count*32+16
				
				ldr		x0, =line								//load the line
				ldr 	x1, =read_score							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
				
				ldr 	x0, =line								//load the line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				add 	offset_r, offset_r, 8					//offset = entry_count*32+24
				
				ldr		x0, =line								//load the line
				ldr 	x1, =read_time							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
					
				add 	x23, x23, 1								//entry_count++
				
				b		top_read_lp								//continue the loop
				
top_check:		mov 	x9, -32									//x9 = -32
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for temp structure
				mov 	x21, sp									//store the base address of the temp structure in x21
				
				cmp		x22, x23								//check if the requested entry number is larger than the number of entries
				b.gt	top_fail								//if it is larger 
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0
				
				cmp 	x23, 1									//check if there is only one entry in the logfile
				b.eq 	top_sort_end							//if so, skip the sorting process

top_sort_lp: 	mov 	offset_r, j_r							//offset = j
				mov		x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				add 	offset_r, offset_r, 16					//offset = j*32+16
				
				ldr 	d8, [x20, offset_r]						//load the score of entry #j to d8
				
				mov 	offset_r, j_r							//offset = j
				add 	offset_r, offset_r, 1					//offset = j+1
				mov		x9, 32									//x9 = 48
				mul 	offset_r, offset_r, x9					//offset = (j+1)*32
				add 	offset_r, offset_r, 16					//offset = (j+1)*32+16
				
				ldr 	d9, [x20, offset_r]						//load the score of entry #j+1 to d9
				
				fcmp 	d8, d9									//compare the two scores
				b.le 	top_sort_test							//if score of #j is less than or equal to score of #j+1
				
				
				mov 	offset_r, j_r							//offset = j
				add 	offset_r, offset_r, 1					//offset = j+1
				mov		x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = (j+1)*32
				
				
				ldr 	x9,	[x20, offset_r]						//load the first 8 bytes of #j+1's name	
				str 	x9, [x21]								//store the first 8 bytes of #j+1's name in temp structure
				
				
				add 	offset_r, offset_r, 8					//offset = (j+1)*32+8
				ldr 	x9, [x20, offset_r]						//load the second 8 bytes of #j+1's name
				str 	x9, [x21, 8]							//store it in temp structure
				
				str 	d9, [x21, 16]							//store the #j+1's score in temp structure
				
				add 	offset_r, offset_r, 16					//offset = (j+1)*32+24
				ldr 	x9, [x20, offset_r]						//load the time of #j+1
				str		x9, [x21, 24]							//store it in temp structure
				
				mov 	offset_r, j_r							//offset = j
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				
				ldr 	x9, [x20, offset_r]						//load the first 8 bytes of #j's name
				add 	offset_r, offset_r, 32					//offset = (j+1)*32
				str 	x9, [x20, offset_r]						//store it in #j+1's structure
				
				sub 	offset_r, offset_r, 24					//offset = j*32+8
				ldr 	x9, [x20, offset_r]						//load the second 8 bytes of #j's name
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+8
				str 	x9, [x20, offset_r]						//store it in #j+1's structure
				
				sub 	offset_r, offset_r, 24					//offset = j*32+16
				ldr 	d8, [x20, offset_r]						//load the score of #j
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+16
				str 	d8, [x20, offset_r]						//store the score in #j+1
				
				sub 	offset_r, offset_r, 24					//offset = j*32+24
				ldr 	x9, [x20, offset_r]						//load the time of #j
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+24
				str 	x9, [x20, offset_r]						//store the time in #j+1
				
				mov 	offset_r, j_r							//offset = j
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				
				ldr 	x9, [x21]								//load the first 8 bytes of name in temp
				str		x9, [x20, offset_r]						//store the first 8 bytes of name in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+8
				ldr		x9, [x21, 8]							//load the second 8 bytes of name in temp
				str 	x9, [x20, offset_r]						//store the second 8 bytes of name in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+16
				ldr		d8, [x21, 16]							//load the score in temp
				str 	d8, [x20, offset_r]						//store the score in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+24
				ldr		x9, [x21, 24]							//load the time in temp
				str 	x9, [x20, offset_r]						//store the time in #j
					
top_sort_test: 	add 	j_r, j_r, 1								//j++
				
				sub 	x10, x23, i_r							//x10 = entry_count-i
				sub 	x10, x10, 1								//x10 = entry_count-i-1
				
				cmp 	j_r, x10								//check if j reaches the value in x10
				b.lt	top_sort_lp								//if not, continue the loop
				
				add		i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				
				cmp 	i_r, x23								//check if i reaches entry_count
				b.lt	top_sort_lp								//if not, continue the loop
				
top_sort_end:	mov 	i_r, x23								//i = entry_count
				sub 	i_r, i_r, 1								//i = entry_count - 1
				
pt_top_loop:	mov 	offset_r, i_r							//offset = i
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = i*32
				
				ldr 	x0, =fmt_newline						//load the new line format
				bl		printf									//print the new line
				
				ldr 	x0, =msg_name							//load the report name message
				add 	x1, x20, offset_r						//load the name
				bl 		printf									//print the message
				
				add 	offset_r, offset_r, 16					//offset = i*32+16
				
				ldr 	x0, =msg_score							//load the score report message
				ldr  	d0, [x20, offset_r]						//load the score
				bl		printf									//print
				
				add 	offset_r, offset_r, 8					//offset = i*32+24
				
				ldr 	x0, =msg_timeUsed						//load the time report message
				ldr 	x1, [x20, offset_r]						//load the time
				bl 		printf									//print
				
				ldr 	x0, =fmt_newline						//load the newline format
				bl		printf									//print 
				
pt_top_test:	sub 	i_r, i_r, 1								//i--
					
				sub 	x11, x23, x22							//x11 = entry_count-entry_num
				sub 	x11, x11, 1								//x11 = entry_count-entry_num-1
				
				cmp		i_r, x11								//check if i reaches the value of x11
				b.gt	pt_top_loop								//if not, continue the loop 
				
				b 		top_end									//end the display top function
				
top_fail: 		ldr 	x0, =msg_top_fail						//load the fail message
				bl		printf									//print
				
				b 		top_end									//end the function 

t_open_fail: 	ldr 	x0, =msg_log_fail						//load the failed
				bl		printf									//print
				
				b 		t_exit									//end
				
top_end:		mov 	x0, x19									//fp
				bl		fclose									//close file
				
				mov		x19, 0									//x19 = 0
				mov	 	x20, 0									//x20 = 0
				mov 	x21, 0									//x21 = 0
				mov 	x22, 0									//x22 = 0
				mov 	x23, 0									//x23 = 0
				
				mov 	x9, -32									//x9 = -32
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value
				add 	sp, sp, x9								//deallocate the memory for temp
				
				mov 	x9, -960								//x9 = -960
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value
				add 	sp, sp, x9								//deallocate the memory for structures
				
t_exit:			ldp		fp, lr, [sp], 16						//restore state
				ret												//restore state		

display_btm:	stp		fp, lr, [sp, -16]!						//save state
				mov 	fp, sp									//save state
				
				
				ldr  	x22, entry_num							//use x22 to store entry_num							
				mov 	x23, 0									//use x23 to store entry_count
				mov 	x24, 0									//use x24 to count entries that have scores larger than negative infinites
				
				ldr 	x0, =fname_log							//load the file name
				ldr 	x1, =read_mode							//load the open mode
				bl		fopen									//open the file
				
				cmp 	x0, 0									//check if fp = null
				b.eq 	b_open_fail								//if so, fail to open log file
				
				mov 	x19, x0									//store fp in x19
				
				mov 	x9, -960								//x9 = -960
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for the structure
				mov 	x20, sp									//store the base address of the structure to x20
				
				
btm_read_lp: 	ldr 	x0, =line								//load the address of line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				cmp 	x0, 0									//check if reaches the end of file
				b.eq 	btm_check								//if so, break the loop
				
				mov 	offset_r, x23							//offset = entry_count
				mov		x9, 32									//x9 = 32
				mul		offset_r, offset_r, x9					//offset = entry_count*32
				
				ldr		x0, =line								//load the line
				ldr 	x1, =read_name							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
				
				ldr 	x0, =line								//load the line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				add 	offset_r, offset_r, 16					//offset = entry_count*32+16
				
				ldr		x0, =line								//load the line
				ldr 	x1, =read_score							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
				
				ldr 	d9, [x20, offset_r]						//load the score of the entry
				ldr		d10, neg_infi							//load the value of negative infinite
				fcmp 	d9, d10									//compare the score and negative infinite
				b.eq	continue_btm							//if it equals, skip the fini_count
				
fini_count: 	add 	x24, x24, 1								//count the number of entries that finished the game
				
continue_btm:	ldr 	x0, =line								//load the line
				mov 	x1, 1000								//maximum number of characters
				mov 	x2, x19									//fp
				bl		fgets									//read a line
				
				add 	offset_r, offset_r, 8					//offset = entry_count*32+24
				
				ldr		x0, =line								//load the line
				ldr 	x1, =read_time							//load the read_name format
				add 	x2, x20, offset_r						//set the address
				bl 		sscanf									//call sscanf to get the name
				
				add 	x23, x23, 1								//entry_count++
				
				b		btm_read_lp								//continue the loop
				
btm_check:		mov 	x9, -32									//x9 = -32
				and 	x9, x9, q_align							//quadword align
				add 	sp, sp, x9								//allocate memory for temp structure
				mov 	x21, sp									//store the base address of the temp structure in x21
				
				cmp		x22, x24								//check if the requested entry number is larger than the number of finished entries
				b.gt	btm_fail								//if it is larger
				
				mov 	i_r, 0									//reset i to 0
				mov 	j_r, 0									//reset j to 0
				
				cmp 	x24, 1									//check if there is only 1 entry that not equal to negative infinite in the log file
				b.eq 	btm_sort_end							//if so, skip the sorting

btm_sort_lp: 	mov 	offset_r, j_r							//offset = j
				mov		x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				add 	offset_r, offset_r, 16					//offset = j*32+16
				
				ldr 	d8, [x20, offset_r]						//load the score of entry #j to d8
				
				mov 	offset_r, j_r							//offset = j
				add 	offset_r, offset_r, 1					//offset = j+1
				mov		x9, 32									//x9 = 48
				mul 	offset_r, offset_r, x9					//offset = (j+1)*32
				add 	offset_r, offset_r, 16					//offset = (j+1)*32+16
				
				ldr 	d9, [x20, offset_r]						//load the score of entry #j+1 to d9
				
				fcmp 	d8, d9									//compare the two scores
				b.ge 	btm_sort_test							//if score of #j is greater than or equal to score of #j+1
				
				
				mov 	offset_r, j_r							//offset = j
				add 	offset_r, offset_r, 1					//offset = j+1
				mov		x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = (j+1)*32
				
				
				ldr 	x9,	[x20, offset_r]						//load the first 8 bytes of #j+1's name	
				str 	x9, [x21]								//store the first 8 bytes of #j+1's name in temp structure
				
				
				add 	offset_r, offset_r, 8					//offset = (j+1)*32+8
				ldr 	x9, [x20, offset_r]						//load the second 8 bytes of #j+1's name
				str 	x9, [x21, 8]							//store it in temp structure
				
				str 	d9, [x21, 16]							//store the #j+1's score in temp structure
				
				add 	offset_r, offset_r, 16					//offset = (j+1)*32+24
				ldr 	x9, [x20, offset_r]						//load the time of #j+1
				str		x9, [x21, 24]							//store it in temp structure
				
				mov 	offset_r, j_r							//offset = j
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				
				ldr 	x9, [x20, offset_r]						//load the first 8 bytes of #j's name
				add 	offset_r, offset_r, 32					//offset = (j+1)*32
				str 	x9, [x20, offset_r]						//store it in #j+1's structure
				
				sub 	offset_r, offset_r, 24					//offset = j*32+8
				ldr 	x9, [x20, offset_r]						//load the second 8 bytes of #j's name
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+8
				str 	x9, [x20, offset_r]						//store it in #j+1's structure
				
				sub 	offset_r, offset_r, 24					//offset = j*32+16
				ldr 	d8, [x20, offset_r]						//load the score of #j
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+16
				str 	d8, [x20, offset_r]						//store the score in #j+1
				
				sub 	offset_r, offset_r, 24					//offset = j*32+24
				ldr 	x9, [x20, offset_r]						//load the time of #j
				add 	offset_r, offset_r, 32					//offset = (j+1)*32+24
				str 	x9, [x20, offset_r]						//store the time in #j+1
				
				mov 	offset_r, j_r							//offset = j
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = j*32
				
				ldr 	x9, [x21]								//load the first 8 bytes of name in temp
				str		x9, [x20, offset_r]						//store the first 8 bytes of name in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+8
				ldr		x9, [x21, 8]							//load the second 8 bytes of name in temp
				str 	x9, [x20, offset_r]						//store the second 8 bytes of name in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+16
				ldr		d8, [x21, 16]							//load the score in temp
				str 	d8, [x20, offset_r]						//store the score in #j
				
				add 	offset_r, offset_r, 8					//offset = j*32+24
				ldr		x9, [x21, 24]							//load the time in temp
				str 	x9, [x20, offset_r]						//store the time in #j
				
btm_sort_test: 	add 	j_r, j_r, 1								//j++
				
				sub 	x10, x23, i_r							//x10 = entry_count-i
				sub 	x10, x10, 1								//x10 = entry_count-i-1
				
				cmp 	j_r, x10								//check if j reaches the value in x10
				b.lt	btm_sort_lp								//if not, continue the loop
				
				add		i_r, i_r, 1								//i++
				mov 	j_r, 0									//reset j to 0
				
				cmp 	i_r, x23								//check if i reaches entry_count
				b.lt	btm_sort_lp								//if not, continue the loop
				
btm_sort_end:	mov 	i_r, x24								//i = positive_count
				sub 	i_r, i_r, 1								//i = positive_count - 1				
				
				
pt_btm_loop:	mov 	offset_r, i_r							//offset = i
				mov 	x9, 32									//x9 = 32
				mul 	offset_r, offset_r, x9					//offset = i*32
				
				ldr 	x0, =fmt_newline						//load the newline
				bl		printf									//print
				
				ldr 	x0, =msg_name							//load the report name message
				add 	x1, x20, offset_r						//load the name
				bl 		printf									//print the message
				
				add 	offset_r, offset_r, 16					//offset = i*32+16
				
				ldr 	x0, =msg_score							//load the score report message
				ldr  	d0, [x20, offset_r]						//load the score
				bl		printf									//print
				
				add 	offset_r, offset_r, 8					//offset = i*32+24
				
				ldr 	x0, =msg_timeUsed						//load the time report message
				ldr 	x1, [x20, offset_r]						//load the time
				bl 		printf									//print
				
				ldr 	x0, =fmt_newline						//load newline
				bl		printf									//print
				
pt_btm_test:	sub 	i_r, i_r, 1								//i--
				
				sub 	x11, x24, x22							//x11 = positive_count-entry_num
				sub 	x11, x11, 1								//x11 = positive_count-entry_num-1
				
				cmp		i_r, x11								//check if i reaches the value of x11
				b.gt	pt_btm_loop								//if not, continue the loop 
				
				b 		btm_end									//end the display btm function
				
btm_fail: 		ldr 	x0, =msg_btm_fail						//load the fail message
				bl		printf									//print
				
				b 		btm_end									//end the function
				
b_open_fail: 	ldr 	x0, =msg_log_fail						//load the open failed message
				bl		printf									//print
			
				b 		b_exit									//end the function
				
btm_end:		mov 	x0, x19									//fp
				bl		fclose									//close file
				
				mov		x19, 0									//x19 = 0
				mov	 	x20, 0									//x20 = 0
				mov 	x21, 0									//x21 = 0
				mov 	x22, 0									//x22 = 0
				mov 	x23, 0									//x23 = 0
				
				mov 	x9, -32									//x9 = -32
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value
				add 	sp, sp, x9								//deallocate the memory for temp
					
				mov 	x9, -960								//x9 = -960
				and 	x9, x9, q_align							//quadword align
				mov 	x10, -1									//x10 = -1
				mul 	x9, x9, x10								//negate the value
				add 	sp, sp, x9								//deallocate the memory for structures
				
b_exit:			ldp		fp, lr, [sp], 16						//restore state
				ret												//restore state
				
				
				
				