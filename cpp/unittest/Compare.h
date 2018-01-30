#pragma once
#include "string.h"


template  < typename A, typename B > struct Compare
{
  inline static int between(const A &a,const B &b)
  {
    if (a<b) return -1;
    if (b<a) return  1;
    return 0;
  } // between
  inline static bool equal(const A &a,const B &b)
  {
    return (!(a<b)) && (!(b<a));
  } // equal
  inline static bool notEqual(const A &a,const B &b)
  {
    return (a<b) || (b<a);
  } // notEqual
  inline static bool less(const A &a,const B &b)
  {
    return a<b;
  } // less
  inline static bool more(const A &a,const B &b)
  {
    return b<a;
  } // more
  inline static bool lessOrEqual(const A &a,const B &b)
  {
    return !(b<a);
  } // lessOrEqual
  inline static bool moreOrEqual(const A &a,const B &b)
  {
    return !(a<b);
  } // moreOrEqual
};

template  <  > struct Compare<const char *,const char *>;
template  <  > struct Compare<const char *,char *>;
template  < long M > struct Compare<const char *,char [M]>;
template  <  > struct Compare<char *,const char *>;
template  <  > struct Compare<char *,char *>;
template  < long M > struct Compare<char *,char [M]>;
template  < long N > struct Compare<char [N],const char *>;
template  < long N > struct Compare<char [N],char *>;
template  < long N, long M > struct Compare<char [N],char [M]>;

template  <  > struct Compare<const char *,const char *>
{
  inline static int between(const char * const &a,const char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char * const &a,const char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char * const &a,const char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char * const &a,const char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char * const &a,const char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char * const &a,const char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char * const &a,const char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  <  > struct Compare<const char *,char *>
{
  inline static int between(const char * const &a,char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char * const &a,char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char * const &a,char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char * const &a,char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char * const &a,char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char * const &a,char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char * const &a,char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < long M > struct Compare<const char *,char [M]>
{
  inline static int between(const char * const &a,const char (&b)[M])
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char * const &a,const char (&b)[M])
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char * const &a,const char (&b)[M])
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char * const &a,const char (&b)[M])
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char * const &a,const char (&b)[M])
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char * const &a,const char (&b)[M])
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char * const &a,const char (&b)[M])
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  <  > struct Compare<char *,const char *>
{
  inline static int between(char * const &a,const char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(char * const &a,const char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(char * const &a,const char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(char * const &a,const char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(char * const &a,const char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(char * const &a,const char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(char * const &a,const char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  <  > struct Compare<char *,char *>
{
  inline static int between(char * const &a,char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(char * const &a,char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(char * const &a,char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(char * const &a,char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(char * const &a,char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(char * const &a,char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(char * const &a,char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < long M > struct Compare<char *,char [M]>
{
  inline static int between(char * const &a,const char (&b)[M])
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(char * const &a,const char (&b)[M])
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(char * const &a,const char (&b)[M])
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(char * const &a,const char (&b)[M])
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(char * const &a,const char (&b)[M])
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(char * const &a,const char (&b)[M])
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(char * const &a,const char (&b)[M])
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < long N > struct Compare<char [N],const char *>
{
  inline static int between(const char (&a)[N],const char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char (&a)[N],const char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char (&a)[N],const char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char (&a)[N],const char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char (&a)[N],const char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char (&a)[N],const char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char (&a)[N],const char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < long N > struct Compare<char [N],char *>
{
  inline static int between(const char (&a)[N],char * const &b)
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char (&a)[N],char * const &b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char (&a)[N],char * const &b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char (&a)[N],char * const &b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char (&a)[N],char * const &b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char (&a)[N],char * const &b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char (&a)[N],char * const &b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < long N, long M > struct Compare<char [N],char [M]>
{
  inline static int between(const char (&a)[N],const char (&b)[M])
  {
    return strcmp(a,b);
  } // between
  inline static bool equal(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(const char (&a)[N],const char (&b)[M])
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  < > struct Compare<bool, bool>
{
  inline static int between(bool a, bool b)
  {
    return b ? (a ? 0 : -1) : (a ? 1 : 0);
  } // between
  inline static bool equal(bool a, bool b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(bool a, bool b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(bool a, bool b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(bool a, bool b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(bool a, bool b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(bool a, bool b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  <typename T> struct Compare<bool, T>
{
  inline static int between(bool a, T b)
  {
    return b ? (a ? 0 : -1) : (a ? 1 : 0);
  } // between
  inline static bool equal(bool a, T b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(bool a, T b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(bool a, T b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(bool a, T b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(bool a, T b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(bool a, T b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template  <typename T> struct Compare<T, bool>
{
  inline static int between(T a, bool b)
  {
    return b ? (a ? 0 : -1) : (a ? 1 : 0);
  } // between
  inline static bool equal(T a, bool b)
  {
    return between(a,b) == 0;
  } // equal
  inline static bool notEqual(T a, bool b)
  {
    return between(a,b) != 0;
  } // notEqual
  inline static bool less(T a, bool b)
  {
    return between(a,b) < 0;
  } // less
  inline static bool more(T a, bool b)
  {
    return between(a,b) > 0;
  } // more
  inline static bool lessOrEqual(T a, bool b)
  {
    return between(a,b) <= 0;
  } // lessOrEqual
  inline static bool moreOrEqual(T a, bool b)
  {
    return between(a,b) >= 0;
  } // moreOrEqual
};
template <typename A, typename B> int compareBetween(const A &a, const B &b) { return Compare<A,B>::between(a,b); }
template <typename A, typename B> bool compareEqual(const A &a, const B &b) { return Compare<A,B>::equal(a,b); }
template <typename A, typename B> bool compareNotEqual(const A &a, const B &b) { return Compare<A,B>::notEqual(a,b); }
template <typename A, typename B> bool compareLess(const A &a, const B &b) { return Compare<A,B>::less(a,b); }
template <typename A, typename B> bool compareMore(const A &a, const B &b) { return Compare<A,B>::more(a,b); }
template <typename A, typename B> bool compareLessOrEqual(const A &a, const B &b) { return Compare<A,B>::lessOrEqual(a,b); }
template <typename A, typename B> bool compareMoreOrEqual(const A &a, const B &b) { return Compare<A,B>::moreOrEqual(a,b); }
