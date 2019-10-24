// TExaS.c
// Runs on TM4C123
// Periodic timer interrupt data collection
// PLL turned on at 80 MHz
// Implements Logic Analyzer on Port B, D, or E
//
// Jonathan Valvano. Daniel Valvano
// August 29, 2018

/* This example accompanies the book
   "Embedded Systems: Introduction to ARM Cortex M Microcontrollers",
   ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2018

 Copyright 2018 by Jonathan W. Valvano, valvano@mail.utexas.edu
    You may use, edit, run or distribute this file
    as long as the above copyright notice remains
 THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
 OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
 VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
 OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 For more information about my classes, my research, and my books, see
 http://users.ece.utexas.edu/~valvano/
 */

// Timer5A periodic interrupt implements logic analyzer
void PLL_Init(void);

void UART0_Init(void);

volatile unsigned long *PortDataAddr; // pointer to data


//*****************************************************************************
//
// I/O ports so students do not have to include port header file
//
//*****************************************************************************
#define SYSCTL_RCGCGPIO_R       (*((volatile unsigned long *)0x400FE608))
#define SYSCTL_RCGCTIMER_R      (*((volatile unsigned long *)0x400FE604))

#define NVIC_PRI17_R            (*((volatile unsigned long *)0xE000E444))
#define NVIC_PRI23_R            (*((volatile unsigned long *)0xE000E45C))
#define NVIC_EN2_R              (*((volatile unsigned long *)0xE000E108))
#define NVIC_DIS2_R             (*((volatile unsigned long *)0xE000E188))


#define TIMER5_CFG_R            (*((volatile unsigned long *)0x40035000))
#define TIMER5_TAMR_R           (*((volatile unsigned long *)0x40035004))
#define TIMER5_TBMR_R           (*((volatile unsigned long *)0x40035008))
#define TIMER5_CTL_R            (*((volatile unsigned long *)0x4003500C))
#define TIMER5_SYNC_R           (*((volatile unsigned long *)0x40035010))
#define TIMER5_IMR_R            (*((volatile unsigned long *)0x40035018))
#define TIMER5_RIS_R            (*((volatile unsigned long *)0x4003501C))
#define TIMER5_MIS_R            (*((volatile unsigned long *)0x40035020))
#define TIMER5_ICR_R            (*((volatile unsigned long *)0x40035024))
#define TIMER5_TAILR_R          (*((volatile unsigned long *)0x40035028))
#define TIMER5_TBILR_R          (*((volatile unsigned long *)0x4003502C))
#define TIMER5_TAMATCHR_R       (*((volatile unsigned long *)0x40035030))
#define TIMER5_TBMATCHR_R       (*((volatile unsigned long *)0x40035034))
#define TIMER5_TAPR_R           (*((volatile unsigned long *)0x40035038))
#define TIMER5_TBPR_R           (*((volatile unsigned long *)0x4003503C))
#define TIMER5_TAPMR_R          (*((volatile unsigned long *)0x40035040))
#define TIMER5_TBPMR_R          (*((volatile unsigned long *)0x40035044))
#define TIMER5_TAR_R            (*((volatile unsigned long *)0x40035048))
#define TIMER5_TBR_R            (*((volatile unsigned long *)0x4003504C))
#define TIMER5_TAV_R            (*((volatile unsigned long *)0x40035050))
#define TIMER5_TBV_R            (*((volatile unsigned long *)0x40035054))
#define TIMER5_RTCPD_R          (*((volatile unsigned long *)0x40035058))
#define TIMER5_TAPS_R           (*((volatile unsigned long *)0x4003505C))
#define TIMER5_TBPS_R           (*((volatile unsigned long *)0x40035060))
#define TIMER5_TAPV_R           (*((volatile unsigned long *)0x40035064))
#define TIMER5_TBPV_R           (*((volatile unsigned long *)0x40035068))
#define TIMER5_PP_R             (*((volatile unsigned long *)0x40035FC0))
#define GPIO_PORTA_DATA_R       (*((volatile unsigned long *)0x400043FC))
#define GPIO_PORTB_DATA_R       (*((volatile unsigned long *)0x400053FC))
#define GPIO_PORTE_DATA_R       (*((volatile unsigned long *)0x400243FC))
#define GPIO_PORTF_DATA_R       (*((volatile unsigned long *)0x400253FC))
#define GPIO_PORTD_DATA_R       (*((volatile unsigned long *)0x400073FC))


void (*sendDataPt)(void);

// ************TExaS_Init*****************
// Initialize grader, 7-bit logic analyzer on timer 5A 100us
// sets PLL to 80 MHz
// This needs to be called once
// Inputs: function to send data
// This will only activate clock, user sets direction and other modes
// Outputs: none
void TExaS_Init(void(*task)(void)){
  PLL_Init();     // PLL on at 80 MHz
	sendDataPt = task;
 /* if(port==0){
    SYSCTL_RCGCGPIO_R |= 1;   // Port A
    PortDataAddr = ((volatile unsigned long *)0x400043FC); // GPIO_PORTA_DATA_R
  }else if(port==1){
    SYSCTL_RCGCGPIO_R |= 2;   // Port B
    PortDataAddr = ((volatile unsigned long *)0x400053FC); // GPIO_PORTB_DATA_R
  }else if(port==3){
    SYSCTL_RCGCGPIO_R |= 8;   // Port D
    PortDataAddr = ((volatile unsigned long *)0x400073FC); //GPIO_PORTD_DATA_R
  }else if(port==4){
    SYSCTL_RCGCGPIO_R |= 0x10;   // Port E
    PortDataAddr = ((volatile unsigned long *)0x400243FC); //GPIO_PORTE_DATA_R
  }else if(port==5){
    SYSCTL_RCGCGPIO_R |= 0x20;   // Port F
    PortDataAddr = ((volatile unsigned long *)0x400253FC); // GPIO_PORTF_DATA_R
  }else{
    return; // bad input
  }
  */
  SYSCTL_RCGCTIMER_R |= 0x20;      // 0) activate timer5
  UART0_Init();                    // UART0 is connected to TExaSdisplay
  TIMER5_CTL_R = 0x00000000;       // 1) disable timer5A during setup
  TIMER5_CFG_R = 0x00000000;       // 2) configure for 32-bit mode
  TIMER5_TAMR_R = 0x00000002;      // 3) configure for periodic mode, default down-count settings
  TIMER5_TAILR_R = 7999;           // 4) 100us reload value
  TIMER5_TAPR_R = 0;               // 5) bus clock resolution
  TIMER5_ICR_R = 0x00000001;       // 6) clear timer5A timeout flag
  TIMER5_IMR_R = 0x00000001;       // 7) arm timeout interrupt
  NVIC_PRI23_R = (NVIC_PRI23_R&0xFFFFFF00)|0x00000040; // 8) priority 2
// interrupts enabled in the main program after all devices initialized
// vector number 108, interrupt number 92
  NVIC_EN2_R = 0x10000000;         // 9) enable interrupt 92 in NVIC
  TIMER5_CTL_R = 0x00000001;       // 10) enable timer5A
}

#define UART0_DR_R              (*((volatile unsigned long *)0x4000C000))
// Timer5 implements the logic analyzer
// Sends 7-bit data to PC running TExaSdisplay via the USB cable
void Timer5A_Handler(void){
  TIMER5_ICR_R = 0x00000001;         // acknowledge timer5A timeout
 (*sendDataPt)();
//  UART0_DR_R = (*PortDataAddr)|0x80; // send digital data to TExaSdisplay
}


// ************TExaS_Stop*****************
// Stop the transfer
// Inputs:  none
// Outputs: none
void TExaS_Stop(void){
  NVIC_DIS2_R = 0x10000000;       // 9) disable interrupt 92 in NVIC
  TIMER5_CTL_R = 0x00000000;      // 10) disable timer5A
}


// The #define statement SYSDIV2 in PLL.h
// initializes the PLL to the desired frequency.

// bus frequency is 400MHz/(SYSDIV2+1) = 400MHz/(4+1) = 80 MHz
// see the table at the end of this file

#define SYSCTL_RIS_R            (*((volatile unsigned long *)0x400FE050))
#define SYSCTL_RIS_PLLLRIS      0x00000040  // PLL Lock Raw Interrupt Status
#define SYSCTL_RCC_R            (*((volatile unsigned long *)0x400FE060))
#define SYSCTL_RCC_XTAL_M       0x000007C0  // Crystal Value
#define SYSCTL_RCC_XTAL_6MHZ    0x000002C0  // 6 MHz Crystal
#define SYSCTL_RCC_XTAL_8MHZ    0x00000380  // 8 MHz Crystal
#define SYSCTL_RCC_XTAL_16MHZ   0x00000540  // 16 MHz Crystal
#define SYSCTL_RCC2_R           (*((volatile unsigned long *)0x400FE070))
#define SYSCTL_RCC2_USERCC2     0x80000000  // Use RCC2
#define SYSCTL_RCC2_DIV400      0x40000000  // Divide PLL as 400 MHz vs. 200
                                            // MHz
#define SYSCTL_RCC2_SYSDIV2_M   0x1F800000  // System Clock Divisor 2
#define SYSCTL_RCC2_SYSDIV2LSB  0x00400000  // Additional LSB for SYSDIV2
#define SYSCTL_RCC2_PWRDN2      0x00002000  // Power-Down PLL 2
#define SYSCTL_RCC2_BYPASS2     0x00000800  // PLL Bypass 2
#define SYSCTL_RCC2_OSCSRC2_M   0x00000070  // Oscillator Source 2
#define SYSCTL_RCC2_OSCSRC2_MO  0x00000000  // MOSC
// The #define statement SYSDIV2 initializes
// the PLL to the desired frequency.
#define SYSDIV2 4
// bus frequency is 400MHz/(SYSDIV2+1) = 400MHz/(4+1) = 80 MHz

// configure the system to get its clock from the PLL
void PLL_Init(void){
  // 0) configure the system to use RCC2 for advanced features
  //    such as 400 MHz PLL and non-integer System Clock Divisor
  SYSCTL_RCC2_R |= SYSCTL_RCC2_USERCC2;
  // 1) bypass PLL while initializing
  SYSCTL_RCC2_R |= SYSCTL_RCC2_BYPASS2;
  // 2) select the crystal value and oscillator source
  SYSCTL_RCC_R &= ~SYSCTL_RCC_XTAL_M;   // clear XTAL field
  SYSCTL_RCC_R += SYSCTL_RCC_XTAL_16MHZ;// configure for 16 MHz crystal
  SYSCTL_RCC2_R &= ~SYSCTL_RCC2_OSCSRC2_M;// clear oscillator source field
  SYSCTL_RCC2_R += SYSCTL_RCC2_OSCSRC2_MO;// configure for main oscillator source
  // 3) activate PLL by clearing PWRDN
  SYSCTL_RCC2_R &= ~SYSCTL_RCC2_PWRDN2;
  // 4) set the desired system divider and the system divider least significant bit
  SYSCTL_RCC2_R |= SYSCTL_RCC2_DIV400;  // use 400 MHz PLL
  SYSCTL_RCC2_R = (SYSCTL_RCC2_R&~0x1FC00000) // clear system clock divider field
                  + (SYSDIV2<<22);      // configure for 80 MHz clock
  // 5) wait for the PLL to lock by polling PLLLRIS
  while((SYSCTL_RIS_R&SYSCTL_RIS_PLLLRIS)==0){};
  // 6) enable use of PLL by clearing BYPASS
  SYSCTL_RCC2_R &= ~SYSCTL_RCC2_BYPASS2;
}

#define GPIO_PORTA_AFSEL_R      (*((volatile unsigned long *)0x40004420))
#define GPIO_PORTA_DEN_R        (*((volatile unsigned long *)0x4000451C))
#define GPIO_PORTA_AMSEL_R      (*((volatile unsigned long *)0x40004528))
#define GPIO_PORTA_PCTL_R       (*((volatile unsigned long *)0x4000452C))
#define UART0_FR_R              (*((volatile unsigned long *)0x4000C018))
#define UART0_IBRD_R            (*((volatile unsigned long *)0x4000C024))
#define UART0_FBRD_R            (*((volatile unsigned long *)0x4000C028))
#define UART0_LCRH_R            (*((volatile unsigned long *)0x4000C02C))
#define UART0_CTL_R             (*((volatile unsigned long *)0x4000C030))
#define UART0_CC_R              (*((volatile unsigned long *)0x4000CFC8))
#define UART_FR_TXFF            0x00000020  // UART Transmit FIFO Full
#define UART_FR_RXFE            0x00000010  // UART Receive FIFO Empty
#define UART_LCRH_WLEN_8        0x00000060  // 8 bit word length
#define UART_LCRH_FEN           0x00000010  // UART Enable FIFOs
#define UART_CTL_UARTEN         0x00000001  // UART Enable
#define UART_CC_CS_M            0x0000000F  // UART Baud Clock Source
#define UART_CC_CS_SYSCLK       0x00000000  // The system clock (default)
#define SYSCTL_RCGCUART_R       (*((volatile unsigned long *)0x400FE618))
#define SYSCTL_RCGC1_R          (*((volatile unsigned long *)0x400FE104))
#define SYSCTL_RCGC2_R          (*((volatile unsigned long *)0x400FE108))
#define SYSCTL_RCGC1_UART0      0x00000001  // UART0 Clock Gating Control
#define SYSCTL_RCGC2_GPIOA      0x00000001  // port A Clock Gating Control
#define SYSCTL_PRGPIO_R         (*((volatile unsigned long *)0x400FEA08))
#define SYSCTL_PRUART_R         (*((volatile unsigned long *)0x400FEA18))
#define SYSCTL_PRGPIO_R0        0x00000001  // GPIO Port A Peripheral Ready
#define SYSCTL_PRUART_R0        0x00000001  // UART Module 0 Peripheral Ready
//------------UART0_Init------------
// Initialize the UART for 115,200 baud rate (assuming 80 MHz UART clock),
// 8 bit word length, no parity bits, one stop bit, FIFOs enabled
// Input: none
// Output: none
void UART0_Init(void){volatile unsigned long delay;
  SYSCTL_RCGCUART_R |= 0x01; // activate UART0
  SYSCTL_RCGCGPIO_R |= SYSCTL_RCGC2_GPIOA; // activate port A
                                        // wait for clock to stabilize
//  while((SYSCTL_PRUART_R&SYSCTL_PRUART_R0) == 0){};
  delay = SYSCTL_RCGCGPIO_R;
  delay = SYSCTL_RCGCGPIO_R;
  UART0_CTL_R &= ~UART_CTL_UARTEN;      // disable UART
  UART0_IBRD_R = 43;                    // IBRD = int(80,000,000 / (16 * 115200)) = int(43.402778)
  UART0_FBRD_R = 26;                    // FBRD = round(0.402778 * 64) = 26
                                        // 8 bit word length (no parity bits, one stop bit, FIFOs)
  UART0_LCRH_R = (UART_LCRH_WLEN_8|UART_LCRH_FEN);
  UART0_CC_R &= ~UART_CC_CS_M;          // clear baud clock control field
  UART0_CC_R |= UART_CC_CS_SYSCLK;      // configure for system clock
  UART0_CTL_R |= UART_CTL_UARTEN;       // enable UART
//  while((SYSCTL_PRGPIO_R&SYSCTL_PRGPIO_R0) == 0){};
  GPIO_PORTA_AFSEL_R |= 0x03;           // enable alt funct on PA1-0
  GPIO_PORTA_DEN_R |= 0x03;             // enable digital I/O on PA1-0
                                        // configure PA1-0 as UART
  GPIO_PORTA_PCTL_R = (GPIO_PORTA_PCTL_R&0xFFFFFF00)+0x00000011;
  GPIO_PORTA_AMSEL_R &= ~0x03;          // disable analog functionality on PA
}



