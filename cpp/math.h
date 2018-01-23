//abs
long abs(long x)     { return x > 0 ? x : -x; }
double fabs(double x) { return x > 0 ? x : -x; }

//max
long max(long a, long b)       { return a > b ? a : b; }
double fmax(double a, double b) { return a > b ? a : b; }

//min
long min(long a, long b)       { return a < b ? a : b; }
double fmin(double a, double b) { return a < b ? a : b; }

//constrain
long constrain(long x, long a, long b)         { return max(a, min(b, x)); }
double constrain(double x, double a, double b) { return max(a, min(b, x)); }

//map
long map(long x, long in_min, long in_max, long out_min, long out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

double map(double x, double in_min, double in_max, double out_min, double out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

//sq
long sq(long x)     { return x * x; }
double sq(double x) { return x * x; }

// ??? too lazy to sort these now
//pow
//sqrt

// http://www.ganssle.com/approx.htm
// http://www.ganssle.com/approx/sincos.cpp
//cos
//sin
//tan

