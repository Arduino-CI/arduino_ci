The parent directory is for files that must stand in for their Arduino counterparts -- any `SomeFile` that might be requested as `#include <SomeFile.h>`.

This directory is specificially for support files required by those other files.  That's because we don't want to create collisions on filenames for common data structures like Queue.

If there end up being class-level conflicts, it is this developer's stated intention to rename our classes such that `class Float` becomes `class FloatyMcFloatFace`.
