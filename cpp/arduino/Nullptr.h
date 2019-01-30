#pragma once

// Define C++11 nullptr
typedef void * my_nullptr_t;
#define nullptr (my_nullptr_t)NULL

inline std::ostream& operator << (std::ostream& out, const my_nullptr_t &np) { return out << "nullptr"; }
