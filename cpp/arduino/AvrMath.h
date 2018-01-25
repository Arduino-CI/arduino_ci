//#include <math.h>
#pragma once

template <typename A> inline A abs(A x) { return x > 0 ? x : -x; }

//max
template <typename A> inline float max(A a, float b) { return a > b ? a : b; }
template <typename A> inline float max(float a, A b) { return a > b ? a : b; }
template <typename A, typename B> inline long max(A a, B b) { return a > b ? a : b; }

//min
template <typename A> inline float min(A a, float b) { return a < b ? a : b; }
template <typename A> inline float min(float a, A b) { return a < b ? a : b; }
template <typename A, typename B> inline long min(A a, B b) { return a < b ? a : b; }

//constrain
template <typename A> inline A constrain(A x, A a, A b)         { return max(a, min(b, x)); }

//map
template <typename A> inline A map(A x, A in_min, A in_max, A out_min, A out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

//sq
template <typename A> A inline sq(A x) { return x * x; }

// ??? too lazy to sort these now
//pow
//sqrt

// http://www.ganssle.com/approx.htm
// http://www.ganssle.com/approx/sincos.cpp
//cos
//sin
//tan

