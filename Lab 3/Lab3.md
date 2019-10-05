# Lab 3 / 4

![Logical Analyzer](4FlipsPerSec.PNG)

## Step 1

Setup 

```nasm
    ; Turn on clock for port E
    LDR  R1, =SYSCTL_RCGCGPIO_R     ; Grab clock location
    LDR  R0, [R1]                   ; Grab clock value
    MOV  R0, #0x10                  ; Bit 5 is for Port E
    STR  R0, [R1]                   ; Store clock values turning on E
    NOP                             ; Wait part1
    NOP                             ; Wait part2
    ; Set PE3 as output
    LDR  R1, =GPIO_PORTE_DIR_R      ; Grab direction location
    LDR  R0, [R1]                   ; Grab direction value
    MOV  R0, #0x8                   ; PE3 as output
    STR  R0, [R1]                   ; Store configuration
    ; Set PE3 as digital
    LDR  R1, =GPIO_PORTE_DEN_R      ; Grab enable register address
    LDR  R0, [R1]                   ; Grab enable register's value
    MOV  R0, #0x8                   ; Set PE3 Pin as enabled
    STR  R0, [R1]                   ; Set enable register as new value
```

Delay

$$ \frac{80Mhz}{1{sec}} \cdot \frac{1{sec}}{4\space{toggles}} \cdot \frac{1\space{toggle}}{4\space{cycles}} = 5000000{cycles}\space{per}\space{wait}  $$

$$ 5000000_{10} = 0x004C4B40_{16} $$

When attempting to move `0x4C4B40` into register 0, the compiler complains:
```main.s(82): error: A1871E: Immediate 0x004C4B40 cannot be represented by 0-255 shifted left by 0-23 or duplicated in all, odd or even bytes```
So I had to move half the value in (`0x4C`) then move the other half in after (`0x4B40`).

```nasm
delay
    MOV  R1, #0x4C                  ; Move high half of Dword into R1
    MOV  R0, #0x4B40                ; Move low half of Dword into R0
    ADD  R0, R0, R1, LSL #0x10      ; Merge the two
wait
    SUBS R0, R0, #0x01              ; (1 cycle)
    BNE  wait                       ; (3 cycles)
    BX   LR                         ; return
```

Main

