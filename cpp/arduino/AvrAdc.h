#pragma once

// mock storage to allow access to ADCSRA
extern unsigned char sfr_store;
#define _SFR_MEM8(mem_addr) sfr_store
