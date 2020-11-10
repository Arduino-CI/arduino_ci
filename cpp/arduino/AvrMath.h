#pragma once
#include "ArduinoDefines.h"
#include <math.h>

#ifdef __cplusplus

  template <class Amt, class Low, class High>
  auto constrain(const Amt &amt, const Low &low, const High &high)
      -> decltype(amt < low ? low : (amt > high ? high : amt)) {
    return (amt < low ? low : (amt > high ? high : amt));
  }

  template <class X, class InMin, class InMax, class OutMin, class OutMax>
  auto map(const X &x, const InMin &inMin, const InMax &inMax,
          const OutMin &outMin, const OutMax &outMax)
      -> decltype((x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin) {
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  template <class T> auto radians(const T &deg) -> decltype(deg * DEG_TO_RAD) {
    return deg * DEG_TO_RAD;
  }

  template <class T> auto degrees(const T &rad) -> decltype(rad * RAD_TO_DEG) {
    return rad * RAD_TO_DEG;
  }

  template <class T> auto sq(const T &x) -> decltype(x * x) { return x * x; }

  template <class T> auto abs(const T &x) -> decltype(x > 0 ? x : -x) {
    return x > 0 ? x : -x;
  }

  template <class T, class L>
  auto min(const T &a, const L &b) -> decltype((b < a) ? b : a) {
    return (b < a) ? b : a;
  }

  template <class T, class L>
  auto max(const T &a, const L &b) -> decltype((b < a) ? b : a) {
    return (a < b) ? b : a;
  }

#else // __cplusplus

  #ifdef constrain
  #undef constrain
  #endif
  #define constrain(amt, low, high)                                              \
    ({                                                                           \
      __typeof__(amt) _amt = (amt);                                              \
      __typeof__(low) _low = (low);                                              \
      __typeof__(high) _high = (high);                                           \
      (amt < low ? low : (amt > high ? high : amt));                             \
    })

  #ifdef map
  #undef map
  #endif
  #define map(x, inMin, inMax, outMin, outMax)                                   \
    ({                                                                           \
      __typeof__(x) _x = (x);                                                    \
      __typeof__(inMin) _inMin = (inMin);                                        \
      __typeof__(inMax) _inMax = (inMax);                                        \
      __typeof__(outMin) _outMin = (outMin);                                     \
      __typeof__(outMax) _outMax = (outMax);                                     \
      (_x - _inMin) * (_outMax - _outMin) / (_inMax - _inMin) + _outMin;         \
    })

  #ifdef radians
  #undef radians
  #endif
  #define radians(deg)                                                           \
    ({                                                                           \
      __typeof__(deg) _deg = (deg);                                              \
      _deg *DEG_TO_RAD;                                                          \
    })

  #ifdef degrees
  #undef degrees
  #endif
  #define degrees(rad)                                                           \
    ({                                                                           \
      __typeof__(rad) _rad = (rad);                                              \
      _rad *RAD_TO_DEG;                                                          \
    })

  #ifdef sq
  #undef sq
  #endif
  #define sq(x)                                                                  \
    ({                                                                           \
      __typeof__(x) _x = (x);                                                    \
      _x *_x;                                                                    \
    })

  #ifdef abs
  #undef abs
  #endif
  #define abs(x)                                                                 \
    ({                                                                           \
      __typeof__(x) _x = (x);                                                    \
      _x > 0 ? _x : -_x;                                                         \
    })

  #ifdef min
  #undef min
  #endif
  #define min(a, b)                                                              \
    ({                                                                           \
      __typeof__(a) _a = (a);                                                    \
      __typeof__(b) _b = (b);                                                    \
      _a < _b ? _a : _b;                                                         \
    })

  #ifdef max
  #undef max
  #endif
  #define max(a, b)                                                              \
    ({                                                                           \
      __typeof__(a) _a = (a);                                                    \
      __typeof__(b) _b = (b);                                                    \
      _a > _b ? _a : _b;                                                         \
    })

#endif
