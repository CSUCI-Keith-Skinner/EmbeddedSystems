;****************** main.s ***************
; Program written by: Keith Skinner
; Date Created: 2/4/2017
; Last Modified: 9/26/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

KEITH_10_DC1 EQU 0x007A
KEITH_10_DC2 EQU 0x1200


    IMPORT  TExaS_Init
    THUMB
    AREA    DATA, ALIGN=2
;global variables go here
	

    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB
    EXPORT  Start
Start
; TExaS_Init sets bus clock at 80 MHz
    BL  TExaS_Init ; voltmeter, scope on PD3
; Initialization goes here
	
	; Make PE3 an output and make PE2 and PF4 inputs.
	; Activate clock for port E
	LDR R1, =SYSCTL_RCGCGPIO_R		; Grab clock location
	LDR R0, [R1]					; Grab clock value
	MOV R0, #0x10				    ; Bit 5 is for Port E
	STR R0, [R1]					; Store clock values turning on E
	NOP								; Wait part1
	NOP								; Wait part2
	
	; Set up direction register
	LDR R1, =GPIO_PORTE_DIR_R		; load port e configuration location
	MOV R0, #0x8				    ; set pin PE3 as output
	STR R0, [R1]					; Store configuration
	; Enable Port E digital port
	LDR R1, =GPIO_PORTE_DEN_R		; load port e configuration
	MOV R0, #0x8					; Make pin PE3 digital
	STR R0, [R1]					; Store configuration
	
    CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
	MOV R0, #0x007A
	LSL R0, #16
	ADD R0, R0, #0x1200
wait
	SUBS R0, R0, #1
	BNE wait
	
	;Write out to the LED
	EOR R1, R1, #0x8
	; Write R0 out to PORTE
	LDR R2, =GPIO_PORTE_DATA_R		; Pointer to Port E data
	STR R1, [R2]					; Write all of R0 out to Port E
   
    B    loop
	
    ALIGN      ; make sure the end of this section is aligned
	END        ; end of file

