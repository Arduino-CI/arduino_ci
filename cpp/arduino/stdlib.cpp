
#if 1 // This code is copied from https://people.cs.umu.se/isak/snippets/ltoa.c and then converted from ltoa to itoa.
/*
**  LTOA.C
**
**  Converts a integer to a string.
**
**  Copyright 1988-90 by Robert B. Stout dba MicroFirm
**
**  Released to public domain, 1991
**
**  Parameters: 1 - number to be converted
**              2 - buffer in which to build the converted string
**              3 - number base to use for conversion
**
**  Returns:  A character pointer to the converted string if
**            successful, a NULL pointer if the number base specified
**            is out of range.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE (sizeof(int) * 8 + 1)

char *itoa(int N, char *str, int base)
{
      int i = 2;
      int uarg;
      char *tail, *head = str, buf[BUFSIZE];

      if (36 < base || 2 > base)
            base = 10;                    /* can only use 0-9, A-Z        */
      tail = &buf[BUFSIZE - 1];           /* last character position      */
      *tail-- = '\0';

      if (10 == base && N < 0L)
      {
            *head++ = '-';
            uarg    = -N;
      }
      else  uarg = N;

      if (uarg)
      {
            for (i = 1; uarg; ++i)
            {
                  ldiv_t r;

                  r       = ldiv(uarg, base);
                  *tail-- = (char)(r.rem + ((9L < r.rem) ?
                                  ('A' - 10L) : '0'));
                  uarg    = r.quot;
            }
      }
      else  *tail-- = '0';

      memcpy(head, ++tail, i);
      return str;
}
#endif

/*
The dtostrf() function converts the double value passed in val into 
an ASCII representationthat will be stored under s. The caller is 
responsible for providing sufficient storage in s.

Conversion is done in the format “[-]d.ddd”. The minimum field width 
of the output string (including the ‘.’ and the possible sign for 
negative values) is given in width, and prec determines the number of 
digits after the decimal sign. width is signed value, negative for 
left adjustment.

The dtostrf() function returns the pointer to the converted string s. 
*/

char *dtostrf(double __val, signed char __width, unsigned char __prec, char *__s) {
      sprintf(__s, "%*.*f", __width, __prec, __val);
      return __s;
}
