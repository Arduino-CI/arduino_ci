#pragma once

// allows the production code to define an ISR method
#define _VECTOR(N) __vector_ ## N
#define ISR(vector, ...)            \
     extern "C" void vector (void)  __VA_ARGS__; \
     void vector (void)
