#pragma once


/*
def d(var_raw)
   var = var_raw.split("_")[0]
   out = "#define #{var}_P(...) #{var}(__VA_ARGS__)\n"
   IO.popen('pbcopy', 'w') { |f| f << out }
   out
 end

text = File.open("arduino-1.8.5/hardware/tools/avr/avr/include/avr/pgmspace.h").read
externs = text.split("\n").select {|l| l.start_with? "extern"}
out = externs.map {|l| l.split("(")[0].split(" ")[-1].gsub("*", "") }.uniq
out.each { |l| puts d(l) }
*/

#include <avr/io.h>
#include <string>

#define PROGMEM

#ifndef PGM_P
#define PGM_P const char *
#endif

#ifndef PGM_VOID_P
#define PGM_VOID_P const void *
#endif

// everything's a no-op
#define PSTR(s) ((const char *)(s))
#define pgm_read_byte_near(x)  (x)
#define pgm_read_word_near(x)  (x)
#define pgm_read_dword_near(x) (x)
#define pgm_read_float_near(x) (x)
#define pgm_read_ptr_near(x)   (x)

#define pgm_read_byte_far(x)  (x)
#define pgm_read_word_far(x)  (x)
#define pgm_read_dword_far(x) (x)
#define pgm_read_float_far(x) (x)
#define pgm_read_ptr_far(x)   (x)


#define pgm_read_byte(x) (x)
#define pgm_read_word(x) (x)
#define pgm_read_dword(x) (x)
#define pgm_read_float(x) (x)
#define pgm_read_ptr(x) (x)
#define pgm_get_far_address(x) (x)

#define memchr_P(...) memchr(__VA_ARGS__)
#define memcmp_P(...) memcmp(__VA_ARGS__)
#define memccpy_P(...) memccpy(__VA_ARGS__)
#define memcpy_P(...) memcpy(__VA_ARGS__)
#define memmem_P(...) memmem(__VA_ARGS__)
#define memrchr_P(...) memrchr(__VA_ARGS__)
#define strcat_P(...) strcat(__VA_ARGS__)
#define strchr_P(...) strchr(__VA_ARGS__)
#define strchrnul_P(...) strchrnul(__VA_ARGS__)
#define strcmp_P(...) strcmp(__VA_ARGS__)
#define strcpy_P(...) strcpy(__VA_ARGS__)
#define strcasecmp_P(...) strcasecmp(__VA_ARGS__)
#define strcasestr_P(...) strcasestr(__VA_ARGS__)
#define strcspn_P(...) strcspn(__VA_ARGS__)
#define strlcat_P(...) strlcat(__VA_ARGS__)
#define strlcpy_P(...) strlcpy(__VA_ARGS__)
#define strnlen_P(...) strnlen(__VA_ARGS__)
#define strncmp_P(...) strncmp(__VA_ARGS__)
#define strncasecmp_P(...) strncasecmp(__VA_ARGS__)
#define strncat_P(...) strncat(__VA_ARGS__)
#define strncpy_P(...) strncpy(__VA_ARGS__)
#define strpbrk_P(...) strpbrk(__VA_ARGS__)
#define strrchr_P(...) strrchr(__VA_ARGS__)
#define strsep_P(...) strsep(__VA_ARGS__)
#define strspn_P(...) strspn(__VA_ARGS__)
#define strstr_P(...) strstr(__VA_ARGS__)
#define strtok_P(...) strtok(__VA_ARGS__)
#define strtok_P(...) strtok(__VA_ARGS__)
#define strlen_P(...) strlen(__VA_ARGS__)
#define strnlen_P(...) strnlen(__VA_ARGS__)
#define memcpy_P(...) memcpy(__VA_ARGS__)
#define strcpy_P(...) strcpy(__VA_ARGS__)
#define strncpy_P(...) strncpy(__VA_ARGS__)
#define strcat_P(...) strcat(__VA_ARGS__)
#define strlcat_P(...) strlcat(__VA_ARGS__)
#define strncat_P(...) strncat(__VA_ARGS__)
#define strcmp_P(...) strcmp(__VA_ARGS__)
#define strncmp_P(...) strncmp(__VA_ARGS__)
#define strcasecmp_P(...) strcasecmp(__VA_ARGS__)
#define strncasecmp_P(...) strncasecmp(__VA_ARGS__)
#define strstr_P(...) strstr(__VA_ARGS__)
#define strlcpy_P(...) strlcpy(__VA_ARGS__)
#define memcmp_P(...) memcmp(__VA_ARGS__)
