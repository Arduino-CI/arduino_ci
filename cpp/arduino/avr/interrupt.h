/*
   This header file defines the macros required for the production
   code for AVR CPUs to declare ISRs in the test environment.
   See for more details
   https://www.nongnu.org/avr-libc/user-manual/group__avr__interrupts.html
*/
#pragma once

// Allows the production code to define an ISR method.
// These definitions come from the original avr/interrupt.h file
// https://www.nongnu.org/avr-libc/user-manual/interrupt_8h_source.html
#define _VECTOR(N) __vector_ ## N
#define ISR(vector, ...)            \
     extern "C" void vector (void)  __VA_ARGS__; \
     void vector (void)
