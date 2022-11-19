#pragma once

#include <cstdio>
#include <string>
#include <vector>
#include <gtest/gtest.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"

// Placeholder defines here
#ifndef TESTS_PATH
#define TESTS_PATH "."
#endif // TESTS_PATH
#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER

#define SIM_DONE_VAL 0xcafebabe

// Regfile aliases
typedef enum {
    ZERO=0, RA, SP, GP, TP, T0, T1, T2, S0, FP=S0, S1, A0, A1, A2, A3, A4, A5, A6, A7,
        S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, T3, T4, T5, T6, REGISTER_COUNT
} RV32I_Registers;

class boredcore {
public:
    boredcore(vluint64_t maxSimTime, int dumpLevel=0);
    ~boredcore();
    bool create(Vboredcore* cpu, const char* traceFile, std::string initRegfilePath=std::string());
    bool createMemory(size_t memSize);
    bool createMemory(size_t memSize, std::string initHexfile);
    bool createMemory(size_t memSize, unsigned char* initHexarray, unsigned int initHexarrayLen);
    bool instructionUpdate();
    bool loadStoreUpdate();
    bool peekMem(int addr, int& val);
    bool pokeMem(int addr, int val);
    void writeRegfile(int index, int val);
    int readRegfile(int index);
    void reset(int cycles=1);
    void tick();
    void dump();
    bool end();
    Vboredcore*             m_cpu;      // Reference to CPU object

private:
    vluint64_t              m_cycles;
    VerilatedVcdC*          m_trace;
    vluint64_t              m_maxSimTime;
    int                     m_dump;
    char*                   m_mem;      // Test memory
    size_t                  m_memSize;  // Sizeof Test memory in bytes
};

/*
    NOTE:   Verilator changes its internal-module interface scheme from v4.210 and up (i.e. rootp).
            Making utility wrapper here to easily handle and access module internals.
            (As well as keep track of any future-version interface changes)
*/
#if VERILATOR_VER >= 4210
#define CPU(sim) (sim)->m_cpu->rootp->boredcore
#else
#define CPU(sim) (sim)->m_cpu->boredcore
#endif
