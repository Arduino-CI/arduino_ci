#pragma once
#include "Compare.h"

// helper define for the operators below
#define assertOp(desc, relevance1, arg1, op, op_name, relevance2, arg2) \
  do                                                               \
  {                                                                \
    if (!assertion<typeof(arg1), typeof(arg2)>(__FILE__, __LINE__, \
                                               desc,               \
                                               relevance1, #arg1, (arg1),      \
                                               op_name, op,        \
                                               relevance2, #arg2, (arg2)))     \
    {                                                              \
      return;                                                      \
    }                                                              \
  } while (0)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertEqual(arg1,arg2)       assertOp("assertEqual","expected",arg1,compareEqual,"==","actual",arg2)
#define assertNotEqual(arg1,arg2)    assertOp("assertNotEqual","unwanted",arg1,compareNotEqual,"!=","actual",arg2)
#define assertLess(arg1,arg2)        assertOp("assertLess","lowerBound",arg1,compareLess,"<","upperBound",arg2)
#define assertMore(arg1,arg2)        assertOp("assertMore","upperBound",arg1,compareMore,">","lowerBound",arg2)
#define assertLessOrEqual(arg1,arg2) assertOp("assertLessOrEqual","lowerBound",arg1,compareLessOrEqual,"<=","upperBound",arg2)
#define assertMoreOrEqual(arg1,arg2) assertOp("assertMoreOrEqual","upperBound",arg1,compareMoreOrEqual,">=","lowerBound",arg2)
#define assertTrue(arg) assertEqual(arg,true)
#define assertFalse(arg) assertEqual(arg,false)

