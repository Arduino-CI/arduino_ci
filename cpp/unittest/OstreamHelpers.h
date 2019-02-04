#pragma once

#include <ostream>

inline std::ostream& operator << (std::ostream& out, const std::nullptr_t &np) { return out << "nullptr"; }
