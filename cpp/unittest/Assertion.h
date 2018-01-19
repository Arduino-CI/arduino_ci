#pragma once
#include "Compare.h"

// helper define for the operators below
#define assertOp(desc, arg1, op, op_name, arg2)                    \
  do                                                               \
  {                                                                \
    if (!assertion<typeof(arg1), typeof(arg2)>(__FILE__, __LINE__, \
                                               desc,               \
                                               #arg1, (arg1),      \
                                               op_name, op,        \
                                               #arg2, (arg2)))     \
    {                                                              \
      return;                                                      \
    }                                                              \
  } while (0)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertEqual(arg1,arg2)       assertOp("assertEqual",arg1,compareEqual,"==",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertNotEqual(arg1,arg2)    assertOp("assertNotEqual",arg1,compareNotEqual,"!=",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertLess(arg1,arg2)        assertOp("assertLess",arg1,compareLess,"<",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertMore(arg1,arg2)        assertOp("assertMore",arg1,compareMore,">",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertLessOrEqual(arg1,arg2) assertOp("assertLessOrEqual",arg1,compareLessOrEqual,"<=",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertMoreOrEqual(arg1,arg2) assertOp("assertMoreOrEqual",arg1,compareMoreOrEqual,">=",arg2)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertTrue(arg) assertEqual(arg,true)

/** macro generates optional output and calls fail() followed by a return if false. */
#define assertFalse(arg) assertEqual(arg,false)

