#pragma once
#include <math.h>

#define constrain(x,l,h) ((x)<(l)?(l):((x)>(h)?(h):(x)))
#define map(x,inMin,inMax,outMin,outMax) (((x)-(inMin))*((outMax)-(outMin))/((inMax)-(inMin))+outMin)

#define sq(x) ((x)*(x))

#define radians(deg) ((deg)*DEG_TO_RAD)
#define degrees(rad) ((rad)*RAD_TO_DEG)

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

