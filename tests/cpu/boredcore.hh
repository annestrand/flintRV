#pragma once

#include <cstdio>
#include <string>
#include <vector>
#include <gtest/gtest.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"

// Placeholder defines here
#ifndef BASE_PATH // This default dir is "obj_dir/"
#define BASE_PATH "."
#endif // BASE_PATH
#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER

extern const int* g_argc;
extern const char** g_argv;

struct stimulus {
    std::vector<std::string> machine_code;
    std::vector<std::string> init_regfile;
};

// Regfile aliases
typedef enum {
    ZERO=0, RA, SP, GP, TP, T0, T1, T2, S0, FP=S0, S1, A0, A1, A2, A3, A4, A5, A6, A7,
        S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, T3, T4, T5, T6, REGISTER_COUNT
} RV32I_Registers;

class boredcore {
public:
    boredcore(vluint64_t maxSimTime);
    ~boredcore();
    bool create(Vboredcore* cpu, const char* traceFile);
    bool createStimulus(std::string machineCodeFilePath, std::string initRegfilePath=std::string());
    void writeRegfile(int index, int val);
    int readRegfile(int index);
    void reset(int count=1);
    void tick();
    void dump();
    bool end();
    Vboredcore*             m_cpu;      // Reference to CPU object
    stimulus                m_stimulus; // Test vector data for CPU tests

private:
    vluint64_t              m_cycles;
    VerilatedVcdC*          m_trace;
    vluint64_t              m_maxSimTime;
    int                     m_dump;
};

/*
    NOTE:   Verilator changes its internal-module interface scheme from v4.210 and up.
            Making utility wrapper here to easily handle and access module internals.
            (As well as keep track of any future-version interface changes)
*/
#if VERILATOR_VER >= 4210
#define cpu(sim) (sim)->m_cpu->rootp
#else
#define cpu(sim) (sim)->m_cpu
#endif
