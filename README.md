# Sumo
This is a sumo game implemented using assembly for 
a C8051F020 microprocessor.


This program models two sumo wrestlers. These to
sumo wrestlers are shown by two of the LEDS on 
LED bar graph. Their initial position is 
determined by the position of three of the 
switches. After 1 second, the sumo wrestlers 
step back from each other and proceed to try 
to push each other out of the "ring" or to the 
edge of the LED bar graph. The first player to
press down on their button moves their sumo 
wrestler forward one space. If the player who 
pressed their button down first is able to 
release their button before the first player 
presses theirs, they advance their player an 
additional space, which would cause both sumo
wrestlers to move one space overall. If both
players are able to press their buttons down 
before the other one releases, there is no net
change. After the initial step back, there is a
"random" delay before the sumo wrestlers push 
each other back. This delay is based on the time
it takes the players to press and release their
buttons. The game is over when the pair of sumo
wrestlers reaches either end of the LED bar 
graph. 

This program assumes that there are 10 LEDs 
connected (0 to 9) to Port 1.0-1.7, Port 2.0 and 
Port 2.1. 
There are two buttons connected to Port 2.6 
and Port 2.7. 
There are also 8 switches connected to
Port 3.0-3.7.
