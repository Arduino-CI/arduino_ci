// Stub for testing that doesn't do anything (but at least compiles!)

#define wdt_disable() (void)0
#define wdt_enable(timeout) (void)0
#define wdt_reset() (void)0

#define WDTO_15MS 0
#define WDTO_30MS 1
#define WDTO_60MS 2
#define WDTO_120MS 3
#define WDTO_250MS 4
#define WDTO_500MS 5
#define WDTO_1S 6
#define WDTO_2S 7
#define WDTO_4S 8
#define WDTO_8S 9
