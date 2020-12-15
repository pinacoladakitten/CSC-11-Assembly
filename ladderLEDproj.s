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

.align 4
.text
.global main

main:
			//int main()
	push {lr}	//{
	bl wiringPiSetup // wiringPiSetup();  // initialize the wiringPi library

	mov r0, #STP_PIN
	bl setPinInput

	mov r0, #RED_PIN // pinMode(29, OUTPUT); // set the wpi 29 pin for the output 
	bl setPinOutput
	
	mov r0, #BLUE_PIN
	bl setPinOutput
	
	mov r0, #YLO_PIN
	bl setPinOutput

	mov r0, #GRN_PIN
	bl setPinOutput

lp:
	mov r0, #BLUE_PIN
	mov r1, #RED_PIN
	mov r2, #PAUSE_S
	bl action
	
	cmp r0, #1
	beq end_lp
	
	mov r0, #RED_PIN
	mov r1, #GRN_PIN
	mov r2, #PAUSE_S
	bl action

	cmp r0, #1
	beq end_lp

	mov r0, #GRN_PIN
	mov r1, #BLUE_PIN
	mov r2, #PAUSE_S
	bl action
	
	cmp r0, #1
	beq end_lp

	bal lp

end_lp:
	mov r0, #RED_PIN
	bl pinOff
	
	mov r0, #GRN_PIN
	bl pinOff

	mov r0, #BLUE_PIN
	bl pinOff

	mov r0, #0
	pop {pc}	

setPinInput:
	push {lr}
	mov r1, #INPUT
	bl pinMode
	pop {pc}

setPinOutput:
	push {lr}
	mov r1, #OUTPUT
	bl pinMode
	pop {pc}

pinOn:
	push {lr}
	mov r1, #HIGH
	bl digitalWrite
	pop {pc}

pinOff:
	push {lr}
	mov r1, #LOW
	bl digitalWrite
	pop {pc}

readStopButton:
	push {lr}
	mov r0, #STP_PIN
	bl digitalRead
	pop {pc}

action:	// r0 holds pin to turn off, r1 holds pin to turn on
	// r2 holds the number of seconds to delay
	// return value: r0=0, no user interaction; r0=1 user pressed stop button
	push {r4,r5,lr}

	mov r4, r1
	mov r5, r2
	
	bl pinOff
	mov r0, r4
	bl pinOn

	mov r0, #0
	bl time
	mov r4, r0

do_whl:
	bl readStopButton
	cmp r0, #HIGH
	beq action_done
	mov r0, #0
	bl time

	sub r0, r0, r4 // r0 = time(0) - r4, new r0 is # of sec elapsed
	cmp r0, r5
	blt do_whl
	mov r0, #0
	
action_done:
	pop {r4,r5,pc}
