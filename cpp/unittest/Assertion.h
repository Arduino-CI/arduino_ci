#pragma once

#ifndef typeof
#define typeof __typeof__
#endif

#include "Compare.h"

#define testBehaviorExp(die, desc, pass) \
  do                                     \
  {                                      \
    if (!assertion(__FILE__, __LINE__,   \
                   desc, pass))          \
    {                                    \
      if (die) return;                   \
    }                                    \
  } while (0)

#define testBehaviorOp(die, desc, rel1, arg1, op, op_name, rel2, arg2) \
  do                                                                   \
  {                                                                    \
    if (!assertion<typeof(arg1), typeof(arg2)>(__FILE__, __LINE__,     \
                                               desc,                   \
                                               rel1, #arg1, (arg1),    \
                                               op_name, op,            \
                                               rel2, #arg2, (arg2)))   \
    {                                                                  \
      if (die) return;                                                 \
    }                                                                  \
  } while (0)



// helper define for the operators below
#define assertOp(desc, rel1, arg1, op, op_name, rel2, arg2) \
  testBehaviorOp(false, desc, rel1, arg1, op, op_name, rel2, arg2)

#define assureOp(desc, rel1, arg1, op, op_name, rel2, arg2) \
  testBehaviorOp(true, desc, rel1, arg1, op, op_name, rel2, arg2)


/** macro generates optional output and calls fail() but does not return if false. */
#define assertTrue(arg)                           testBehaviorExp(false, "assertTrue " #arg, (arg))
#define assertFalse(arg)                          testBehaviorExp(false, "assertFalse " #arg, !(arg))
#define assertNull(arg)                           testBehaviorExp(false, "assertNull " #arg, ((void*)NULL == (void*)(arg)))
#define assertNotNull(arg)                        testBehaviorExp(false, "assertNotNull " #arg, ((void*)NULL != (void*)(arg)))
#define assertEqual(arg1,arg2)                    assertOp("assertEqual","expected",arg1,evaluateDoubleEqual,"==","actual",arg2)
#define assertNotEqual(arg1,arg2)                 assertOp("assertNotEqual","unwanted",arg1,evaluateNotEqual,"!=","actual",arg2)
#define assertComparativeEquivalent(arg1,arg2)    assertOp("assertComparativeEquivalent","expected",arg1,compareEqual,"!<>","actual",arg2)
#define assertComparativeNotEquivalent(arg1,arg2) assertOp("assertComparativeNotEquivalent","unwanted",arg1,compareNotEqual,"<>","actual",arg2)
#define assertLess(arg1,arg2)                     assertOp("assertLess","lowerBound",arg1,compareLess,"<","actual",arg2)
#define assertMore(arg1,arg2)                     assertOp("assertMore","upperBound",arg1,compareMore,">","actual",arg2)
#define assertLessOrEqual(arg1,arg2)              assertOp("assertLessOrEqual","lowerBound",arg1,compareLessOrEqual,"<=","actual",arg2)
#define assertMoreOrEqual(arg1,arg2)              assertOp("assertMoreOrEqual","upperBound",arg1,compareMoreOrEqual,">=","actual",arg2)

#define assertEqualFloat(arg1, arg2, arg3)    assertOp("assertEqualFloat", "epsilon", arg3, compareMoreOrEqual, ">=", "actualDifference", fabs(arg1 - arg2))
#define assertNotEqualFloat(arg1, arg2, arg3) assertOp("assertNotEqualFloat", "epsilon", arg3, compareLessOrEqual, "<=", "insufficientDifference", fabs(arg1 - arg2))
#define assertInfinity(arg)                   testBehaviorExp(false, "assertInfinity " #arg, isinf(arg))
#define assertNotInfinity(arg)                testBehaviorExp(false, "assertNotInfinity " #arg, !isinf(arg))
#define assertNAN(arg)                        testBehaviorExp(false, "assertNAN " #arg, isnan(arg))
#define assertNotNAN(arg)                     testBehaviorExp(false, "assertNotNAN " #arg, !isnan(arg))


/** macro generates optional output and calls fail() followed by a return if false. */
#define assureTrue(arg)                           testBehaviorExp(true, "assertTrue " #arg, (arg))
#define assureFalse(arg)                          testBehaviorExp(true, "assertFalse " #arg, !(arg))
#define assureNull(arg)                           testBehaviorExp(true, "assertNull " #arg, ((void*)NULL == (void*)(arg)))
#define assureNotNull(arg)                        testBehaviorExp(true, "assertNotNull " #arg, ((void*)NULL != (void*)(arg)))
#define assureEqual(arg1,arg2)                    assureOp("assureEqual","expected",arg1,evaluateDoubleEqual,"==","actual",arg2)
#define assureNotEqual(arg1,arg2)                 assureOp("assureNotEqual","unwanted",arg1,evaluateNotEqual,"!=","actual",arg2)
#define assureComparativeEquivalent(arg1,arg2)    assertOp("assureComparativeEquivalent","expected",arg1,compareEqual,"!<>","actual",arg2)
#define assureComparativeNotEquivalent(arg1,arg2) assertOp("assureComparativeNotEquivalent","unwanted",arg1,compareNotEqual,"<>","actual",arg2)
#define assureLess(arg1,arg2)                     assureOp("assureLess","lowerBound",arg1,compareLess,"<","actual",arg2)
#define assureMore(arg1,arg2)                     assureOp("assureMore","upperBound",arg1,compareMore,">","actual",arg2)
#define assureLessOrEqual(arg1,arg2)              assureOp("assureLessOrEqual","lowerBound",arg1,compareLessOrEqual,"<=","actual",arg2)
#define assureMoreOrEqual(arg1,arg2)              assureOp("assureMoreOrEqual","upperBound",arg1,compareMoreOrEqual,">=","actual",arg2)

#define assureEqualFloat(arg1, arg2, arg3)    assureOp("assureEqualFloat", "epsilon", arg3, compareMoreOrEqual, ">=", "actualDifference", fabs(arg1 - arg2))
#define assureNotEqualFloat(arg1, arg2, arg3) assureOp("assureNotEqualFloat", "epsilon", arg3, compareLessOrEqual, "<=", "insufficientDifference", fabs(arg1 - arg2))
#define assureInfinity(arg)                   testBehaviorExp(true, "assertInfinity " #arg, isinf(arg))
#define assureNotInfinity(arg)                testBehaviorExp(true, "assertNotInfinity " #arg, !isinf(arg))
#define assureNAN(arg)                        testBehaviorExp(true, "assertNAN " #arg, isnan(arg))
#define assureNotNAN(arg)                     testBehaviorExp(true, "assertNotNAN " #arg, !isnan(arg))
