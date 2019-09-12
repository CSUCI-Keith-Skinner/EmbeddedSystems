;****************** main.s ***************
; Program initially written by: Yerraballi and Valvano
; Author: Keith Skinner
; Date Created: 1/15/2018 
; Last Modified: 9/12/2019
; Brief description of the program: Spring 2019 Lab1
; The objective of this system is to implement odd-bit counting system
; Hardware connections: 
;  Output is positive logic, 1 turns on the LED, 0 turns off the LED
;  Inputs are negative logic, meaning switch not pressed is 1, pressed is 0
;    PE0 is an input 
;    PE1 is an input 
;    PE2 is an input 
;    PE3 is the output
; Overall goal: 
;   Make the output 1 if there is an odd number of 1's at the inputs, 
;     otherwise make the output 0
; The specific operation of this system 
;   Initialize Port E to make PE0,PE1,PE2 inputs and PE3 an output
;   Over and over, read the inputs, calculate the result and set the output

; NOTE: Do not use any conditional branches in your solution. 
;       We want you to think of the solution in terms of logical and shift operations

GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_DEN_R   EQU 0x4002451C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

      THUMB
      AREA    DATA, ALIGN=2
;global variables go here
      ALIGN
      AREA    |.text|, CODE, READONLY, ALIGN=2
      EXPORT  Start
Start
	; Activate clock for port E
	LDR R1, =SYSCTL_RCGCGPIO_R    ; Grab clock location
	LDR R0, [R1]                  ; Grab clock value
	MOV R0, #0x10                 ; Bit 5 is for Port E
	STR R0, [R1]                  ; Store clock values turning on E
	NOP                           ; Wait part1
	NOP                           ; Wait part2
	; Set up direction register
	LDR R1, =GPIO_PORTE_DIR_R     ; Grab direction location
	MOV R0, #0x8                  ; Sets pins PE0-2 as input and PE03 as output
	STR R0, [R1]                  ; Store configuration
	; Enable Port E digital port
	LDR R1, =GPIO_PORTE_DEN_R     ; Pointer to Digital/Analog Options
	MOV R0, #0xF                  ; Make Ports PE0-3 digital
	STR R0, [R1]                  ; Store configuration
	
loop
	; Read PORTE into R0
	LDR R1, =GPIO_PORTE_DATA_R    ; Pointer to Port E data
	LDR R0, [R1]                  ; Read all of Port E into R0
	;Meat of the work here
	MVN R0, R0                    ; invert R0 to make odd parity
	MOV R1, R0                    ; Copy R1 into R0
	LSL R0, R0, #3                ; Shift R0 to the left 3 times (PE0->PE3)
	EOR R0, R0, R1, LSL #2        ; XOR R0 and R1 into R0 after shifting R1 x2
	EOR R0, R0, R1, LSL #1        ; XOR R0 and R1 into R0 after shifting R1 x1
	
	; Write R0 out to PORTE
	LDR R1, =GPIO_PORTE_DATA_R    ; Pointer to Port E data
	STR R0, [R1]                  ; Write all of R0 out to Port E
  
	B    loop						          ; jump to top of loop
  ALIGN                         ; make sure the end of this section is aligned
  END                           ; end of file
  
