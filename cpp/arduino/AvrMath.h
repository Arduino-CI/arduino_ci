#pragma once
#include <math.h>

#define constrain(x,l,h) ((x)<(l)?(l):((x)>(h)?(h):(x)))
#define map(x,inMin,inMax,outMin,outMax) (((x)-(inMin))*((outMax)-(outMin))/((inMax)-(inMin))+outMin)

#include "Forced.h"

#define sq(x) ((x)*(x))

#define radians(deg) ((deg)*DEG_TO_RAD)
#define degrees(rad) ((rad)*RAD_TO_DEG)


