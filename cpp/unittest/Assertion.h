#pragma once

#ifndef typeof
#define typeof __typeof__
#endif

#include "Compare.h"

#define testBehaviorOp(die, desc, rel1, arg1, op, op_name, rel2, arg2) \
  do                                                                   \
    {                                                                  \
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
#define assertEqual(arg1,arg2)       assertOp("assertEqual","expected",arg1,compareEqual,"==","actual",arg2)
#define assertNotEqual(arg1,arg2)    assertOp("assertNotEqual","unwanted",arg1,compareNotEqual,"!=","actual",arg2)
#define assertLess(arg1,arg2)        assertOp("assertLess","lowerBound",arg1,compareLess,"<","upperBound",arg2)
#define assertMore(arg1,arg2)        assertOp("assertMore","upperBound",arg1,compareMore,">","lowerBound",arg2)
#define assertLessOrEqual(arg1,arg2) assertOp("assertLessOrEqual","lowerBound",arg1,compareLessOrEqual,"<=","upperBound",arg2)
#define assertMoreOrEqual(arg1,arg2) assertOp("assertMoreOrEqual","upperBound",arg1,compareMoreOrEqual,">=","lowerBound",arg2)
#define assertTrue(arg) assertEqual(true, arg)
#define assertFalse(arg) assertEqual(false, arg)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assureEqual(arg1,arg2)       assureOp("assureEqual","expected",arg1,compareEqual,"==","actual",arg2)
#define assureNotEqual(arg1,arg2)    assureOp("assureNotEqual","unwanted",arg1,compareNotEqual,"!=","actual",arg2)
#define assureLess(arg1,arg2)        assureOp("assureLess","lowerBound",arg1,compareLess,"<","upperBound",arg2)
#define assureMore(arg1,arg2)        assureOp("assureMore","upperBound",arg1,compareMore,">","lowerBound",arg2)
#define assureLessOrEqual(arg1,arg2) assureOp("assureLessOrEqual","lowerBound",arg1,compareLessOrEqual,"<=","upperBound",arg2)
#define assureMoreOrEqual(arg1,arg2) assureOp("assureMoreOrEqual","upperBound",arg1,compareMoreOrEqual,">=","lowerBound",arg2)
#define assureTrue(arg) assureEqual(true, arg)
#define assureFalse(arg) assureEqual(false, arg)

