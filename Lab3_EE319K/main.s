;****************** main.s ***************
; Program written by: Keith Skinner
; Date Created: 2/4/2017
; Last Modified: 9/2/2019

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
GPIO_LOCK_KEY      EQU 0x4C4F434B   ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

; Lab related constants
;LAB3_STEP_1_50_PERC  EQU  5000000
;LAB3_STEP_2_30_PERC  EQU  3000000
;LAB3_STEP_2_70_PERC  EQU  7000000
;LAB3_STEP_3_30_PERC  EQU  3000000
;LAB3_STEP_3_20_PERC  EQU  2000000
;LAB3_STEP_3_100_PERC EQU 10000000

; Lab constants for current step
LAB3_STEP_5_100_PERC EQU 400000
LAB3_STEP_5_1_PERC   EQU   4000 
SW1       EQU 0x10                 ; on the left side of the Launchpad board
SW2       EQU 0x01                 ; on the right side of the Launchpad board    


    IMPORT  TExaS_Init
    THUMB
    AREA    DATA, ALIGN=2
    ;global variables go here
    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB
    EXPORT  Start
        
Start
setup
    ; TExaS_Init sets bus clock at 80 MHz
    BL  TExaS_Init                  ; voltmeter, scope on PD3
    ; Turn on clock for port E
    LDR  R1, =SYSCTL_RCGCGPIO_R     ; Grab clock location
	LDR  R0, [R1]                   ; Grab clock value
	ORR  R0, #0x30                  ; Bit 5 is for Port E Bit 6 is for Port F
	STR  R0, [R1]                   ; Store clock values turning on E
	NOP                             ; Wait part1
	NOP                             ; Wait part2
    ; Set PE3 as output
    LDR  R1, =GPIO_PORTE_DIR_R      ; Grab direction location
    LDR  R0, [R1]                   ; Grab direction value
	ORR  R0, #0x8                   ; PE3 as output
	STR  R0, [R1]                   ; Store configuration
    ; Set PE3 as digital
    LDR  R1, =GPIO_PORTE_DEN_R      ; Grab enable register address
    LDR  R0, [R1]                   ; Grab enable register's value
    ORR  R0, R0, #0x8               ; Set PE3 as enabled
    STR  R0, [R1]                   ; Set enable register as new value
    
    ;~~~~~~~~Taken from "http://users.ece.utexas.edu/~valvano/arm/Switch_4C123asm.zip"~~~~~~~~~
    ; unlock the lock register
    LDR R1, =GPIO_PORTF_LOCK_R      ; R1 = &GPIO_PORTF_LOCK_R
    LDR R0, =GPIO_LOCK_KEY          ; R0 = GPIO_LOCK_KEY (unlock GPIO Port F Commit Register)
    STR R0, [R1]                    ; [R1] = R0 = 0x4C4F434B
    ; set commit register
    LDR R1, =GPIO_PORTF_CR_R        ; R1 = &GPIO_PORTF_CR_R
    MOV R0, #0xFF                   ; R0 = 0x01 (enable commit for PF0)
    STR R0, [R1]                    ; [R1] = R0 = 0x1
    ; set direction register
    LDR R1, =GPIO_PORTF_DIR_R       ; R1 = &GPIO_PORTF_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #(SW1+SW2)          ; R0 = R0&~(SW1|SW2) (make PF0 and PF4 input; PF0 and PF4 built-in buttons)
    STR R0, [R1]                    ; [R1] = R0
    ; regular port function
    LDR R1, =GPIO_PORTF_AFSEL_R     ; R1 = &GPIO_PORTF_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #(SW1+SW2)          ; R0 = R0&~(SW1|SW2) (disable alt funct on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; put a delay here if you are seeing erroneous NMI
    ; enable pull-up resistors
    LDR R1, =GPIO_PORTF_PUR_R       ; R1 = &GPIO_PORTF_PUR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(SW1+SW2)          ; R0 = R0|(SW1|SW2) (enable weak pull-up on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; enable digital port
    LDR R1, =GPIO_PORTF_DEN_R       ; R1 = &GPIO_PORTF_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #(SW1+SW2)          ; R0 = R0|(SW1|SW2) (enable digital I/O on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ; TExaS voltmeter, scope runs on interrupts
    CPSIE  I                        ; Turn on TExaS voltmeter
    
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; R0 = argument to delay
; R5 = Current Duty Cycle
; R6 = How much to add at the end of each tick
; R7 = 100% duty cycle
main
    MOV  R4, #0                     ; Default value of button being pushed
    LDR  R5, =LAB3_STEP_5_1_PERC    ; DUTY CYCLE : Default duty cycle 1%@100Hz
    LDR  R6, =LAB3_STEP_5_1_PERC    ; DUTY CYCLE STEP : When button pressed, add this to R4
    LDR  R7, =LAB3_STEP_5_100_PERC  ; DUTY CYCLE MOD : Max Duty Cycle 100%@2Hz
loop                                ; ~~~~~~MAIN ENGINE GOES HERE~~~~~~~~
    LDR  R1, =GPIO_PORTF_DATA_R     ; get the address to the data register
    LDR  R0, [R1]                   ; get the value of the data register
    AND  R0, #0x10                  ; check if 4th bit is on
    CMP  R0, #0                     ; if it is on
    BNE  loop                       ; do nothing
    
    ADD  R5, R6                     ; Increment the duty cycle
    CMP  R5, R7                     ; Check to see if the cycle has hit the upper bound
    BEQ  twoscomplement             ; R6 := -R6
    CMP  R5, #0                     ; Check to see if the cycle has hit the lower bound
    BEQ  twoscomplement             ; R6 := -R6
    B    goon                       ; Continue
twoscomplement
    MVN  R6, R6                     ; Bit-Wise Not
    ADD  R6, R6, #1                 ; Add 1
goon
    BL   flip_PE3                   ; Flip the LED on
    MOV  R0, R5                     ; Set delay to the duty cycle
    BL   delay                      ; Delay (LED on)
    
    BL   flip_PE3                   ; Flip the LED (LED off)
    SUB  R0, R7, R5                 ; Set the delay to the duty cycle minus the total time
    BL   delay                      ; Delay (LED off)
    B    loop                       ; repeat
    

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; R0 = How much to delay by
delay                
    SUBS R0, R0, #1                 ; Subtract 1 from R0 and set zero flag(1 cycle)(SUB does not set zero flag)
    BGT  delay                      ; Continue delay if R0 is not 0(3 cycles)
    BX   LR                         ; return (total 4 cycles)

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; R1 = address for the data register
; 
flip_PE3
    LDR  R1, =GPIO_PORTE_DATA_R     ; Grab the address for the DATA register for Port E
    LDR  R0, [R1]                   ; Grab the value currently held by the DATA register for Port E
    EOR  R0, R0, #0x08              ; Flip the 4th bit for LED
    STR  R0, [R1]                   ; Store the new data value
    BX   LR                         ; return
    
    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file