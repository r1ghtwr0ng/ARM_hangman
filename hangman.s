@32-bit ARM assembly hangman game by r1ghtwr0ng.

@The program takes the \n seperated words from the file words.txt within the same directory and selects a random word to be used in the game.
@The user must have read permissions of the file in order for the progam to work.
@Other notable things about the program:

@1. The print subprocedure is used to print individual characters until \0 is reached.

@2. Register R4 is used to store the number of mistakes the player has made during the runtime of the program.

@3. Non-changing ascii strings are located in the .data section, while labels that change are located in the .bss section

@4. Input validation is handled by input_valid. The number of characters accepted for input is 20. Should the user input more than 20 characters, the ramaining ones will be interpreted as input for the next prompt, or placed onto the terminal if the program quits.

@5. The words.txt file is opened in the first few lines of the main finction. The filename is held inside the filename_word label on the top of the .data section.

@6. print_ASCII_art works by having two seperate functions: dead - prints completely hanged stickman, normalprint - prints without stickman. Depending on the number of mistakes the player has made, the function will switch from printing a dead stickman to no stickman.
@This allows for reusing many .asciz labels and making the code more compact.

@7. Underscores for the word to be guessed are set as the word is being saved. Upon entering a valid character, it is compared to the characers in the word and replaced at the appropriate places in the label with underscores (unguessed letters).
@Should the inputted character be matched to a character inside the word, register R6 is set to 0 (originally set to 1). After the end of the word is reached, R6 is compared to 1 (indicating no match) and if true, the inputted character is put in the wrong label.
@R6 is then added to R4, meaning that if no match, R6 = 1, R4 is incremented by 1 (number of mistakes increased), otherwise R4 remains the same.

@---------------------------------------------------------------FUNCTIONS

reset_round:                                                    @Used to print message and restart round.
        BL print
        B next_round

win:                                                            @Prints the winning message and prompts user to try again (branch to try_again label)
        LDR R1, =win_msg
        BL print
        LDR R1, =word
        BL print
        LDR R1, =newline
        BL print
        B try_again

promptchar:                                                     @Used for getting input from user. Input is then passed to input_valid, which checks its validity.
        MOV R0, #0                                              @Set up syscall parameters to get character input
        LDR R1, =char
        MOV R2, #20
        MOV R7, #3
        SVC 0
        B input_valid

print_ASCII_art:                                                @R1 - pointer to string to be printed, R4 - number of failed guesses, R5 - pointer to word. More info on how print_ASCII_art works, see point 5. at the top of the file.
        PUSH {LR}                                               @Save link register
        LDR R1, =seperator
        BL print
        LDR R1, =top_part1
        BL print
        LDR R1, =top_part2
        BL print
        LDR R1, =line_1
        BL print
        LDR R1, =hidden_word
        BL print
        LDR R1, =line_2
        BL print
        TEQ R4, #0
        BEQ normalprint
dead:                                                           @Branch to here to start print a hanging stickman
        LDR R1, =line_3changed                                  @Set R1 to print head
        BL print
        LDR R1, =wrong
        BL print
        CMP R4, #1                                              @Check if only one mistake, if true print the remaining lines without stickman
        BEQ ntorso
        CMP R4, #3
        LDRGT R1, =line_4_2arms                                 @If > 3 mistakes, set R1 to print 2 arms
        LDREQ R1, =line_4_1arm                                  @If = 3 mistakes, set R1 to print 1 arm
        LDRLT R1, =line_4to5_dead                               @If < 3 mistakes, (2 mistakes) set R1 to print just torso
        BL print
        LDR R1, =line_4to5_dead                                 @Set R4 to print lower part of torso
        BL print
        CMP R4, #5
        BLT nolegs                                              @If < 5 mistakes, (4 mistakes) set R1 to print regular line and branch to normal print (no legs)
        LDREQ R1, =line_6_1leg                                  @If = 5 mistakes, set R1 to print 1 leg
        LDRGT R1, =line_6_2legs                                 @If > 5 mistakes, (6 mistakes) set R1 to print 2 legs
        BL print
        B endpr

normalprint:                                                    @Branch to here to print without stickman
        LDR R1, =line_3
        BL print
        LDR R1, =wrong
        BL print
ntorso: LDR R1, =line_4to5                                      @Branch to here to not print torso
        BL print
        LDR R1, =line_4to5
        BL print
nolegs: LDR R1, =line_6_nolegs                                  @Branch to here to not print legs
        BL print
endpr:  LDR R1, =line_7                                         @Branch to here to print last 2 lines (they are the same regardless of how many lives the player has)
        BL print
        LDR R1, =line_8
        BL print
        POP {LR}                                                @Restore link register and return to main
        BX LR

print:                                                          @Prints individual character until it reaches #0
        PUSH {R0, R3}                                           @Save register values
        MOV R7, #4                                              @Following 3 lines set up registers to perform write syscall with 1 character
        MOV R2, #1
        MOV R0, #0
print_loop:
        SVC 0
        LDRB R3, [R1], #1                                       @Load next character
        TEQ R3, #0                                              @Compare to \0 and loop if not true
        BNE print_loop
        POP {R0, R3}
        BX LR

try_again:                                                      @Prompt user to try again
        LDR R1, =newline
        BL print
        LDR R1, =try_again_msg                                  @Set up r1 to print prompt
        BL print

        MOV R2, #0                                              @Set up syscall parameters to get character input
        LDR R1, =char
        BL restore_data                                         @Zero out char label before performing read syscall

        LDR R1, =char
        MOV R0, #0
        MOV R2, #20
        MOV R7, #3
        SVC 0

        LDR R1, =newline
        BL print
        LDR R1, =char
        LDRB R2, [R1]                                           @Load first inputted character into R2
        LDRB R3, [R1, #1]!                                      @Load second inputted character into R3
        TEQ R3, #0xA
        BEQ small_hop                                           @If the second inputted character is \n (Enter), input is correct size, therefore skip to Y/N check
        LDR R1, =too_many_chars
        BL print
        B try_again

small_hop:
        CMP R2, #0x61                                           @If lowercase, capitalize the character
        SUBGE R2, #32
        TEQ R2, #89                                             @If char = Y, restart game
        BLEQ reset
        BEQ subseq_games
        CMP R2, #78                                             @If char = N, exit game
        LDREQ R1, =exit_msg
        BEQ end
        B try_again                                             @If neither, ask again

reset:                                                          @Reset everthing in .bss section (except buffer, to avoid having to read file again)
        PUSH {R0, LR}
        MOV R0, #0
        LDR R1, =word
        BL restore_data
        LDR R1, =used
        BL restore_data
        LDR R1, =hidden_word
        BL restore_data
        LDR R1, =wrong
        BL restore_data
        POP {R0, LR}
        BX LR

restore_data:                                                   @R0 - null, R1 -pointer (will reset to null), R2 - char in pointer (check if null)
        LDRB R2, [R1]
        CMP R2, #0
        BXEQ LR                                                 @End reset loop if true
        STRB R0, [R1], #1
        B restore_data

input_valid:                                                    @Check if input is valid, make character uppercase if its not
        LDR R1, =char
        LDRB R2, [R1]
        LDRB R3, [R1, #1]!
        TEQ R3, #0
        LDREQ R1, =invalid_char
        BEQ reset_round
        TEQ R3, #0xA
        LDRNE R1, =too_many_chars
        BNE reset_round
        SUB R1, R1, #1
        TEQ R2, #48                                             @Check if character is 0, and exit if it is
        LDREQ R1, =quit_msg
        BEQ end
        CMP R2, #65                                             @Check if character is less than A

        LDRLT R1, =invalid_char                                 @If < A, character is invalid
        BLT reset_round

        CMP R2, #90                                             @Check if character is between A - Z
        STRLEB R2, [R1]
        BXLE LR
        CMP R2, #97                                             @Check if character is less than a

        LDRLT R1, =invalid_char
        BLLT reset_round

        CMP R2, #122                                            @Check if character is between a-z
        SUBLE R2, R2, #32                                       @Convert to uppercase
        STRLEB R2, [R1]
        BXLE LR                                                 @Return to main

end:                                                            @Exit the program
        MOV R0, #0
        BL print                                                @Print exit message
        MOV R7, #1
        SVC 0

@---------------------------------------------------------------MAIN PROGRAM
.global main

main:                                                           @Entry point for program
        LDR R1, =title                                          @Print title ascii art and text
        BL print
        LDR R1, =title_text
        BL print

        LDR R0, =filename_word                                  @Open file "words.txt" as read-only
        MOV R1, #0
        MOV R2, #0x444
        MOV R7, #5
        SVC 0

        TEQ R0, #3                                              @Check if file was opened without errors
        LDRNE R1, =file_missing                                 @Load error message and quit if errors occured
        BNE end

        LDR R1, =buff                                           @Save contents of file inside =buff
        MOV R2, #199
        MOV R7, #3
        SVC 0

        MOV R7, #6                                              @Close file
        SVC 0

subseq_games:                                                   @If a player chooses to try again, the program must branch to here (avoid printing title and opening file again)

        MOV R0, #0                                              @Set up for generating a random number to be stored in R0
        BL time
        BL srand
        BL rand
        AND R0, R0, #0xFF                                       @Logical AND operation to get only the last byte of the random number in R0

mod_loop:                                                       @Performs mod 10 on the random byte in R0 via repeated subtraction to choose a random word index (0 - 1st word, 1 - 2nd word, etc.)
        CMP R0, #9
        SUBGT R0, R0, #10
        BGT mod_loop                                            @R0 - random number between 0 and 9
        PUSH {R0}                                               @Save the value by pushing onto the stack

        POP {R0}                                                @Restore value of R0 (random word index)
        LDR R1, =buff
        LDR R3, =word
        LDR R4, =hidden_word
        MOV R5, #0x5F                                           @R5 = '_'

selectword:                                                     @This will loop until R1 is pointing to the first character of the randomly selected word, This happens by decrementing the random number every time there is a \n until it becomes 0
        LDRB R2, [R1]
        TEQ R0, #0
        BEQ saveword
        TEQ R2, #0xA
        SUBEQ R0, R0, #1
        ADD R1, R1, #1
        B selectword

saveword:                                                       @R1 =buff, R2 - buff char, R3 =word, R4 =hidden_word, R5 - '_', This will save the randomly selected word into memory
        LDRB R2, [R1]
        TEQ R2, #10                                             @Check if char is \n
        MOVEQ R4, #0                                            @Set R4 (number of mistakes) to 0
        BEQ next_round                                          @Start game
        TEQ R2, #0                                              @Check if char is \0
        MOVEQ R4, #0
        BEQ next_round                                          @Start game

        STRB R2, [R3]                                           @Add character to word
        STRB R5, [R4]                                           @Add underscore to line_1_word
        ADD R1, R1, #1
        ADD R3, R3, #1
        ADD R4, R4, #1                                          @Move all pointers to next character
        B saveword

next_round:                                                     @Start next round
        MOV R0, #0
        LDR R1, =char
        BL restore_data
        BL print_ASCII_art                                      @Print ASCII hangman
        LDR R1, =prompt                                         @Print prompt
        BL print
        BL promptchar                                           @Prompt user for a character input

        PUSH {R5-R7}
        PUSH {R4}                                               @R4 will be popped before the remaining registers
        LDR R0, =char
        LDRB R0, [R0]
        LDR R1, =used
        LDR R2, =hidden_word
        LDR R3, =wrong

mark_used:                                                      @Store inputted character in used label, make R3 point to where the next wrong character should be stored. More detailed description of this and the next function can be found in point 7. at the top of the file
        LDRB R6, [R1]
        TEQ R0, R6
        LDREQ R1, =repeat_char
        POPEQ {R4}
        BEQ reset_round
        LDRB R4, [R3]
        TEQ R4, #0
        ADDNE R3, #1
        TEQ R6, #0
        STREQB R0, [R1]
        ADDNE R1, R1, #1
        BNE mark_used

        LDR R1, =word
        MOV R6, #1                                              @If character is matched, R6 will be set to #0. The value of R6 will be added to R4 at the end
        MOV R7, #0

checkword:                                                      @1 is added to R7 every time an '_' is found in hidden_word

        LDRB R5, [R1], #1
        TEQ R0, R5
        LDREQB R4, [R2]
        MOVEQ R6, #0
        STREQB R0, [R2]
        LDRB R4, [R2], #1
        TEQ R4, #0x5F
        ADDEQ R7, R7, #1
        TEQ R5, #0
        BNE checkword
        TEQ R6, #1
        STREQB R0, [R3]
        POP {R4}
        ADD R4, R4, R6

        TEQ R7, #0                                              @Test if all characters are guessed, if true branch to win label
        POP {R5-R7}
        BEQ win
        TEQ R4, #6                                              @Check if out of mistakes
        BNE next_round                                          @Play next round if game is not over
        BL print_ASCII_art                                      @Print final hangman
        LDR R1, =lose_msg
        BL print                                                @Print lose message
        LDR R1, =word                                           @Print out the word
        BL print
        B try_again                                             @Branch to try_again (prompts user to try again)





.data

.balign 2

filename_word:  .asciz "words.txt"
filename_word_len       = .-filename_word
title:          .asciz "  ________________________________________________________________\n  |   _    _            _   _   _____  _    _            _   _   |\n  |  | |  | |    /\\    | \\ | | / ____|| \\  / |    /\\    | \\ | |  |\n  |  | |__| |   /  \\   |  \\| || |  __ |  \\/  |   /  \\   |  \\| |  |\n  |  |  __  |  / /\\ \\  | . ` || | |_ || \\  / |  / /\\ \\  | . ` |  |\n  |  | |  | | / ____ \\ | |\\  || |__| || |\\/| | / ____ \\ | |\\  |  |\n  |  |_|  |_|/_/    \\_\\|_| \\_| \\____/ |_|  |_|/_/    \\_\\|_| \\_|  |\n  |______________________________________________________________|\n\n"             @ASCII art title
title_text:     .asciz "  A 32-bit ARM assembly game by r1ghtwr0ng\n"
prompt:         .asciz "  Enter next character (A-Z) or 0 (zero) to exit: "

seperator:      .asciz "\n  _______________________"
top_part1:      .asciz "\n  | _)__   ___________  |"
top_part2:      .asciz "\n  |_____)  |________ |  |"
line_1:         .asciz "\n  |'' ' '  |    \\\\ | |  |   Word: "
line_2:         .asciz "\n  | ' ,    |     \\\\| |  |"
line_3:         .asciz "\n  |' ,            \\| |  |   Misses: "
line_3changed:  .asciz "\n  |'  ,    O      \\| |  |   Misses: "
line_4to5:      .asciz "\n  | '              | |  |"
line_4to5_dead: .asciz "\n  |' ,     |       | |  |"
line_4_1arm:    .asciz "\n  | '     \\|       | |  |"
line_4_2arms:   .asciz "\n  |',     \\|/      | |  |"
line_6_1leg:    .asciz "\n  |, ' __ /   __   | |  |"
line_6_2legs:   .asciz "\n  | '  __ / \\ __   | |  |"
line_6_nolegs:  .asciz "\n  |' , __     __   | |  |"
line_7:         .asciz "\n  |'   ||      |   | |  |"
line_8:         .asciz "\n  |____|_______|___|_|__|\n"

invalid_char:   .asciz "\n  -------- Invalid character --------\n\n"
too_many_chars: .asciz "\n  -------- Too many characters inputted --------\n\n"
repeat_char:    .asciz "\n  -------- You have already used this character --------\n\n"
file_missing:   .asciz "\n  -------- File: words.txt cannot be found --------\n\n"
lose_msg:       .asciz "\n  #### YOU LOST - OUT OF LIVES ####\n\n  The word was: "
win_msg:        .asciz "    ---------------------------\n  << YOU WIN! CONGRATULATIONS! >>\n    ---------------------------\n\n  The word was: "
try_again_msg:  .asciz "  Try again? (Y/N): "
exit_msg:       .asciz "  Thank you for playing!\n"
quit_msg:       .asciz "  Quitting...\n"
newline:        .asciz "\n"


.bss
.balign 2
char:           .space 22               @Holds user input
word:           .space 20               @Holds randomly chosen word
hidden_word:    .space 20               @Holds underscores and guessed characters of the word
wrong:          .space 8                @Holds incorrectly guessed characters
used:           .space 28               @Holds all used characters
buff:           .space 300              @Holds words.txt file contents
.end
