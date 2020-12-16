.equ INPUT, 0
.equ OUTPUT, 1
.equ LOW, 0
.equ HIGH, 1

.equ RED_PIN, 1
.equ BLUE_PIN, 29
.equ YLO_PIN, 26
.equ GRN_PIN, 27

.equ STP_PIN, 24
.equ PAUSE_S, 1 // pause in sec
.equ SPD, 200

.section .rodata
ladder_msg:	.asciz "Pin#: %u\n"
.align 4
.text
.global main

main:
			//int main()
	push {lr}	//{
	bl wiringPiSetup // wiringPiSetup();  // initialize the wiringPi library
	
	mov r0, #STP_PIN // Set Button pin for input
	bl setPinInput

	mov r0, #RED_PIN // pinMode(1, OUTPUT); // set the wpi 1 pin for the output 
	bl setPinOutput
	
	mov r0, #BLUE_PIN // do the same this as red pin for blue, green yellow
	bl setPinOutput
	
	mov r0, #YLO_PIN
	bl setPinOutput

	mov r0, #GRN_PIN
	bl setPinOutput


	// Turn off ALL Pins
	mov r0, #GRN_PIN
	bl pinOff

	mov r0, #BLUE_PIN
	bl pinOff

	mov r0, #RED_PIN
	bl pinOff

	mov r0, #YLO_PIN
	bl pinOff
	
	mov r9, #1 // Toggle Light flicker (1 On, -1 Off)
	mov r6, #0 // Counter, for ladder game score
	mov r4, #GRN_PIN // Light Color, where we are on the ladder
	mov r5, #1 // Toggle button, to check if pressed (1), and released (-1)
	mov r8, #-1 // Toggler, modifier for whatever we toggle so we multiply by it

lp:
	cmp r6, #0 		// Test to see if our Counter is 0, this uses the Green Light (0) 
	moveq r4, #GRN_PIN	// Then move our value for the light into r4

	cmp r6, #1		// Test Counter for Blue Light (1)
	moveq r4, #BLUE_PIN

	cmp r6, #2		// Test Counter for Yellow Light (2)
	moveq r4, #YLO_PIN

	cmp r6, #3
	moveq r4, #RED_PIN	// Test Counter for Red Light (3)

	mov r1, r4		//  Move r4 into r1 and pass both r1 and r2 (The pause delay) into the action func
	mov r2, #PAUSE_S
	bl action	// execute action func

	cmp r0, #1	// check to see if the button is pressed
	cmpeq r9, #1	// check if the light is ON
	cmpeq r5, #1	// check if the button has been released before hand (reset)
	addeq r6, #1	// add to the counter and move to next light
	muleq r5, r8	// toggle r5 so the button cannot be read if held down, releasing sets it back

	cmp r0, #0	// if the button has been released, set r5 to 1 to read input again
	muleq r5, r8

	cmp r6, #4	//if reached the end, end the game (4 stages)
	bleq end_lp	// execute end loop func

	bal lp		// loop the function

end_lp:
	mov r0, #RED_PIN	//End loop function, turn all pins off, and end the program
	bl pinOff

	mov r0, #GRN_PIN
	bl pinOff

	mov r0, #BLUE_PIN
	bl pinOff

	mov r0, #YLO_PIN
	bl pinOff

	mov r0, #0
	pop {pc}

turnAllOff:		// This function was made to turn all lights off without ending the program, but is unused
	push {lr}
	mov r0, #RED_PIN
	bl pinOff

	mov r0, #BLUE_PIN
	bl pinOff

	mov r0, #YLO_PIN
	bl pinOff

	mov r0, #GRN_PIN
	bl pinOff
	
	mov r0, #0

	pop {pc}
	

setPinInput:		// Set a pin to take in input from the user (button)
	push {lr}
	mov r1, #INPUT
	bl pinMode	// Set the pin to take in input
	pop {pc}

setPinOutput:		// Set a pin to output something (the lights)
	push {lr}
	mov r1, #OUTPUT
	bl pinMode // Set the pin to output from r1
	pop {pc}

pinOn:			// Turn a pinOn for lights
	push {lr}
	mov r1, #HIGH
	bl digitalWrite	// Write the HIGH to a pin (ON)
	pop {pc}

pinOff:			// Turn a pinOff
	push {lr}
	mov r1, #LOW
	bl digitalWrite		// Write the LOW to a pin (OFF)
	pop {pc}

readStopButton:		// Read from the stop button
	push {lr}
	mov r0, #STP_PIN
	bl digitalRead
	pop {pc}

action:	// r1 holds pin to turn on or off
	// r2 holds the number of seconds to delay
	// return value: r0=0, no user interaction; r0=1 user pressed stop button
	push {r4,r5,lr}

	mov r4, r1
	mov r5, r2
	
	cmp r9, #-1	// If r9 == -1
	moveq r0, r4	// Turn the light off
	bleq pinOff

	cmp r9, #1	// If r9 == 1
	moveq r0, r4	// Turn the light on
	bleq pinOn

	mul r9, r8	// Toggle r9 to turn off/on by using r8

	mov r0, #0
	bl time		// Start timer

	mov r4, r0

do_whl:
	bl readStopButton	// see if the stop button was pressed
	cmp r0, #HIGH
	beq action_done	
	mov r0, #0		// Check the timer for flickering lights
	bl time

	sub r0, r0, r4 // r0 = time(0) - r4, new r0 is # of sec elapsed
	mov r1, #3	// Add modifier to increase flicker speed as levels increase
	
	sub r1, r1, r6	// get the difference between the max level and the current level to increase the flicker speed
	sub r0, r0, r1
	cmp r0, r5	// compare to see if the timer is done
	blt do_whl	// otherwise loop
	mov r0, #0
	
action_done:
	pop {r4,r5,pc}
	cmp r9, #0
	moveq r9, #1	// if r9 is 0, set to 1
