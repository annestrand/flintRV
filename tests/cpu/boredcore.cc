#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"
#include "boredcore.hh"

simulation::simulation(vluint64_t maxSimTime) :
    m_trace(nullptr), m_cycles(0), m_maxSimTime(maxSimTime), m_cpu(nullptr) {}

bool simulation::create(Vboredcore* cpu, const char* traceFile) {
    LOG_I("Creating simulation...\n");
    Verilated::traceEverOn(true);
    if (m_trace == nullptr) {
        m_trace = new VerilatedVcdC;
        if (m_trace == nullptr) {
            LOG_W("Failed to create boredcore trace unit!\n");
            return false;
        }
        m_cpu = cpu;
        m_cpu->trace(m_trace, 99);
        m_trace->open(traceFile);
    }
    return true;
}

void simulation::reset() {
    // Some dummy values for now
    m_cpu->instr    = 0xcafebabe;
    m_cpu->dataIn   = 0x00c0ffee;
    m_cpu->ifValid  = 0;
    m_cpu->memValid = 0;

    // Toggle reset
    m_cpu->rst = 1;
    tick();
    m_cpu->rst = 0;
}

void simulation::tick() {
    m_cpu->clk = 1;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); }
    m_cpu->clk = 0;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); m_trace->flush(); }
}

bool simulation::end() { return (Verilated::gotFinish() || m_cycles > m_maxSimTime); }

simulation::~simulation() {
    LOG_I("Cleaning up simulation...\n");
    m_trace->close();
    delete m_cpu;
    m_cpu = nullptr;
    delete m_trace;
    m_trace = nullptr;
}

// ====================================================================================================================
int main(int argc, char** argv, char** env) {
    {
        // Init
        Verilated::commandArgs(argc, argv);
        Vboredcore *cpu = new Vboredcore;
        simulation sim = simulation(200);
        if (!sim.create(cpu, "obj_dir/waveform.vcd")) {
            return -1;
        }
        sim.reset();

        // Simulation loop
        while (!sim.end()) {
            // TODO: add some test vectors here
            // ...

            sim.tick();
        }
    }
    return 0;
}
