// Stuff where we very explicitly override std C++
// Note lack of "pragma once"

#ifdef abs
#undef abs
#endif
#define abs(x) ((x)>0?(x):-(x))

#ifdef max
#undef max
#endif
#define max(a,b) ((a)>(b)?(a):(b))

#ifdef min
#undef min
#endif
#define min(a,b) ((a)<(b)?(a):(b))
