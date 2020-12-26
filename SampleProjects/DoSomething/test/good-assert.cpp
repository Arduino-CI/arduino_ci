#include <ArduinoUnitTests.h>
#include "../do-something.h"

class NonOrderedType {
  public:
    int x; // ehh why not
    NonOrderedType(int some_x) : x(some_x) {}

    bool operator==(const NonOrderedType &that) const {
      return that.x == x;
    }

    bool operator!=(const NonOrderedType &that) const {
      return that.x != x;
    }
};
inline std::ostream& operator << ( std::ostream& out, const NonOrderedType& n ) {
  out << "NonOrderedType(" << n.x << ")";
  return out;
}


unittest(assert_equal_without_total_ordering)
{
  NonOrderedType a(3);
  NonOrderedType b(3);
  NonOrderedType c(4);

  assertEqual(a, b);
  assertEqual(a, a);
  assertNotEqual(a, c);

}

unittest(float_assertions)
{
  assertInfinity(exp(800));
  assertInfinity(0.0/0.0);
  assertNotInfinity(42);

  assertNAN(INFINITY - INFINITY);
  assertNAN(0.0/0.0);
  assertNotNAN(42);
}

unittest_main()
