#ifndef GDBSTUB_H
#define GDBSTUB_H

#include "risa.h"
#include <stdint.h>

// GDB packet logging
#ifdef GDBLOG
#define GDBLOG 1
#else
#define GDBLOG 0
#endif

void gdbserverCall(rv32iHart_t *cpu);
void gdbserverInit(rv32iHart_t *cpu);

#endif // GDBSTUB_H
