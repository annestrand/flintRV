#ifndef GDBSTUB_H
#define GDBSTUB_H

#include <stdint.h>

#include "risa.h"

// GDB packet logging
#ifdef GDBLOG
#define GDBLOG 1
#else
#define GDBLOG 0
#endif

void gdbserverCall(rv32iHart *cpu);
void gdbserverInit(rv32iHart *cpu);

#endif // GDBSTUB_H
