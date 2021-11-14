//Name: Sipeng He
//UCID: 30113342
//Tutorial: T03
//Program: A simple memory card game
//Features:
//May 11, 2021
//-display function to print the game board
//-randomNum function to generate random number within the input boundary
//-the initialize function to initialize the game board
//-shuffle function to shuffle the cards generated
//-swap function to swap the two specified cards
//May 12, 2021
//-copyFirstHalf and copySecondHalf function to copy the first half of cards to the game board
//-findMatchCoordinate to find the coordinate of the matched card of a specific card
//-findDistance function to find the distance of the two specific cards
//-finish the game routine in the main function
//May 13. 2021
//-add validity check to user input
//May 14, 2021
//-logFile function to keep a record of player's name and score
//Limitations:
//-the input coordinates(as a string) cannot exceed 1000 characters
//-the input player's name cannot exceed 100 characters


#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

//Function Prototype declarations
void display(int** board, int** ifRevealed, int n);
void initialize(int** board, int n);
void copyFirstHalf(int* cards, int** board, int n);
void copySecondHalf(int* cards, int** board, int n);
int randomNum(int n, int m);
void shuffle(int* cards, int numOfCards);
void swap(int* cards, int i, int j);
int findDistance(int** board, int i1, int j1, int i2, int j2);
void findMatchCoordinate(int** board, int inputX, int inputY, int* iMatch, int* jMatch, int n);
void logFile(char *playerName,int score);

/*
Function: main
Features:
-initialize variables and board array
-ask player for n, if valid input is not found in command line
-ask player for name
-validity check for user input
-game runtime control
-keep track of player's score
*/
int main(int argc, char *argv[]) {
	int i,j; //for looping use
	int n=0; //key variable n that determines the size of the game board and the initial score
	int inputX, inputY; //store the coordinates input by users
	int iMatch, jMatch; //store the coordinates of the match card of a specific card choose by users
	int distance; //store the distance between the card that user pick and the correct match card
	char input[1000]; //store the player's input of coordinates as a string
	int temp; //store the card with the coordinates that input by players(inputX, inputY)
	int validityCheck = 0; //record if the input is successful or not
	if(argc == 1){ //when the n is missing in command line, ask the player to enter it
		while(validityCheck == 0){
	        printf("Input n is missing. Please enter a valid one(n>=1): ");
	        validityCheck = scanf("%d",&n);
		}
	}
	else{ 
		n = atoi(argv[1]);
	}
	validityCheck = 1;
	while(n<1||validityCheck == 0){ //if the input n is invalid, ask the user to enter a valid one
		printf("n is not valid. Please enter a valid one(n>=1): ");
		validityCheck = scanf("%d",&n);
	}
	int score = 2 * n; //initial score is 2*n
	char playerName[100]; //store the player's input name
	int numOfRevealedCards = 0; //keep track of how many cards has been successfully revealed during the game
	int** board; //initialize the 2D array board using 'pointers of pointers'
	board = (int**)malloc(2 * n * sizeof(int*));
	for (i = 0; i < 2 * n; i++) {
		board[i] = (int*)malloc(2 * n * sizeof(int));
	}
	int** ifRevealed; //initialize the 2D array of ifRevealed to keep track of the status of each card on the board(revealed or unrevealed)
	ifRevealed = (int**)malloc(2 * n * sizeof(int*));
	for (i = 0; i < 2 * n; i++) {
		ifRevealed[i] = (int*)malloc(2 * n * sizeof(int));
	}
	for (i = 0; i < 2 * n; i++) {
		for (j = 0; j < 2 * n; j++) {
			ifRevealed[i][j] = 1; //set the status of every card to 'revealed' in order to print the initial board
		}
	}
	printf("Enter the player's name: "); //ask for player's name
	scanf("%s", &playerName); 
	while('\n'!=getchar());
	initialize(board,n); //initialize the board
	printf("The randomly generated board is as followed: \n");
	display(board,ifRevealed,n); //print the initial board
	for (i = 0; i < 2 * n; i++) {
		for (j = 0; j < 2 * n; j++) {
			ifRevealed[i][j] = 0; //set the status of every card to 'unrevealed' to start the memory game
		}
	}
	printf("Press Enter to continue...\n");
	getchar();
	system("clear"); //clear the screen(initial board) to start the game
	while (numOfRevealedCards < 2*n*2*n&&score >0) { //game routine loop, end if all the cards are revealed or score is reduced to 0
		printf("Your current score: %d\n", score);
		if(numOfRevealedCards % 2 == 1){
			printf("The card you are looking for is: %d\n",temp);
		}
		printf("The game board now: \n");
		display(board, ifRevealed, n);
		printf("Enter the coordinates of a card(Enter Q/q to exit the game): ");
		validityCheck = scanf("%[^\n]",&input); 
		while('\n'!=getchar());
		if(validityCheck == 0){ //if input fails, ask the player to do it again
			printf("Invalid input. Please try again.\n\n");
			continue; 
		}
		if(strcmp(input,"Q")==0||strcmp(input,"q")==0){ //if player's input is 'Q' or 'q', end the game
			break;
		}
		validityCheck = sscanf(input,"%d %d",&inputX,&inputY); //get the coordinates from the input string 
		if(validityCheck != 2){ //if input fails, ask the player for it again
			printf("Invalid input. Please Try again.\n\n");
			continue;
		}
		printf("The coordinates you pick are: (%d,%d)\n",inputX,inputY);
		if(inputX<0||inputX>(2*n-1)||inputY<0||inputY>(2*n-1)){ //if the input coordinates are invalid, ask again
			printf("Invalid coordinates. Please try again.\n");
			printf("\n");
			continue;
		}
		if(ifRevealed[inputX][inputY]==1){ //if the chosen card has already been revealed, ask for coordinates again
			printf("This card has already been revealed, please select another card.\n\n");
			continue;
		}
		ifRevealed[inputX][inputY] = 1; //set the status of the chosen card to 'revealed'
		display(board,ifRevealed,n);
		if (numOfRevealedCards % 2 == 0) { //if the number of revealed cards is even, keep the chosen card 'revealed', continue to next round of loop
			temp = board[inputX][inputY]; //store the card in temp
			findMatchCoordinate(board, inputX, inputY, &iMatch, &jMatch,n); //find coordinates of the matched card of the chosen card
			numOfRevealedCards++;
			continue;
		}
		if (board[inputX][inputY] != temp) { //if the number of revealed cards is odd, and it is not the correct matched one
			ifRevealed[inputX][inputY] = 0; //flip back the card
			score--;
			distance = findDistance(board, inputX, inputY, iMatch, jMatch); //calculate the distance to the correct card
			printf("You are %d card(s) away!\n",distance); //give the hint
			printf("Press Enter to continue...\n");
			while('\n'!=getchar());
		}
		else{ //if the card chosen is the correct matched card
			printf("It's a match!\n");
			numOfRevealedCards++;
			score = score + n;
			printf("\n");
		}
	}
	printf("Game over.\n"); //print the name and final score on the screen
	printf("Player name: %s\n",playerName); 
	printf("Final score: %d\n",score);
	logFile(playerName,score); //write the name and score in the log file
	free(board); //free the space that allocated to the arrays
	free(ifRevealed);
	return 0;
}

/*
Function: display
Features:
-print the game board on the screen according to the data in ifRevealed array
*/
void display(int **board,int **ifRevealed,int n) {
	int i, j; //for looping purpose
	printf("\n");
	for (i = 0; i < 2 * n; i++) {
		for (j = 0; j < 2 * n; j++) {
			if (ifRevealed[i][j] == 1) { //if the card has been revealed
				printf("%d\t", board[i][j]);
			}
			else {
				printf("X\t");
			}
		}
		printf("\n");
	}
	printf("\n");
}

/*
Function: initialization
Features:
-initialize the cards array
-shuffle the cards array and copy the cards to the game board(2 times)
*/
void initialize(int **board,int n) {
	int i; //for looping purpose
	int* cards; //array to store the cards generated
	int numOfCards; //store the number of cards that should be generated
	numOfCards = 2 * n * n; //2*n*n of cards should be generated(for 2 times)
	cards = (int*)malloc(numOfCards * sizeof(int)); //initialize the card array
	for (i = 0; i < numOfCards; i++) {
		cards[i] = i;
	}
	shuffle(cards,numOfCards);
	copyFirstHalf(cards,board,n);
	shuffle(cards, numOfCards);
	copySecondHalf(cards,board,n);
	free(cards); //free the allocated space for cards array
}

/*
Function: copyFirstHalf
Features:
-copy the cards generated to the first half of the game board
*/
void copyFirstHalf(int *cards,int **board,int n) {
	int i, j; //for looping purpose
	for (i = 0; i < n; i++) {
		for (j = 0; j < 2 * n; j++) {
			board[i][j] = cards[i * 2 * n + j];
		}
	}
}

/*
Function: copySecondHalf
Features:
-copy the cards generated to the second half of the game board
*/
void copySecondHalf(int *cards,int **board,int n) {
	int i, j; //for looping purpose
	for (i = n; i < 2 * n; i++) {
		for (j = 0; j < 2 * n; j++) {
			board[i][j] = cards[(i - n) * 2 * n + j];
		}
	}
}

/*
Function: randomNum
Features:
-generate a random number within the input boundary
*/
int randomNum(int n,int m) {
	srand((unsigned)time(NULL)); //generate a random number(without limitation), time is used to make sure that the number is truly random
	return rand() % (m - n+1) + n; //using the modulo calculation to make the random number within the required boundary(n<randomNumber<m)
}

/*
Function: shuffle
Features:
-shuffle the cards using the algorithm specified in the assignment description
-which is letting every card except for the last one to swap with a random card that has larger index than it
*/
void shuffle(int* cards, int numOfCards) {
	int i, j; //for looping purpose
	for (i = 0; i < numOfCards-2; i++) { //every card generated, except for the last one, swap with a random card that has bigger index than it
		j = randomNum(i, numOfCards - 1);
		swap(cards,i,j);
	}
}

/*
Function: swap
Features:
-swap two specific cards with given coordinates
*/
void swap(int *cards,int i,int j) {
	int temp;
	temp = cards[i];
	cards[i] = cards[j];
	cards[j] = temp;
}

/*
Function: findDistance
Features:
-find the distance of two specific cards with given coordinates 
*/
int findDistance(int **board,int i1,int j1,int i2,int j2) {
	int iDistance = abs(i1 - i2); //calculate the distance of x-coordinates 
	int jDistance = abs(j1 - j2); //calculate the distance of y-coordinates
	if (iDistance > jDistance) { //pick the bigger one as the distance of the two cards
		return iDistance;
	}
	else {
		return jDistance;
	}
}
/*
Function: findMatchCoordinate
Features:
-find the coordinate of a specific card's match card
*/

void findMatchCoordinate(int **board,int inputX,int inputY, int *iMatch,int *jMatch,int n) {
	int i, j; //for looping purpose
	for (i = 0; i < 2* n; i++) {
		for (j = 0; j < 2* n; j++) {
			if (board[i][j] == board[inputX][inputY]&&(inputX!=i||inputY!=j)) { //find the matched card's coordinate and store it
				*iMatch = i;
				*jMatch = j;
			}
		}
	}
}

/*
Function: logFile
Features:
-write the player's name and score in a log file
*/
void logFile(char *playerName,int score){
	FILE* fp;
	fp=fopen("assign1.log","a+");
	if(fp == NULL){
		printf("Fail to open the log file.\n");
	}
	fprintf(fp,"Player name: %s\n",playerName);
	fprintf(fp,"Final score: %d\n\n",score);
	fclose(fp);
}
