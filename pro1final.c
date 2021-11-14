/*
Name: Sipeng He
Tutorial: T03
UCID: 30113342
Program: MindMaster in C

Description: 
-a game that letting player taking guesses about the random generated sequence of colors(alphabets)
-for each guess, the program can show the user the hint about how many of the slots he or she gets right, etc.

Finish Date: June 2, 2021

Features:
-user can specify the size of the game board by using command line parameters
-random colors(alphabets) are generated and assigned to the game board grids
-take guesses from user
-give hint, score, time and other information to users
-finished the game or not, an entry will be created to the logfile.log
-for each game ends with win or loss, a transcript is created, the name of which is the player's name and time it was created
-user can choose to see the top n scores and bottom n scores at the begining and the end of each game
-when a game ends, user can choose to start a new game or quit
-some level of input validation is provided

Limitations:
-if the user ask to see the top n scores or bottom n scores when the logfile.log hasn't been created, the program will end directly with a message
*/ 


#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>

struct record {		//structure to store the information read from the logfile.log
	char name[100];
	double score;
	int time;
};

void printHiddenCode(char** hiddenCode, int N, int M);
void getTrial(char** trials, int trialCounter, int N, int M, int* quitFlag);
void initializeGame(char** hiddenCode, int C, int M, int N);
int randomNum(int n, int m, int neg);
char color(int n, int C);
void calculateResponse(int N, int M, int trialCounter, char** hiddenCode, char** trials, double** hint, double* score, int *timer, int* previousTime);
void displayHints(int N, int M, int trialCounter, char** trials, double** hint);
void exitGame(char* playerName, double finalScore, char** trials, double** hint, int N, int M, int trialCounter, int quitFlag, int crackedFlag, int timesUpFlag, int timeLimit, char** hiddenCode);
double calculateScore(int trialCounter, int crackedFlag, int failFlag, int R, double** hint, int quitFlag);
void displayTop(int n);
void displayBottom(int n);

/*
Function: main
Features:
-loop control for each game and each guess
-initialization of parameters
-validity check for command line input
*/
int main(int argc, char* argv[]) {
	int i, j;
	char playerName[100];
	int N = -1;
	int M = -1;
	int C = -1;
	int R = -1;
	double score;
	double finalScore;
	int modeFlag = -1;
	char playAgainFlag;
	int trialCounter;
	int validity;
	
	char** hiddenCode;	//declare pointers to array of pointers
	char** trials;
	double** hint;
	

	int crackedFlag;
	int quitFlag;
	int timesUpFlag;
	int failFlag;
	char parameters[100];

	srand(time(NULL)); //generate a random number(without limitation), time is used to make sure that the number is truly random

	if (argc < 7) {		//if some parameters are missing from command line
		printf("Some parameters are missing. Please re-enter them.\n");
		while (1) {
			printf("Please Enter name N M C R mode(0 or 1): ");
			scanf("%[^\n]", parameters);
			validity = sscanf(parameters, "%s %d %d %d %d %d", playerName, &N, &M, &C, &R, &modeFlag);
			if (N < 1 || M < 1 || C < 5 || R<1 || M>C || (modeFlag != 0 && modeFlag != 1 || validity == -1)) {
				printf("Invalid input. Please try again.\n");
				while (getchar() != '\n');
				continue;
			}
			getchar();
			break;
		}
	}
	else {		//validity check for command line input
		strcpy(playerName, argv[1]);
		N = atoi(argv[2]);
		M = atoi(argv[3]);
		C = atoi(argv[4]);
		R = atoi(argv[5]);
		modeFlag = atoi(argv[6]);
		if (N < 1 || M < 1 || C < 5 || R<1 || M>C || (modeFlag != 0 && modeFlag != 1)) {
			N = -1;
			M = -1;
			C = -1;
			R = -1;
			modeFlag = -1;
			printf("Command Line Parameters are invalid. Please re-enter them.\n");
			while (1) {
				printf("Please Enter name N M C R mode(0 or 1): ");
				scanf("%[^\n]", parameters);
				validity = sscanf(parameters, "%s %d %d %d %d %d", playerName, &N, &M, &C, &R, &modeFlag);
				if (N < 1 || M < 1 || C < 5 || R<1 || M>C || (modeFlag != 0 && modeFlag != 1 || validity == -1)) {
					printf("Invalid input. Please try again.\n");
					while (getchar() != '\n');
					continue;
				}
				while (getchar() != '\n');
				break;
			}
		}
	}
	while (1) {		//loop for each game; player can choose to start a new game at the end of the loop
		score = 0;
		finalScore = 0;
		trialCounter = 0;
		crackedFlag = 0;
		quitFlag = 0;
		timesUpFlag = 0;
		failFlag = 0;
		int timeLimit = 60 * N * 5;	
		int timer = 60 * N * 5;
		int previousTime;
		previousTime = time(NULL);

		hiddenCode = (char**)malloc(N * sizeof(char*));		//allocating memories to 2D arrays
		for (i = 0; i < N; i++) {
			hiddenCode[i] = (char*)malloc(M * sizeof(char));
		}

		trials = (char**)malloc(R * N * sizeof(char*));
		for (i = 0; i < R * N; i++) {
			trials[i] = (char*)malloc(M * sizeof(char));
		}

		hint = (double**)malloc(R * sizeof(double*));
		for (i = 0; i < R; i++) {
			hint[i] = (double*)malloc(5 * sizeof(double));
		}

		initializeGame(hiddenCode, C, M, N);	//generate the hidden code or game board

		printf("Hello %s!\n", playerName);
		if (modeFlag == 0) {
			printf("Running MasterMind in play mode\n");
		}
		else {
			printf("Running MasterMind in test mode\n");
		}

		printf("Do you want to see the entries at the top or bottom of the log file?\n");	//prompt users if they want to see the top or bottom n entries in the logfile.log
		printf("-Enter T to see entries at the top\n");
		printf("-Enter B to see entries at the bottom\n");
		printf("-Enter other keys to continue the game\n");

		char disTB;
		scanf("%c", &disTB);
		int entryNum;

		if (disTB == 'T' || disTB == 't') {
			printf("Enter the number of top entries you want to see: ");
			while (1) {
				validity = scanf("%d", &entryNum);
				if (validity == -1||entryNum < 0) {
					printf("Invalid input! Please try again: ");
				}
				else {
					break;
				}
			}
			displayTop(entryNum);
		}

		if (disTB == 'B' || disTB == 'b') {
			printf("Enter the number of bottom entries you want to see: ");
			while (1) {
				validity = scanf("%d", &entryNum);
				if (validity == -1||entryNum < 0) {
					printf("Invalid input! Please try again: ");
				}
				else {
					break;
				}
			}
			displayBottom(entryNum);
		}

		while ('\n' != getchar());

		if (modeFlag == 1) {			//if the game is in test mode, print the hidden code
			printHiddenCode(hiddenCode, N, M);
		}

		printf("Start Cracking......\n");	//printing frame
		for (i = 0; i < M; i++) {
			printf("- ");
		}
		printf("B\tW\tR\tS\tT\n");

		while (1) {		//loop of each guess
			getTrial(trials, trialCounter, N, M, &quitFlag);		//let user input a guess
			if (quitFlag == 1) {	//if the user type in "$" to quit, set the flag and break the loop
				break;
			}
			calculateResponse(N, M, trialCounter, hiddenCode, trials, hint, &score, &timer, &previousTime);	//calculate and print the hints and score
			trialCounter++;
			displayHints(N, M, trialCounter, trials, hint);
			if (hint[(trialCounter - 1)][4] < 0) {		//if the time is used up, set the flag and break the loop
				timesUpFlag = 1;
				break;
			}
			if (hint[(trialCounter - 1)][0] == N * M) {		//if the hidden code is completely cracked, set the flag and break the loop
				crackedFlag = 1;
				break;
			}
			if (trialCounter == R) {		//if the number of trials exceed the limitation, set the flag and break the loop
				failFlag = 1;
				break;
			}
		}
		finalScore = calculateScore(trialCounter, crackedFlag, failFlag, R, hint, quitFlag);	//calculate final score
		exitGame(playerName, finalScore, trials, hint, N, M, trialCounter, quitFlag, crackedFlag, timesUpFlag, timeLimit, hiddenCode);	//get the log file and trancript done

		printf("Do you want to see the entries at the top or bottom of the log file?\n");	//prompt users again if they want to see the top or bottom n entries in the logfile.log
		printf("-Enter T to see entries at the top\n");
		printf("-Enter B to see entries at the bottom\n");
		printf("-Enter other keys to exit the game\n");
		
		scanf("%c", &disTB);

		if (disTB == 'T' || disTB == 't') {
			printf("Enter the number of top entries you want to see: ");
			while (1) {
				validity = scanf("%d", &entryNum);
				if (validity == -1||entryNum < 0) {
					printf("Invalid input! Please try again: ");
				}
				else {
					break;
				}
			}
			displayTop(entryNum);
		}

		if (disTB == 'B' || disTB == 'b') {
			printf("Enter the number of bottom entries you want to see: ");
			while (1) {
				validity = scanf("%d", &entryNum);
				if (validity == -1||entryNum < 0) {
					printf("Invalid input! Please try again: ");
				}
				else {
					break;
				}
			}
			displayBottom(entryNum);
		}
		free(trials);			//deallocate memories
		free(hiddenCode);
		free(hint);
		getchar();
		printf("Play again?(Y/N): ");		//ask users if they want to play again
		scanf("%c", &playAgainFlag);
		if (playAgainFlag != 89 && playAgainFlag != 121) {	//if they don't want to play again, quit the game
			break;
		}
		while(getchar()!='\n');
	}
		return 0;
}

/*
Function: printHiddenCode
Features:
-print the randomly generated hidden code in the test mode
*/
	void printHiddenCode(char** hiddenCode, int N, int M) {
		int i, j;
		printf("Hidden Code is: \n");
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				printf("%c ", hiddenCode[i][j]);
			}
			printf("\n");
		}
	}
	
/*
Function: getTrial
Features:
-take in a guess from the user, store it in array trials
-input validity check
*/
	void getTrial(char** trials, int trialCounter, int N, int M, int* quitFlag) {
		int i = 0;
		int j;
		int row;
		char input;
		char test;
		while (i < N) {
			j = 0;
			while (j < M) {
				input = getchar();
				if (input == '$') {
					*quitFlag = 1;
					break;
				}
				else if ((int)input > 90 || (int)input < 65){
					printf("Invalid Input. Please Try again\n");
					j = 0;
					while(getchar()!='\n');
					continue;
				}
				else {
					trials[N * trialCounter + i][j] = input;
					j++;
				}
				test = getchar();
			}
			if (*quitFlag == 1) {
				break;
			}
			i++;
		}
	}

/*
Function: initializeGame
Features:
-call the randomNum function to generate a random number
-generate random color combinations and assign them to the hiddenCode array
*/
	void initializeGame(char** hiddenCode, int C, int M, int N) {
		int i, j;
		int randNum;
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				randNum = randomNum(0, 100, 0);
				hiddenCode[i][j] = color(randNum, C);
			}
		}
	}
/*
Function: randomNum
Features:
-generate a random color using the time as seed
*/
	int randomNum(int n, int m, int neg) {
		int num;
		num = rand() % (m - n + 1) + n; //using the modulo calculation to make the random number within the required boundary(n<randomNumber<m)
		if (neg == 1) {
			num = num * -1;
		}
		return num;
	}
/*
Function: color
Features:
-return a color(alphabet) acccording to the randomly generated number n
*/
	char color(int n, int C) {
		char color;
		color = (char)((n % C) + 65);
		return color;
	}
/*
Function: calculateResponse
Features:
-calculate the hints, score and time remained from one guess
*/
	void calculateResponse(int N, int M, int trialCounter, char** hiddenCode, char** trials, double** hint, double* score, int *timer, int* previousTime) {
		int B = 0;
		int W = 0;
		int i, j;
		int row;
		int u, v;
		int currentTime;
		int timeDifference;
		double stepScore;
		char** tempBoard;		//a tempBoard array is used to calculate the number of input color that is correct but in wrong position
		tempBoard = (char**)malloc(N * sizeof(char*));
		for (i = 0; i < N; i++) {
			tempBoard[i] = (char*)malloc(M * sizeof(char));
		}
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				tempBoard[i][j] = hiddenCode[i][j];	//copy the hidden code to the tempBoard
			}
		}
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				row = trialCounter * N + i;
				if (trials[row][j] == hiddenCode[i][j]) {
					B++;
					tempBoard[i][j] = '0';	//for every element in the tempboard that has already been matched, set that corresponding value on tempboard as '0'
				}
			}
		}
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				if (tempBoard[i][j] != '0') {	//colors on the correct position should not be considered for calculating W
					for (u = 0; u < N; u++) {
						for (v = 0; v < M; v++) {
							if (trials[N * trialCounter + i][j] == tempBoard[u][v]) {
								W++;
								tempBoard[u][v] = '1';	//if a mismatched element on the gameboard is found, set the corresponding value in the tempboard to '1' to avoid duplication
								break;
							}
						}
						if (tempBoard[u][v] == '1') {	//for a input color that already finds a match, no need to look again, break the loop and move on to next color 
							break;
						}
					}
				}
			}
		}
		stepScore = (B + ((double)W / 2)) / (trialCounter + 1);		//calculating scores
		*score = *score + stepScore;
		currentTime = time(NULL);		//calculating Time duration
		timeDifference = currentTime - *previousTime;
		*timer = *timer - timeDifference;
		*previousTime = currentTime;
		hint[trialCounter][0] = B;
		hint[trialCounter][1] = W;
		hint[trialCounter][2] = trialCounter + 1;
		hint[trialCounter][3] = *score;
		hint[trialCounter][4] = *timer;
		free(tempBoard);		//deallocate the memories for tempBoard
	}
/*
Function: displayHints
Features:
-print the hint array that contains hints, score, trial number and time remained
*/

	void displayHints(int N, int M, int trialCounter, char** trials, double** hint) {
		int i, j;
		int min;
		int sec;
		int time;
		int row;
		printf("\n");
		for (i = 0; i < M; i++) {
			printf("- ");
		}
		printf("B\tW\tR\tS\tT\n");
		for (i = 0; i < N * trialCounter; i++) {
			for (j = 0; j < M; j++) {
				printf("%c ", trials[i][j]);
			}
			if ((i + 1) % N == 0) {
				row = (i + 1) / N - 1;
				time = (int)hint[row][4];  //convert the original time date in seconds to the form of minutes:seconds
				min = time / 60;
				sec = time % 60;
				printf("%.0lf\t%.0lf\t%.0lf\t%.2lf\t%d:%02d\n", hint[row][0], hint[row][1], hint[row][2], hint[row][3], min, sec);
			}
			else {
				printf("\n");
			}
		}
	}
/*
Function: calculateScore
Features:
-calculate the final score
-users that don't finish the game will get negative infinate score, which is presented by -999999 in this program
*/
	double calculateScore(int trialCounter, int crackedFlag, int failFlag, int R, double** hint, int quitFlag) {
		double finalScore;
		if (failFlag == 1) {
			finalScore = -1 * (hint[trialCounter - 1][3] / trialCounter) * 1000 * hint[trialCounter - 1][4];
		}
		else if (quitFlag == 1) {
			finalScore = -999999;
		}
		else {
			finalScore = (hint[trialCounter - 1][3] / trialCounter) * 1000 * hint[trialCounter - 1][4];
		}
		return finalScore;
	}
/*
Function: logScore
Features:
-make a log file that contains user's name, final score and time duration
-the time duration for users who don't finish the game will be positive infinate, which is represented by 999999 in this program 
*/

	void logScore(char* playerName, double finalScore, int timeUsed, int quitFlag) {
		FILE* fp;
		fp = fopen("logfile.log", "a+");
		if (fp == NULL) {
			printf("Fail to open the log file.\n");
		}
		fprintf(fp, "Player name: %s\n", playerName);
		fprintf(fp, "Final score: %.2lf\n", finalScore);
		if (quitFlag == 0) {
			fprintf(fp, "Time(seconds): %d\n\n", timeUsed);
		}
		else {
			fprintf(fp, "Time(seconds): 999999\n\n");
		}
		fclose(fp);
	}
/*
Function: transcripeGame
Features: 
-make a transcript of a game, listing the hiddenCode, every move and final result
-the transcript file is in the form of name-hour-minute-second.log
*/
	void transcripeGame(char* playerName, char** trials, double** hint, int N, int M, int trialCounter, char* recTime, char** hiddenCode, int crackedFlag, int timesUpFlag, double finalScore) {
		int i, j;
		int min;
		int time;
		int sec;
		int row;
		FILE* fp;
		char fileName[100];
		char onlyTime[100];
		strcpy(fileName, playerName);
		strcat(fileName, "-");
		strncpy(onlyTime, recTime+11, 8);	//cut the hour, minute, second part from the original string returned by the ctime function
		onlyTime[8] = '\0';
		strcat(fileName, onlyTime);			//concatenate the name string and time string together
		char* temp;
		if ((temp = strstr(fileName, ":"))) {	//replace the : in the string with -
			*temp = '-';
		}
		if ((temp = strstr(fileName, ":"))) {
			*temp = '-';
		}
		char ext[6] = ".log";
		strcat(fileName, ext);
		printf("The transcript has been saved as %s\n", fileName);
		fp = fopen(fileName, "a+");
		if (fp == NULL) {
			printf("Fail to open the transcript file.\n");
		}
		fprintf(fp, "Hidden Code is: \n");
		for (i = 0; i < N; i++) {
			for (j = 0; j < M; j++) {
				fprintf(fp, "%c ", hiddenCode[i][j]);
			}
			fprintf(fp, "\n");
		}
		for (i = 0; i < M; i++) {
			fprintf(fp, "-\t");
		}
		fprintf(fp, "B\tW\tR\tS\tT\n");
		for (i = 0; i < N * trialCounter; i++) {
			for (j = 0; j < M; j++) {
				fprintf(fp, "%c\t", trials[i][j]);
			}
			if ((i + 1) % N == 0) {
				row = (i + 1) / N - 1;
				time = (int)hint[row][4];
				min = time / 60;
				sec = time % 60;
				fprintf(fp, "%.0lf\t%.0lf\t%.0lf\t%.2lf\t%d:%02d\n", hint[row][0], hint[row][1], hint[row][2], hint[row][3], min, sec);
			}
			else {
				fprintf(fp, "\n");
			}
		}
		if (crackedFlag == 1) {
			fprintf(fp, "Cracked!\n");
			fprintf(fp, "Final score: %.2lf\n", finalScore);
		}
		else if (timesUpFlag == 1) {
			fprintf(fp, "Time's up!\n");
			fprintf(fp, "Final Score: %.2lf\n", finalScore);
		}
		else {
			fprintf(fp, "You lost!\n");
			fprintf(fp, "Final Score: %.2lf\n", finalScore);
		}
		fclose(fp);
	}
/*
Function: exitGame
Features:
-make preparations for exit the game
-call the logScore and transcripeGame functions to make logfile and transcript
-get the current time from the mechine and pass it to the transcripeGame function 
*/
	void exitGame(char* playerName, double finalScore, char** trials, double** hint, int N, int M, int trialCounter, int quitFlag, int crackedFlag, int timesUpFlag, int timeLimit, char** hiddenCode) {
		int timeUsed;
		if (quitFlag == 1) {
			printf("You chose to quit. Game over.\n");
			while(getchar()!='\n');
			logScore(playerName, finalScore, timeUsed, quitFlag);
		}
		else {
			timeUsed = timeLimit - ((int)hint[trialCounter - 1][4]);
			if (crackedFlag == 1) {
				printf("Cracked!\n");
				printf("Final score: %.2lf\n", finalScore);
			}
			else if (timesUpFlag == 1) {
				printf("Time's up!\n");
				printf("Final Score: %.2lf\n", finalScore);
			}
			else {
				printf("You lost!\n");
				printf("Final Score: %.2lf\n", finalScore);
			}
			time_t curtime;
			time(&curtime);
			char recTime[100];
			strcpy(recTime, ctime(&curtime));
			logScore(playerName, finalScore, timeUsed, quitFlag);
			transcripeGame(playerName, trials, hint, N, M, trialCounter, recTime, hiddenCode, crackedFlag, timesUpFlag, finalScore);
		}
	}
/*
Function: displayTop
Features:
-display the top n scores with the name and time duration
-if the user ask to see the top n scores or bottom n scores when the logfile.log hasn't been created, the program will end directly with a message
*/
	void displayTop(int n) {
		struct record records[100];		//declare a structural array
		struct record temp;
		int counter = 0;
		int validity;
		int i, j;
		char input[100];
		FILE* fp;
		fp = fopen("logfile.log", "r");
		if (fp == NULL) {
			printf("Fail to open the log file.\n");
			exit(0);
		}
		while (1) {			//loop through every entry in the logfile and store the information in the structural array
			fgets(input, 1000, fp);
			if (strlen(input) < 3) { 	//finish reading entries, break the loop
				break;
			}
			sscanf(input, "Player name: %s", records[counter].name);
			fgets(input, 1000, fp);
			sscanf(input, "Final score: %lf", &records[counter].score);
			fgets(input, 1000, fp);
			sscanf(input, "Time(seconds): %d", &records[counter].time);
			fgets(input, 1000, fp);
			counter++;
		}
		if (counter < n) {
			while (1) {		//if n is bigger that the number of entries in the logfile, prompt the user for a new n
				printf("There aren't so many entries in the log file!\n");
				printf("Please enter a valid number(<=%d): ", counter);
				scanf("%d", &n);
				if (n <= counter) {
					break;
				}
			}
		}
		printf("The top %d entries: \n\n", n);		
		for (i = 0; i < counter; i++) {			//using the bubble sort method to sort the entries from low score to high score
			for (j = 0; j < counter - i - 1; j++) {
				if (records[j].score > records[j + 1].score) {
					temp = records[j + 1];
					records[j + 1] = records[j];
					records[j] = temp;
				}
			}
		}
		for (i = counter - 1; i > counter - n - 1; i--) {		//print the top n score entries
			validity = printf("Players Name: %s\n", records[i].name);
			printf("Final score: %.2lf\n", records[i].score);
			printf("Time(Seconds): %d\n", records[i].time);
			printf("\n");
		}
	}
/*
Function: displayBottom
Features:
-display the bottom n scores with the name and time duration
-entries with negative score will not be displayed
-if the user ask to see the top n scores or bottom n scores when the logfile.log hasn't been created, the program will end directly with a message
*/
	void displayBottom(int n) {
		struct record records[100];
		struct record temp;
		int counter = 0;
		int validity;
		int i, j;
		char input[100];
		FILE* fp;
		fp = fopen("logfile.log", "r");
		if (fp == NULL) {
			printf("Fail to open the log file.\n");
			exit(0);
		}
		while (1) {		//loop through every entry in the logfile and store the information in the structural array
			fgets(input, 1000, fp);
			if (strlen(input) < 3) {
				break;
			}
			sscanf(input, "Player name: %s", records[counter].name);
			fgets(input, 1000, fp);
			sscanf(input, "Final score: %lf", &records[counter].score);
			fgets(input, 1000, fp);
			sscanf(input, "Time(seconds): %d", &records[counter].time);
			fgets(input, 1000, fp);
			counter++;
		}

		for (i = 0; i < counter; i++) {		//using the bubble sort method to sort the entries from high score to low score
			for (j = 0; j < counter - i - 1; j++) {
				if (records[j].score < records[j + 1].score) {
					temp = records[j + 1];
					records[j + 1] = records[j];
					records[j] = temp;
				}
			}
		}

		for (i = counter - 1; i >= 0; i--) {		//ignore the negative score entries
			if (records[i].score < 0) {
				counter--;
			}
		}
		if (counter < n) {		//if input n is larger that the number of entries in the logfile, prompt the user for a new n
			while (1) {
				printf("There aren't so many entries in the log file!\n");
				printf("Please enter a valid number(<=%d): ", counter);
				scanf("%d", &n);
				if (n <= counter) {
					break;
				}
			}
		}

		printf("The bottom %d entries: \n\n", n);		//print the bottom n entries
		for (i = counter - 1; i > counter - n - 1; i--) {
			validity = printf("Players Name: %s\n", records[i].name);
			printf("Final score: %.2lf\n", records[i].score);
			printf("Time(Seconds): %d\n", records[i].time);
			printf("\n");
		}
	}
