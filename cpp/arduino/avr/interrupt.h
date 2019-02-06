#ifndef _AVR_INTERRUPT_H_
#define _AVR_INTERRUPT_H_

// allows the production code to define an ISR method
#define _VECTOR(N) __vector_ ## N
#define ISR(vector, ...)            \
     extern "C" void vector (void)  __VA_ARGS__; \
     void vector (void)

#endif // _AVR_INTERRUPT_H_
