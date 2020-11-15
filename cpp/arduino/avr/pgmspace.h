#pragma once

/*
def d(var_raw)
   var = var_raw.split("_")[0]
   out = "#define #{var}_P(...) ::#{var}(__VA_ARGS__)\n"
   IO.popen('pbcopy', 'w') { |f| f << out }
   out
 end

text = File.open("arduino-1.8.5/hardware/tools/avr/avr/include/avr/pgmspace.h").read
externs = text.split("\n").select {|l| l.start_with? "extern"}
out = externs.map {|l| l.split("(")[0].split(" ")[-1].gsub("*", "") }.uniq
out.each { |l| puts d(l) }
*/

#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#define PROGMEM

#ifndef PGM_P
#define PGM_P const char *
#endif

#ifndef PGM_VOID_P
#define PGM_VOID_P const void *
#endif

// These are normally 32-bit, but here use (u)intptr_t to ensure a pointer can
// always be safely cast to these types.
typedef intptr_t int_farptr_t;
typedef uintptr_t uint_farptr_t;

// everything's a no-op
#define PSTR(s) ((const char *)(s))

#define pgm_read_byte_near(address_short)  (* (const uint8_t *)  (address_short) )
#define pgm_read_word_near(address_short)  (* (const uint16_t *) (address_short) )
#define pgm_read_dword_near(address_short) (* (const uint32_t *) (address_short) )
#define pgm_read_float_near(address_short) (* (const float *)    (address_short) )
#define pgm_read_ptr_near(address_short)   (* (const void **)    (address_short) )

#define pgm_read_byte_far(address_long)    (* (const uint8_t *)  (address_long) )
#define pgm_read_word_far(address_long)    (* (const uint16_t *) (address_long) )
#define pgm_read_dword_far(address_long)   (* (const uint32_t *) (address_long) )
#define pgm_read_float_far(address_long)   (* (const float *)    (address_long) )
#define pgm_read_ptr_far(address_long)     (* (const void **)    (address_long) )

#define pgm_read_byte(address_short)   pgm_read_byte_near(address_short)
#define pgm_read_word(address_short)   pgm_read_word_near(address_short)
#define pgm_read_dword(address_short)  pgm_read_dword_near(address_short)
#define pgm_read_float(address_short)  pgm_read_float_near(address_short)
#define pgm_read_ptr(address_short)    pgm_read_ptr_near(address_short)

#define pgm_get_far_address(var) ( (uint_farptr_t) (&(var)) )

inline const void * memchr_P(const void *s, int val, size_t len) { return memchr(s, val, len); }
inline int memcmp_P(const void *s1, const void *s2, size_t len) { return memcmp(s1, s2, len); }
inline void *memcpy_P(void *dest, const void *src, size_t n) { return memcpy(dest, src, n); }
inline char *strcat_P(char *dest, const char *src) { return strcat(dest, src); }
inline const char *strchr_P(const char *s, int val) { return strchr(s, val); }
inline int strcmp_P(const char *s1, const char *s2) { return strcmp(s1, s2); }
inline char *strcpy_P(char *dest, const char *src) { return strcpy(dest, src); }
inline size_t strcspn_P(const char *s, const char *reject) { return strcspn(s, reject); }
// strlcat and strlcpy are AVR-specific and not entirely trivial to reimplement using strncat it seems
//inline size_t strlcat_P(char *dst, const char *src, size_t siz) { return strlcat(dst, src, siz); }
//inline size_t strlcpy_P(char *dst, const char *src, size_t siz) { return strlcpy(dst, src, siz); }
//inline size_t strlcat_PF(char *dst, uint_farptr_t src, size_t n) { return strlcat(dst, (const char*)src, n); }
//inline size_t strlcpy_PF(char *dst, uint_farptr_t src, size_t siz) { return strlcpy(dst, (const char*)src, siz); }
inline int strncmp_P(const char *s1, const char *s2, size_t n) { return strncmp(s1, s2, n); }
inline char *strncat_P(char *dest, const char *src, size_t len) { return strncat(dest, src, len); }
inline char *strncpy_P(char *dest, const char *src, size_t n) { return strncpy(dest, src, n); }
inline char *strpbrk_P(const char *s, const char *accept) { return (char*)strpbrk(s, accept); }
inline const char *strrchr_P(const char *s, int val) { return strrchr(s, val); }
inline size_t strspn_P(const char *s, const char *accept) { return strspn(s, accept); }
inline char *strstr_P(const char *s1, const char *s2) { return (char*)strstr(s1, s2); }
inline char *strtok_P(char *s, const char * delim) { return strtok(s, delim); }
inline size_t strlen_PF(uint_farptr_t s) { return strlen((char*)s); }
inline void *memcpy_PF(void *dest, uint_farptr_t src, size_t n) { return memcpy(dest, (const char*)src, n); }
inline char *strcpy_PF(char *dst, uint_farptr_t src) { return strcpy(dst, (const char*)src); }
inline char *strncpy_PF(char *dst, uint_farptr_t src, size_t n) { return strncpy(dst, (const char*)src, n); }
inline char *strcat_PF(char *dst, uint_farptr_t src) { return strcat(dst, (const char*)src); }
inline char *strncat_PF(char *dst, uint_farptr_t src, size_t n) { return strncat(dst, (const char*)src, n); }
inline int strcmp_PF(const char *s1, uint_farptr_t s2) { return strcmp(s1, (const char*)s2); }
inline int strncmp_PF(const char *s1, uint_farptr_t s2, size_t n) { return strncmp(s1, (const char*)s2, n); }
inline char *strstr_PF(const char *s1, uint_farptr_t s2) { return (char*)strstr(s1, (const char*)s2); }
inline int memcmp_PF(const void *s1, uint_farptr_t s2, size_t len) { return memcmp(s1, (const char*)s2, len); }
inline size_t strlen_P(const char *src) { return strlen(src); }

// TODO: These functions cannot be found on the CYGWIN test build for
// some reason, so disable them for now. Most of these are less common
// and/or GNU-specific addons anyway
//inline void *memccpy_P(void *dest, const void *src, int val, size_t len) { return memccpy(dest, src, val, len); }
//inline void *memmem_P(const void *s1, size_t len1, const void *s2, size_t len2) { return memmem(s1, len1, s2, len2); }
//inline const void *memrchr_P(const void *src, int val, size_t len) { return memrchr(src, val, len); }
//inline const char *strchrnul_P(const char *s, int c) { return strchrnul(s, c); }
//inline int strcasecmp_P(const char *s1, const char *s2) { return strcasecmp(s1, s2); }
//inline char *strcasestr_P(const char *s1, const char *s2) { return (char*)strcasestr(s1, s2); }
//inline int strncasecmp_P(const char *s1, const char *s2, size_t n) { return strncasecmp(s1, s2, n); }
//inline char *strsep_P(char **sp, const char *delim) { return strsep(sp, delim); }
//inline char *strtok_r_P(char *string, const char *delim, char **last) { return strtok_r(string, delim, last); }
//inline int strcasecmp_PF(const char *s1, uint_farptr_t s2) { return strcasecmp(s1, (const char*)s2); }
//inline int strncasecmp_PF(const char *s1, uint_farptr_t s2, size_t n) { return strncasecmp(s1, (const char*)s2, n); }
//inline size_t strnlen_P(uint_farptr_t s, size_t len) { return strnlen((char*)s, len); }

// These are normally defined by stdio.h on AVR, but we cannot override that
// include file (at least not without no longer being able to include the
// original as well), so just define these here. It seems likely that any
// sketch that uses these progmem-stdio functions will also include pgmspace.h
inline int  vfprintf_P(FILE *stream, const char *__fmt, va_list __ap) { return vfprintf(stream, __fmt, __ap); }
inline int  printf_P(const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vprintf(__fmt, args); va_end(args); }
inline int  sprintf_P(char *s, const char *__fmt, ...) { va_list args; va_start(args, __fmt); return sprintf(s, __fmt, args); va_end(args); }
inline int  snprintf_P(char *s, size_t __n, const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vsnprintf(s, __n, __fmt, args); va_end(args); }
inline int  vsprintf_P(char *s, const char *__fmt, va_list ap) { return vsprintf(s, __fmt, ap); }
inline int  vsnprintf_P(char *s, size_t __n, const char *__fmt, va_list ap) { return vsnprintf(s, __n, __fmt, ap); }
inline int  fprintf_P(FILE *stream, const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vfprintf(stream, __fmt, args); va_end(args); }
inline int  fputs_P(const char *str, FILE *__stream) { return fputs(str, __stream); }
inline int  puts_P(const char *str) { return puts(str); }
inline int  vfscanf_P(FILE *stream, const char *__fmt, va_list __ap) { return vfscanf(stream, __fmt, __ap); }
inline int  fscanf_P(FILE *stream, const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vfscanf(stream, __fmt, args); va_end(args); }
inline int  scanf_P(const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vscanf(__fmt, args); va_end(args); }
inline int  sscanf_P(const char *buf, const char *__fmt, ...) { va_list args; va_start(args, __fmt); return vsscanf(buf, __fmt, args); va_end(args); }
