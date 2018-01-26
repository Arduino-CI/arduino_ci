#include "AvrMath.h"

// pow
// https://stackoverflow.com/a/9681676/2063546
float nth_root(float A, int n) {
    const int K = 6;
    float x[K] = {1};
    for (int k = 0; k < K - 1; k++)
        x[k + 1] = (1.0 / n) * ((n - 1) * x[k] + A / pow(x[k], n - 1));
    return x[K-1];
}

float pow(float base, float ex){
    if (base == 0)
        return 0;
    // power of 0
    if (ex == 0){
        return 1;
    // negative exponenet
    }else if( ex < 0){
        return 1 / pow(base, -ex);
    // fractional exponent
    }else if (ex > 0 && ex < 1){
        return nth_root(base, 1/ex);
    }else if ((int)ex % 2 == 0){
        float half_pow = pow(base, ex/2);
        return half_pow * half_pow;
    //integer exponenet
    }else{
        return base * pow(base, ex - 1);
    }
}

float sqrt(float x) { return nth_root(x, 2); }


// http://www.ganssle.com/approx.htm
// http://www.ganssle.com/approx/sincos.cpp

// Math constants we'll use
double const pi=3.1415926535897932384626433;	// pi
double const twopi=2.0*pi;                // pi times 2
double const two_over_pi= 2.0/pi;         // 2/pi
double const halfpi=pi/2.0;               // pi divided by 2
double const threehalfpi=3.0*pi/2.0;      // pi times 3/2, used in tan routines
double const four_over_pi=4.0/pi;         // 4/pi, used in tan routines


double cos_121s(double x)
{
  const double c1= 0.99999999999925182;
  const double c2=-0.49999999997024012;
  const double c3= 0.041666666473384543;
  const double c4=-0.001388888418000423;
  const double c5= 0.0000248010406484558;
  const double c6=-0.0000002752469638432;
  const double c7= 0.0000000019907856854;

  double x2 = x * x;// The input argument squared
  return (c1 + x2*(c2 + x2*(c3 + x2*(c4 + x2*(c5 + x2*(c6 + c7*x2))))));
}

double cos(double x){
	x = fmod(x, twopi);  // Get rid of values > 2* pi
	if(x<0)x=-x;         // cos(-x) = cos(x)
	switch ((int)(x * two_over_pi)){
	case 0: return  cos_121s(x);
	case 1: return -cos_121s(pi-x);
	case 2: return -cos_121s(x-pi);
	case 3: return  cos_121s(twopi-x);
	}
}

double sin(double x){
	return cos(halfpi-x);
}

double tan_14s(double x)
{
  const double c1=-34287.4662577359568109624;
  const double c2=  2566.7175462315050423295;
  const double c3=-   26.5366371951731325438;
  const double c4=-43656.1579281292375769579;
  const double c5= 12244.4839556747426927793;
  const double c6=-  336.611376245464339493;

  double x2 = x * x;  // The input argument squared

  x2=x * x;
  return (x*(c1 + x2*(c2 + x2*c3))/(c4 + x2*(c5 + x2*(c6 + x2))));
}

//
double tan(double x){
	int octant;						// what octant are we in?

	x=fmod(x, twopi);				// Get rid of values >2 *pi
	octant=int(x * four_over_pi);			// Get octant # (0 to 7)
	switch (octant){
	case 0: return      tan_14s(x              *four_over_pi);
	case 1: return  1.0/tan_14s((halfpi-x)     *four_over_pi);
	case 2: return -1.0/tan_14s((x-halfpi)     *four_over_pi);
	case 3: return -    tan_14s((pi-x)         *four_over_pi);
	case 4: return      tan_14s((x-pi)         *four_over_pi);
	case 5: return  1.0/tan_14s((threehalfpi-x)*four_over_pi);
	case 6: return -1.0/tan_14s((x-threehalfpi)*four_over_pi);
	case 7: return -    tan_14s((twopi-x)      *four_over_pi);
	}
}


