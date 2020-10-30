;---------------------------------------------------
;   Sudo.asm
;   By Jacob Litster
;   ORIGINAL: 02/10/2020
;   
;   This program models two sumo wrestlers. These to
;   sumo wrestlers are shown by two of the LEDS on 
;   LED bar graph. Their initial position is 
;   determined by the position of three of the 
;   switches. After 1 second, the sumo wrestlers 
;   step back from each other and proceed to try 
;   to push each other out of the "ring" or to the 
;   edge of the LED bar graph. The first player to
;   press down on their button moves their sumo 
;   wrestler forward one space. If the player who 
;   pressed their button down first is able to 
;   release their button before the first player 
;   presses theirs, they advance their player an 
;   additional space, which would cause both sumo
;   wrestlers to move one space overall. If both
;   players are able to press their buttons down 
;   before the other one releases, there is no net
;   change. After the initial step back, there is a
;   "random" delay before the sumo wrestlers push 
;   each other back. This delay is based on the time
;   it takes the players to press and release their
;   buttons. The game is over when the pair of sumo
;   wrestlers reaches either end of the LED bar 
;   graph. 
;
;
;   Revision History
;   Date        Author      Description
;   02/10/2020  jlitster    Original program created
;   02/15/2020  jlitster    Subroutine comments added
;---------------------------------------------------
$INCLUDE (C8051F020.INC)
LED_PORT EQU P1
LED8 BIT P2.0
LED9 BIT P2.1
BTN1 BIT P2.7
BTN0 BIT P2.6
SWITCH_PORT EQU P3


DSEG at 30h
        PLAYER1: DS 1
        PLAYER2: DS 1 
        BTN_STATUS: DS 1

CSEG at 0

        CALL INIT
        

LOOP:   

        CALL PUSH_BACK
FIRST_CHECK:
        CALL CHECK_BUTTONS
        JZ FIRST_CHECK  ;A = 0 when the buttons 
                        ;haven't been pressed

        JB Acc.0, DOWN1 ;IF BTN0 was pressed, it
                        ;moves to DOWN1, otherwise, 
                        ;it moves to DOWN2, since one
                        ;of the buttons was pressed.



;DOWN2 is for when PLAYER2's button is pressed down.
;It checks if PLAYER1's button has been pressed down
;or if PLAYER2's button has been let up.
DOWN2:
        INC PLAYER2     ;PLAYER2 moves "forward"
SECOND_CHECK2:
        CALL DISPLAY
        CALL CHECK_BUTTONS
        JB Acc.0, MOVE1
        JB B.1, MOVE2
        JMP SECOND_CHECK2


;DOWN1 is for when PLAYER1's button is pressed down.
;It checks if PLAYER2's button has been pressed down
;or if PLAYER1's button has been let up.
DOWN1:
        DEC PLAYER1     ;PLAYER1 moves "forward"
SECOND_CHECK1:
        JB Acc.1, MOVE2
        CALL DISPLAY
        CALL CHECK_BUTTONS
        JB B.0, MOVE1
        JMP SECOND_CHECK1


;MOVE1 will move PLAYER1 "forward". It doesn't matter
;which sequence of button presses caused PLAYER1 to
;move. It also checks if the game is over.
MOVE1:
        DEC PLAYER1     
        CALL DISPLAY
        CALL CHECK_ENDGAME
        JMP LOOP


;MOVE1 will move PLAYER2 "forward". It doesn't matter
;which sequence of button presses caused PLAYER2 to
;move. It also checks if the game is over.
MOVE2:
        INC PLAYER2     
        CALL DISPLAY
        CALL CHECK_ENDGAME
        JMP LOOP




;---------------------------------------------------
;   INIT - Initialize
;   
;   This subroutine is the initialization subroutine.
;   It first disables the watchdog and then 
;   configures the inputs. It also initializes the 
;   values for PLAYER1 and PLAYER2 based on the 
;   values of the switches. It then displays the
;   players, sets R7(the psuedo-random number) and 
;   initializes BTN_STATUS based on the current 
;   button presses. 
;
;   INPUTS: SWITCH_PORT, BTN0, BTN1
;   OUTPUTS: PLAYER1, PLAYER2, BTN_STATUS, R7
;   DESTROYS: PLAYER1, PLAYER2, BTN_STATUS, R7
;
INIT:
    	MOV WDTCN,#0DEh ; Disable watchdog
     	MOV WDTCN,#0ADh
    	MOV XBR2,#40h

        SETB BTN0   ;BTN0 is an input
        SETB BTN1   ;BTN1 is an input
        MOV SWITCH_PORT, #0FFh

        MOV A, SWITCH_PORT
        CPL A
        ANL A, #07h     ;Only keeps the bottom 3 bits

        JNZ VALID_INPUT
                            ;If the input value is
        MOV PLAYER1, #05    ;0, the players start in
        MOV PLAYER2, #04    ;the middle
        JMP INVALID
VALID_INPUT:
        MOV PLAYER2, A      ;If A != 0, PLAYER2 is A
                            ;and PLAYER1 is A+1
        INC A
        MOV PLAYER1, A
INVALID:
        CALL DISPLAY
        MOV R7, #50     ;Initialize the "random"
                        ;number for the counter.
                        ;The initial value is 50,
                        ;which gives a 1s delay. 
        

        MOV A, #0FFh    ;This code initializes
        MOV C, BTN0     ;BTN_STATUS with the 
        MOV Acc.0, C    ;initial button values
        MOV C, BTN1
        MOV Acc.1, C

        CPL A 
        MOV BTN_STATUS, A


        RET




;---------------------------------------------------
;   PUSH_BACK
;
;   This subroutine waits for 500 ms plus an 
;   additional 10 ms multiplied by R7. Assuming that
;   R7 contains a value between 0 and 50, it will 
;   give a delay between 500 and 1000 ms. Following
;   the delay, BTN_STATUS is updated(someone may 
;   have pressed one of the buttons in that time).
;   Then PLAYER1 is incremented (moved to the left)
;   and PLAYER2 is decremented (moved to the right). 
;   Finally, PLAYER1 and PLAYER2 are displayed to 
;   the LED bar graph.
;
;   INPUTS:     Random number in R7, BTN0, BTN1, 
;               PLAYER1, PLAYER2
;   OUTPUTS:    BTN_STATUS, PLAYER1, PLAYER2
;   DESTROYS:   R3, R4, R5, BTN_STATUS, 
;               PLAYER1, PLAYER2
;
PUSH_BACK:
        MOV A, R7      ;R7 contains "random" value
                        ;0 - 50
        ADD A, #50     ;R5 now contains a "random"
                        ;value, 50 - 100
        MOV R5, A

DELAY5: MOV R3, #133    ;133*50*1.5 us = 9.975 ms
DELAY3: MOV R4, #50     ;This block of code gives R5 
DELAY4: DJNZ R4, DELAY4 ;times 10 ms delay(.5 - 1 s)   
        DJNZ R3, DELAY3
        DJNZ R5, DELAY5

        MOV A, #0FFh    ;This code sets BTN_STATUS
        MOV C, BTN0     ;with the current button
        MOV Acc.0, C    ;status. This is done
        MOV C, BTN1     ;because buttons may have 
        MOV Acc.1, C    ;changed during the delay
                        ;and we will be checking the
                        ;button presses AFTER PushBack,
        CPL A           ;not during.
        MOV BTN_STATUS, A  

        INC PLAYER1     ;Player1 moves left
        DEC PLAYER2     ;Player2 moves right
        CALL DISPLAY

        RET




;---------------------------------------------------
;   CHECK_BUTTONS
;
;   This subroutine checks for transitions in the 
;   button status. It uses a modulous counter in
;   R7 to generate the random number used in 
;   PUSH_BACK. This number is decremented each time
;   this subroutine is called, which gives a random
;   enough number since it is based on human 
;   interaction. It then delays for 10 ms to
;   debounce the buttons. Then BTN_STATUS is updated
;   with the new button status and A returns a 1 for 
;   each button pressed and B returns a 1 for each 
;   button that was released. Bit 0 of A & B is for
;   BTN0 and Bit 1 is for BTN1. 
;
;   INPUTS:     Random number in R7, BTN0, BTN1, 
;               BTN_STATUS
;   OUTPUTS:    Random number in R7, BTN_STATUS,
;               Button presses in A, 
;               Button releases in B
;   Destroys:   R3, R4, R7, BTN_STATUS
;  
CHECK_BUTTONS:

        ;This code decrements the pseudo-random
        ;number each time CHECK_BUTTONS is called.
        ;It gives a range of 0-50, which is elsewhere
        ;used to give a 0.5-1 sec delay
        DJNZ R7, CARRY_ON
        MOV R7, #50     
CARRY_ON:


        MOV R3, #133    ;133*50*1.5 us = 9.975 ms
DELAY:  MOV R4, #50     ;This gives 10 ms to       
DELAY2: DJNZ R4, DELAY2 ;debounce the buttons.   
        DJNZ R3, DELAY

        MOV A, #0FFh    ;This code moves the buttons
        MOV C, BTN0     ;into bits 0 and 1 of ACC and
        MOV Acc.0, C    ;clears the rest(by setting
        MOV C, BTN1     ;them high).
        MOV Acc.1, C

        MOV B,A
        CPL A 
        XCH A, BTN_STATUS   ;A is the old BTN_STATUS
                            ;BTN_STATUS is updated.

        XRL A, BTN_STATUS   ;A is the differences
                            ;in the old and new
                            ;BTN_STATUS 
        XCH A, B
        ANL A, B            ;A is now the "let go's"

        XCH A, B
        ANL A, BTN_STATUS   ;A is now the rising
                            ;edges. B is the falling.

        RET
    



;---------------------------------------------------
;   DISPLAY
;   
;   This subroutine first turns off all of the LEDs
;   and then turns on the LED for PLAYER1 and then
;   the one for PLAYER2.
;
;   INPUTS:     PLAYER1, PLAYER2
;   OUTPUTS:    Changes LEDs in LED_PORT
;   DESTROYS:   LED_PORT
;
DISPLAY:
        CALL LEDS_OFF
        MOV A, PLAYER1
        CALL LED_ON
        MOV A, PLAYER2
        CALL LED_ON

        RET




;---------------------------------------------------
;   LEDS_OFF
;
;   This subroutine turns all LEDs in LED_PORT off.
;
;   INPUTS:     NONE
;   OUTPUTS:    LED_PORT
;   DESTROYS:   LED_PORT
;
LEDS_OFF:
        MOV LED_PORT, #0FFh ;The LEDs are active low.
        SETB LED8           ;Setting them to a 1 
        SETB LED9           ;turns them off. 
        RET




;---------------------------------------------------
;   LED_ON
;
;   This subroutine turns on a single LED in LED_PORT
;   and leaves the rest as they were previously,
;
;   INPUTS:     LED number 0-9 in A
;   OUTPUTS:    LED_PORT
;   DESTROYS:   LED_PORT
;
LED_ON:
        JB ACC.3, OVER8
        ADD A, #TABLE - AFTER
        MOVC A, @A + PC 
AFTER:  ANL LED_PORT, A

        RET
        ;A 0 turns an LED on. ANDing the Port with
        ;all 1s except for the 0 will cause only the
        ;bit with the 0 to turn on. The other bits 
        ;will stay the same
TABLE:  DB 0FEh, 0FDh, 0FBh, 0F7h, 0EFh, 0DFh, 0BFh, 7Fh

OVER8:  JB ACC.0, SET9
        CLR LED8
        RET

SET9:   CLR LED9
        RET




;---------------------------------------------------
;   CHECK_ENDGAME
;
;   This subroutine checks if either player is at 
;   the end of the "ring" and if so ends the game
;   by entering an infinite loop. Otherwise, it
;   returns.
;
;   INPUTS:     PLAYER1, PLAYER2
;   OUTPUTS:    NONE
;   DESTROYS:   R1, R2
;
CHECK_ENDGAME:
        MOV R1, PLAYER1         ;When PLAYER1 is 9,
        CJNE R1, #09h, CONT     ;the LEDs will be on
        JMP DIE                 ;the far left(end of 
                                ;game)

CONT:   MOV R2, PLAYER2         ;When PLAYER2 is 0,        
        CJNE R2, #00h, NOT_END  ;the LEDs will be on 
                                ;the far right(end of
                                ;game)
DIE:    JMP DIE 

NOT_END:
        RET



        END