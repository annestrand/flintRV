#pragma once

#include <cstdio>
#include <string>
#include <vector>
#include <verilated_vcd_c.h>

// Placeholder defines here
#ifndef BASE_PATH // This default dir is "obj_dir/"
#define BASE_PATH "."
#endif // BASE_PATH
#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER

struct stimulus {
    std::vector<std::string> instructions;
    std::vector<std::string> machine_code;
    std::vector<std::string> init_regfile;
};

class simulation {
public:
    simulation(vluint64_t maxSimTime);
    ~simulation();
    bool create(Vboredcore* cpu, const char* traceFile);
    bool createStimuli( std::string machineCodeFilePath, std::string initRegfilePath=std::string());
    void writeRegfile(int index, int val);
    int readRegfile(int index);
    void reset(int count=1);
    void tick();
    bool end();
    Vboredcore*             m_cpu;      // Reference to CPU object
    stimulus                m_stimulus; // Test vector data for CPU tests

private:
    vluint64_t              m_cycles;
    VerilatedVcdC*          m_trace;
    vluint64_t              m_maxSimTime;
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
