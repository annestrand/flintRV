// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#pragma once

#include <cstdio>
#include <string>
#include <vector>

#include "VflintRV.h"
#include "VflintRV__Syms.h"

#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER

#ifndef flintRV_VERSION
#define flintRV_VERSION "unknown"
#endif // flintRV_VERSION

// Syscalls (taken from "riscv64-unknown-elf/include/machine/syscall.h")
#define SYS_exit 93
#define SYS_write 64

// Regfile aliases
typedef enum {
    ZERO = 0,
    RA,
    SP,
    GP,
    TP,
    T0,
    T1,
    T2,
    S0,
    FP = S0,
    S1,
    A0,
    A1,
    A2,
    A3,
    A4,
    A5,
    A6,
    A7,
    S2,
    S3,
    S4,
    S5,
    S6,
    S7,
    S8,
    S9,
    S10,
    S11,
    T3,
    T4,
    T5,
    T6,
    REGISTER_COUNT
} RV32I_Registers;

class flintRV {
  public:
    flintRV(vluint64_t maxSimTime, bool tracing = false);
    ~flintRV();
    bool create(VflintRV *cpu, const char *traceFile = nullptr);
    bool createMemory(size_t memSize);
    bool createMemory(size_t memSize, std::string initHexfile);
    bool createMemory(size_t memSize, unsigned char *initHexarray,
                      unsigned int initHexarrayLen);
    bool instructionUpdate();
    bool loadStoreUpdate();
    bool peekMem(size_t addr, int &val);
    bool pokeMem(size_t addr, int val);
    void writeRegfile(int index, int val);
    int readRegfile(int index);
    void reset(int cycles = 1);
    void tick(bool enableDump = true);
    void dump();
    bool end();
    VflintRV *m_cpu; // Reference to CPU object

  private:
    vluint64_t m_cycles;
    VerilatedVcdC *m_trace;
    vluint64_t m_maxSimTime;
    bool m_tracing;
    bool m_endNow;
    char *m_mem;      // Test memory
    size_t m_memSize; // Sizeof Test memory in bytes
};

/*
    NOTE:   Verilator changes its internal-module interface scheme from v4.210
   and up (i.e. rootp). Making utility wrapper here to easily handle and access
   module internals. (As well as keep track of any future-version interface
   changes)
*/
#if VERILATOR_VER >= 4210
#define CPU(sim) (sim)->m_cpu->rootp->flintRV
#else
#define CPU(sim) (sim)->m_cpu->flintRV
#endif
