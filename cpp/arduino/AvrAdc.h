#ifndef _AVR_ADC_H_
#define _AVR_ADC_H_

// mock storage to allow access to ADCSRA
extern unsigned char sfr_store;
#define _SFR_MEM8(mem_addr) sfr_store

#endif // _AVR_ADC_H_
