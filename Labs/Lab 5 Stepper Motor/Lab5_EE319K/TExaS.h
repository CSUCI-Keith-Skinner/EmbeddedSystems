// TExaS.h
// Runs on TM4C123
// Periodic timer interrupt data collection
// PLL turned on at 80 MHz
// Implements Logic Analyzer on Port B, D, or E
//

// Jonathan Valvano. Daniel Valvano
// August 29, 2018

/* This example accompanies the book
   "Embedded Systems: Real Time Operating Systems for ARM Cortex M Microcontrollers",
   ISBN: 978-1466468863, Jonathan Valvano, copyright (c) 2018
   Section 6.4.5, Program 6.1

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
#ifndef __TEXAS_H__
#define __TEXAS_H__
// ************TExaS_Init*****************
// Initialize grader, 7-bit logic analyzer on timer 5A 100us
// sets PLL to 80 MHz
// This needs to be called once
// Inputs: function to send data
// This will only activate clock, user sets direction and other modes
// Outputs: none
void TExaS_Init(void(*task)(void));
  

// ************TExaS_Stop*****************
// Stop the transfer 
// Inputs:  none
// Outputs: none
void TExaS_Stop(void);

void PLL_Init(void); // set clock to 80 MHz (without logic analyzer functions)

#endif
