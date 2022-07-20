#pragma once

#include <cstdio>
#include <verilated_vcd_c.h>

class simulation {
public:
    simulation(vluint64_t maxSimTime);
    ~simulation();
    bool create(Vboredcore* cpu, const char* traceFile);
    void reset(int count=1);
    void tick();
    bool end();

private:
    vluint64_t              m_cycles;
    VerilatedVcdC*          m_trace;
    vluint64_t              m_maxSimTime;
    Vboredcore*             m_cpu; // Reference to CPU object
};