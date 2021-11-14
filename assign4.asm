/*
Name: Sipeng He
UCID: 30113342
Tutorial: T03
Date: May 8, 2021
Program Features:
-get an input dimension value N from the command line
-if the input N in command line is not valid, or it is missing, prompt the user for it
-generate the initial N*N array, each element of the array is a structure of two ints, x and y
-fill the array with randomly generated positive numbers that are less than 100
-print the initial array in the form of (x,y)
-print the x and y matrix seperately
-calculate the product matrix of x and y matrix
-print the product matrix
-calculate the sum, max and min value of the product matrix
-store the sum, max and min value of the product matrix in a structure
-print the sum, max and min information of the product matrix in the end
*/


define(temp1, w10)
define(temp2, w11)
define(temp3, x12)
define(array_n, x19)
define(arr1_base, x20)
define(offset, x21)
define(i, x22)
define(j, x23)
define(k, x24)
define(element, w25)
define(arr2_base, x26)
define(summary_base, x27)
define(alloc, x28)
define(fp, x29)
define(lr, x30)

.data
n: .word 0									//receive the input N 

.text
prompt: .string "Please enter a valid N: "					//prompt message for a valid N
input: .string "%ld"								//input format of N
msg_xy: .string "The initial array(x,y):\n"					//title message for the (x,y) matrix
msg_x: .string "The x array:\n"							//title message for the x matrix
msg_y: .string "The y array:\n"							//title message for the y matrix
msg_pro: .string "The product matrix:\n"					//title message for the product matrix
output1: .string "(%d,%d)\t"							//output format for the (x,y) matrix
output2: .string "%d\t"								//output format for the x and y matrix
new_line: .string "\n"								//format of newline control character
msg_sum: .string "The sum of product matrix: %d\n"				//message of sum of product array
msg_max: .string "The max of product matrix: %d\n"				//message of max of product array
msg_min: .string "The min of product matrix: %d\n"				//message of min of product array

.balign 4									//ensure alignment
.global main									//makes main visible to the linker

main:				stp 	fp, lr, [sp, -16]!			//save states
				mov 	fp, sp					//save states
				
				cmp 	w0, 2					//check if the command line contains an N input(2 arguments)
				b.lt	inputN					//if N is missing, prompt the user for it 
				
				mov  	array_n, x1				//get the address of command line arguments
				ldr 	x0, [array_n, 8]			//load the 2nd(N in string) argument to x0
				bl 	atoi					//call the c function atoi to change N from string to int value
				mov 	array_n, x0				//get the int N value
				b 	input_test				//go to input_test to check the validity
		
inputN:				ldr 	x0, =prompt				//load the prompt message to x0
				bl 	printf					//print the prompt message
		
				ldr 	x0, =input				//load the input format to x0
				ldr 	x1, =n					//use n to catch the input N
				bl 	scanf					//get an input N from the user
				ldr 	array_n, n				//load the input N to x19
		
input_test:			cmp 	array_n, 0				//check if the input N value is positive
				b.le 	inputN					//if negative or equal to 0, prompt for an input again
				
				mul	alloc, array_n, array_n			//alloc = N*N
				lsl	alloc, alloc, 3				//alloc = N*N*8
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//alloc = -N*N*8
				
				and 	alloc, alloc, -16			//clear the first 4 bits to ensure quadword align
				
				add	sp, sp, alloc				//allocate memory for the N*N array, the element of each cell is two ints(x and y)
				
				mov 	arr1_base, sp				//set the base address of array
				mov 	offset, 0				//initialize the offset value
				mov 	i, 0					//initialize the i value for loop
				mov 	j, 0					//initialize the j value for loop
				
randNum1:			mov 	w0, 0					//clear the w0 register
				bl 	clock					//get the current time
				bl 	srand					//use the current time as the seed for generating random number
				bl 	rand					//generate random number
				mov 	element, w0				//store the generated random number to the x25 register

downsize1: 			mov 	temp1, 100				//temp1 = 100
				udiv	temp2, element, temp1			//temp2 = randNum/100
				mul 	temp2, temp2, temp1			//temp2 = randNum/100 * 100
				sub	element, element, temp2			//get the result of randNum%100	
				
	 			str	element, [arr1_base, offset]		//assign the number to the x of (i,j)
				add	offset, offset, 4			//let the offset point to the memory that stores y of (i,j)
				
randNum2:			mov 	w0, 0					//clear the w0 register
				bl 	clock					//get the current time
				bl 	srand					//use the current time as the seed for generating random number
				bl 	rand					//generate random number
				mov 	element, w0				//store the generated random number to the x25 register
				
downsize2: 			mov 	temp1, 100				//temp1 = 100
				udiv 	temp2, element, temp1			//temp2 = randNum/100
				mul 	temp2, temp2, temp1			//temp2 = randNum/100 * 100
				sub	element, element, temp2			//get the result of randNum%100
				
				str	element, [arr1_base, offset]		//assign the random number to the y of (i,j)
				add	offset, offset, 4			//let the offset point to the memory that stores the x of next element
				
				add	j, j, 1					//increment j
				cmp	j, array_n				//check if j reaches N
				b.lt	randNum1				//if j is less than N, return to the randNum1 to fill next cell in the row
			
				add	i, i, 1					//increment i
				mov	j, 0					//set j to 0
				cmp 	i, array_n				//check if i reaches N
				b.lt 	randNum1				//if i is less than N, return to the randNum1 to fill the next cell in the next row
				
				mov	i, 0					//reset i to 0
				mov 	j, 0					//reset j to 0
				mov 	offset, 0				//reset offset to 0
				
				ldr 	x0, =msg_xy				//load the title message of the (x,y) array to x0
				bl 	printf					//print the titlem message
				
print_ele:			ldr 	w0, =output1				//load output format to w0
				ldr 	w1, [arr1_base, offset]			//load the x to w1
				add	offset, offset, 4			//let the offset point to y
				ldr	w2, [arr1_base, offset]			//load the y to w2
				add	offset, offset, 4			//let the offset point to next element
				bl 	printf					//print the element
				
				add	j, j, 1					//increment j
				
				cmp	j, array_n				//check if j has reached N
				b.lt	print_ele				//if j is less than N, go back to print_ele to print next element in the line
				
				ldr	w0, =new_line				//if j is not less than N, load the new line control character to w0
				bl 	printf					//print the new line control character
				
				add 	i, i, 1					//increment i
				mov	j, 0					//reset j to 0
				cmp	i, array_n				//check if i has reached N
				b.lt	print_ele				//if i is less than N, go back to print_ele to print the next line of elements
				
				mov	i, 0					//reset i to 0
				mov 	j, 0					//reset j to 0
				mov 	offset, 0				//reset offset to 0	
				
				ldr	x0, =msg_x				//load the title message of x matrix to x0
				bl	printf					//print the title message

print_x:			ldr 	w0, =output2				//load the output format of x matrix to w0
				ldr 	w1, [arr1_base, offset]			//load the element x of a cell to w1
				bl 	printf					//print the x
				add 	offset, offset, 8			//let the offset point to the next x
				
				add 	j, j, 1					//increment j
				cmp 	j, array_n				//check if j reaches N
				b.lt	print_x					//if j is less than N, go back to print_x to print the next x in the same row
				
				ldr 	x0, =new_line				//if j is not less than N, load the newline control character to x0
				bl 	printf					//print the newline control character
				
				add 	i, i, 1					//increment i
				mov 	j, 0					//reset j to 0
				cmp 	i, array_n				//check if i reaches N
				b.lt	print_x					//if i is less than N, go back to print_x to print the next x in the next row
				
				mov 	i, 0					//reset i to 0
				mov 	j, 0					//reset j to 0
				mov	offset, 4				//reset offset to 4 to print y matrix
				
				ldr	x0, =msg_y				//load the title message of y matrix to x0
				bl 	printf					//print the title message

print_y:			ldr 	w0, =output2				//load the output format of y matrix to w0
				ldr 	w1, [arr1_base, offset]			//load the element y of a cell to w1
				bl	printf					//print the element y
				add 	offset, offset, 8			//let offset point to the next y
				
				add 	j, j, 1					//increment j
				cmp 	j, array_n				//check if j reaches N
				b.lt	print_y					//if j is less than N, go back to print_y to print the next y in the same row
					
				ldr	x0, =new_line				//if j is not less than N, load the newline control character to x0
				bl 	printf					//print the newline control character
				
				add 	i, i, 1					//increment i
				mov	j, 0					//reset j to 0
				cmp 	i, array_n				//check if i reaches N
				b.lt	print_y					//if i is less than N, go back to the print_y to print the next y in the next row
				
				mul	alloc, array_n, array_n			//alloc = N*N
				lsl	alloc, alloc, 2				//alloc = N*N*4
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//alloc = -N*N*4
				
				and 	alloc, alloc, -16			//clear the first 4 bits to ensure quadword align
				
				add	sp, sp, alloc				//allocate memory for the N*N product array
				
				mov 	arr2_base, sp				//set the base address of the product array
				mov 	offset, 0				//initialize the offset value
				mov 	i, 0					//initialize the i value for loop
				mov 	j, 0					//initialize the j value for loop
				mov 	k, 0					//initialize the k value for loop
				mov 	element, 0				//reset the element register
				
multi:				mul	offset, i, array_n			//offset = i*N
				add	offset, offset, k			//offset = (i*N)+k
				lsl 	offset, offset, 3			//offset = ((i*N)+k)*8
				
				ldr 	temp1, [arr1_base, offset]		//load an x of a cell in the specific row to temp1
				
				mov	offset, 0				//reset offset to 0
				mul 	offset, k, array_n			//offset = k*N
				add	offset, offset, j			//offset = (k*N)+j
				lsl 	offset, offset, 3			//offset = ((k*N)+j)*8
				add 	offset, offset, 4			//offset = ((k*N)+j)*8+4
				
				ldr	temp2, [arr1_base, offset]		//load an y of a cell in the specific column to temp2
				
				mul	temp1, temp1, temp2			//temp1 = temp1*temp2
				add	element, element, temp1			//add the value of temp1 to element
				
				add	k, k, 1					//increment k
				cmp 	k, array_n				//check if k reaches N
				b.lt 	multi					//if k is less than N, return to multi to continue calculate the value of a cell in product matrix
				
				mul	offset, i, array_n			//if k is not less than N, calculate the offset for the corresponding cell in product matrix
				add	offset, offset, j			//offset = (i*N)+j
				lsl 	offset, offset, 2			//offset = ((i*N)+j)*4
				
				str	element, [arr2_base, offset]		//store the cell value to the corresponding address
				mov 	element, 0				//set element to 0 to calculate next cell
				
				add	j, j, 1					//increment j
				mov	k, 0					//reset k to 0
				cmp	j, array_n				//check if j reaches N
				b.lt 	multi					//if j is less than N, go back to multi to calculate next cell value in the same row of the product matrix
				
				add 	i, i, 1					//increment i
				mov	j, 0					//reset j to 0
				cmp 	i, array_n				//check if i reaches N
				b.lt  	multi					//if i is less than N, go back to multi to calculate next cell value in the next row of the product matrix
				
				mov 	i, 0					//reset i to 0
				mov 	j, 0					//reset j to 0
				mov 	offset, 0				//reset offset to 0
				
				ldr 	x0, =msg_pro				//load the product matrix message
				bl 	printf					//print the product matrix message
				
product_disp:			ldr 	element, [arr2_base, offset]		//load a element in the product matrix
				add 	offset, offset, 4			//set the offset to point to the next element
				ldr 	x0, =output2				//load the output format
				mov	w1, element				//assign the element to w1 to print it out
				bl 	printf					//print the element 
				
				add 	j, j, 1					//increment j
				cmp	j, array_n				//check if j reaches N
				b.lt	product_disp				//if j is less than N, go back to product_disp to print the next cell in the same row
				
				add 	i, i, 1					//if j is larger than N, increment i
				mov 	j, 0					//reset j to 0
				
				ldr 	x0, =new_line				//load the newline control charater to x0
				bl 	printf					//print the newline control character
							
				cmp 	i, array_n				//check if i reaches N
				b.lt 	product_disp				//if i is less than N, go to product_disp to print next cell in the next row
				
				mov	alloc, -12				//the summary structure contains 3 ints, and it needs 12 bytes of memory
				and 	alloc, alloc, -16			//ensure quadword alignment
				
				add 	sp, sp, alloc				//allocate the memory for summary structure
				mov 	summary_base, sp
				
				mov 	i, 0					//reset i to 0
				mov 	j, 0					//reset j to 0
				mov	offset, 0				//reset offset to 0
				
				
				mov 	element, 0				//reset element register to 0
				str	element, [summary_base, 0]		//assign the initial value 0 to sum
				ldr 	element, [arr2_base, offset]		//load the value of the first cell to element
				str	element, [summary_base, 4]		//assign the initial value to max
				str 	element, [summary_base, 8]		//assign the initial value to min
				
sum_loop:			ldr 	element, [arr2_base, offset]		//load an element in the product matrix
				add 	offset, offset, 4			//let the offset point to the next cell
				ldr	temp1, [summary_base, 0]		//load the sum value to temp1
				add	temp1, temp1, element			//add the element value to sum value
				str 	temp1, [summary_base, 0]		//store the sum value back
				
				ldr 	temp1, [summary_base, 4]		//load the max value to temp1
				cmp	element, temp1				//check if the element value is larger than the max value
				b.gt	update_max				//if larger than the max value, update max value
				b 	check_min				//if not larger than the max value, jump to check_min to continue

update_max:			str 	element, [summary_base, 4]		//store the element value as the new max value
				
check_min:			ldr 	temp1, [summary_base, 8]		//load the min value to temp1
				cmp	element, temp1				//check if the element value is less than the min value
				b.lt	update_min				//if less than the min value, update min value
				b	sum_test				//if not less than the min value, jump to sum_test to continue
				
update_min: 			str 	element, [summary_base, 8]		//store the element value as the new min value

sum_test:			add 	j, j, 1					//increment j
				cmp 	j, array_n				//check if j reaches N
				b.lt	sum_loop				//if j is less than N, go back to sum_loop to check the next cell in the same row of product matrix
				
				add 	i, i, 1					//if j is not less than N, increment i
				mov	j, 0					//reset j to 0
				cmp 	i, array_n				//check if i reaches N
				b.lt	sum_loop				//if i is less than N, go back to sum_loop to check the next cell in the next line of the product matrix
				
print_sum:			ldr 	x0, =msg_sum				//load the sum message to x0
				ldr	w1, [summary_base, 0]			//load the sum value to w1
				bl 	printf					//print the sum message
				
				ldr 	x0, =msg_max				//load the max message to x0
				ldr 	w1, [summary_base, 4]			//load the max value to w1
				bl 	printf					//print the max value
				
				ldr 	x0, =msg_min				//load the min message to x0
				ldr 	w1, [summary_base, 8]			//load the min value to w1
				bl 	printf					//print the min value
				
				mov 	alloc, -12				//alloc = -12, which is the memory used by the summary structure
				and 	alloc, alloc, -16			//ensure quadword alignment
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//negate the alloc value
				add	sp, sp, alloc				//deallocate the memeory for summary structure
				
				mul 	alloc, array_n, array_n			//alloc = N*N
				lsl	alloc, alloc, 2				//alloc = N*N*4
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//alloc = -N*N*4
				and 	alloc, alloc, -16			//ensure quadword alignment
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//negate the alloc value
				add 	sp, sp, alloc				//deallocate the memory for product matrix
				
				mul	alloc, array_n, array_n			//alloc = N*N
				lsl 	alloc, alloc, 3				//alloc = N*N*8
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//alloc = -N*N*8
				and 	alloc, alloc, -16			//ensure quadword alignment
				mov 	temp3, -1				//temp3 = -1
				mul 	alloc, alloc, temp3			//negate the alloc value
				add 	sp, sp, alloc				//deallocate the memory for the initial matrix
				
				ldp	fp, lr, [sp], 16			//restore state
				ret						//restore state
				

				
				
				
				
		
		
		
		
