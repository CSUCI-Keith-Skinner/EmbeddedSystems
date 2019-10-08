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

; Lab constants for current step
LAB3_STEP_3_30_PERC  EQU  3000000
LAB3_STEP_3_20_PERC  EQU  2000000
LAB3_STEP_3_100_PERC EQU 10000000

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
	ORR  R0, #0x10                  ; Bit 5 is for Port E
	STR  R0, [R1]                   ; Store clock values turning on E
	NOP                             ; Wait part1
	NOP                             ; Wait part2
    ; Set PE3 as output
    LDR  R1, =GPIO_PORTE_DIR_R      ; Grab direction location
    LDR  R0, [R1]                   ; Grab direction value
	ORR  R0, #0x8                   ; PE3 as output
    AND  R0, #0xFFFFFFFB            ; PE2 as input
	STR  R0, [R1]                   ; Store configuration
    ; Set PE3 as digital
    LDR  R1, =GPIO_PORTE_DEN_R      ; Grab enable register address
    LDR  R0, [R1]                   ; Grab enable register's value
    ORR  R0, #0xC                   ; Set PE3 and PE2 Pin as enabled
    STR  R0, [R1]                   ; Set enable register as new value
    ; TExaS voltmeter, scope runs on interrupts
    CPSIE  I                        ; Turn on TExaS voltmeter

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; R0 = argument to delay
; R4 = Whether or not a button was pushed
; R5 = Current Duty Cycle
; R6 = How much to add when the button is pressed
; R7 = 100% duty cycle
main
    MOV  R4, #0                     ; Default value of button being pushed
    LDR  R5, =LAB3_STEP_3_30_PERC   ; DUTY CYCLE : Default duty cycle 30%@2Hz
    LDR  R6, =LAB3_STEP_3_20_PERC   ; DUTY CYCLE STEP : When button pressed, add this to R4
    LDR  R7, =LAB3_STEP_3_100_PERC  ; DUTY CYCLE MOD : Max Duty Cycle 100%@2Hz
loop                                ; ~~~~~~MAIN ENGINE GOES HERE~~~~~~~~
    BL   flip_PE3                   ; Flip the LED on
    MOV  R0, R5                     ; Set delay to the duty cycle
    BL   delay                      ; Delay (LED on)
    BL   flip_PE3                   ; Flip the LED (LED off)
    SUB  R0, R7, R5                 ; Set the delay to the duty cycle minus the total time
    BL   delay                      ; Delay (LED off)
    B    loop                       ; repeat
    

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; R0 = How much to delay by
; R1 = value of data register
; R2 = address of data register
; R3 = Unused
; R4 = Whether or not the button on PE2 was pressed
;   R4:0 is set while pressed
;   R4:1 is set when pressed
;   R4:0 is unset when released
;   R4: 0b0000 -> not pressed
;       0b0011 -> being pressed
;       0b0010 -> was pressed
; R5 = Current Duty Cycle
; R6 = How much to add when the button is pressed
; R7 = 100% duty cycle
delay
button_state
    LDR  R2, =GPIO_PORTE_DATA_R     ; Get the address of the data register
    LDR  R1, [R2]                   ; Get the value of the data register
    AND  R1, R1, #0x4               ; Isolate PE2
    CMP  R1, #0x4                   ; Is PE2 on?
    BEQ  button_state_pressed       ; PE2 is pressed
    AND  R4, R4, #0x2               ; PE2 not pressed -> turn off first bit in R4
    B    button_state_done          ; done 
button_state_pressed                
    ORR  R4, R4, #0x3               ; turn on the first 2 bits
button_state_done
update_duty                         
    AND R4, R4, #3                  ; Zero out all but the first 2 bits (not really neccessary is it?)
    CMP R4, #2                      ; Is the value currently 2
    BNE update_duty_done            ; If R4 != 2 then button not yet pressed or still being pressed
increment
    MOV R4, #0                      ; Clear R4
    ADD  R5, R5, R6                 ; Add 20% to the duty cycle
    CMP  R5, R7                     ; Is the duty cycle <= 100
    BLE  increment_done             ; We done
    SUB  R5, R5, R7                 ; duty cycle -= 100
increment_done
    MOV R0, #1                      ; Set R0 to no more delay
update_duty_done                    
    SUBS R0, R0, #5                ; Subtract 5 from R0 and set zero flag(1 cycle)(SUB does not set zero flag)
    BGT  delay                      ; Continue delay if R0 is not 0(3 cycles)
    BX   LR                         ; return (total 4 cycles)
    
flip_PE3
    LDR  R1, =GPIO_PORTE_DATA_R     ; Grab the address for the DATA register for Port E
    LDR  R0, [R1]                   ; Grab the value currently held by the DATA register for Port E
    EOR  R0, R0, #0x08              ; Flip the 4th bit for LED
    STR  R0, [R1]                   ; Store the new data value
    BX   LR                         ; return
    
    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file