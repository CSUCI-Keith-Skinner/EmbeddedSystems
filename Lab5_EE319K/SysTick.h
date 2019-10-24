// SysTick.h
// Runs on TM4C123
// Provide functions that initialize the SysTick module
// Put your name here
// October 5, 2018
#ifndef __SYSTICK_H__
#define __SYSTICK_H__
#include <stdint.h>

// Initialize SysTick with busy wait running at bus clock.
void SysTick_Init(void);

// Time delay using busy wait.
// The delay parameter is in units of the core clock. (units of 12.5 nsec for 80 MHz clock)
void SysTick_Wait(uint32_t delay);

// The delay parameter is in ms.
void SysTick_Wait1ms(uint32_t delay);

// Time delay using busy wait.
// This assumes 80 MHz system clock.
void SysTick_Wait10ms(uint32_t delay);
#endif
