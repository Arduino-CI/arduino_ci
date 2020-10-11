#pragma once

// ADCSRA is defined in the CPU specific header files
// like iom328p.h.
// It is liked to _SFR_MEM8 what does not exists in the test environment.
// Therefore we define _SFR_MEM8 here and provide it a storage
// location so that the test code can read/write on it.
extern unsigned char sfr_store;
#define _SFR_MEM8(mem_addr) sfr_store
