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
  assertEqualFloat(1.0, 1.02, 0.1);
  assertNotEqualFloat(1.2, 1.0, 0.01);

  assertInfinity(exp(800));
  assertInfinity(1.0/0.0);
  assertNotInfinity(42);

  assertNAN(INFINITY - INFINITY);
  assertNAN(0.0/0.0);
  assertNotNAN(42);

  assertComparativeEquivalent(exp(800), INFINITY);
  assertComparativeEquivalent(0.0/0.0, INFINITY - INFINITY);
  assertComparativeNotEquivalent(INFINITY,  -INFINITY);

  assertLess(0, INFINITY);
  assertLess(-INFINITY, 0);
  assertLess(-INFINITY, INFINITY);
}

unittest_main()
