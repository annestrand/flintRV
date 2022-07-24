#include <cstdio>
#include <string>
#include <vector>
#include <iostream>

#include <gtest/gtest.h>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"
#include "boredcore.hh"
#include "common.hh"

// ====================================================================================================================
simulation::simulation(vluint64_t maxSimTime) :
    m_trace(nullptr), m_cycles(0), m_maxSimTime(maxSimTime), m_cpu(nullptr), m_stimulus({}) {}
// ====================================================================================================================
bool simulation::create(Vboredcore* cpu, const char* traceFile) {
    LOG_I("Creating simulation...\n");
    if (cpu == nullptr) {
        LOG_E("Failed to create Verilated boredcore module!\n");
        return false;
    }
    m_cpu = cpu;
    Verilated::traceEverOn(true);
    if (m_trace == nullptr) {
        m_trace = new VerilatedVcdC;
        if (m_trace == nullptr) {
            LOG_W("Failed to create boredcore trace unit!\n");
            return false;
        }
        m_cpu->trace(m_trace, 99);
        m_trace->open(traceFile);
    }
    return true;
}
// ====================================================================================================================
bool simulation::createStimuli( std::string asmFilePath,
                                std::string machineCodeFilePath,
                                std::string initRegfilePath) {
    // Read test vector files
    m_stimulus.instructions = asmFileReader(asmFilePath);
    if (m_stimulus.instructions.empty()) {
        LOG_E("Could not read ASM file!\n");
        return false;
    }
    m_stimulus.machine_code = machineCodeFileReader(machineCodeFilePath);
    if (m_stimulus.machine_code.empty()) {
        LOG_E("Could not read machine-code file!\n");
        return false;
    }
    endianFlipper(m_stimulus.machine_code); // Since objdump does output Verilog in big-endian
    // Read init regfile values (if given)
    if (!initRegfilePath.empty()) {
        m_stimulus.init_regfile = initRegfileReader(initRegfilePath);
        if (m_stimulus.init_regfile.empty()) {
            LOG_E("Could not read init regfile file!\n");
            return false;
        }
    }
    return true;
}
// ====================================================================================================================
void simulation::reset(int count) {
    // Some dummy values for now
    m_cpu->i_instr    = 0x0badc0de;
    m_cpu->i_dataIn   = 0x00c0ffee;
    m_cpu->i_ifValid  = 0;
    m_cpu->i_memValid = 0;

    // Toggle reset
    m_cpu->i_rst = 1;
    for (int i=0; i<count; ++i) { tick(); }
    m_cpu->i_rst = 0;
}
// ====================================================================================================================
void simulation::tick() {
    m_cpu->i_clk = 0;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); }
    m_cpu->i_clk = 1;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); m_trace->flush(); }
}
// ====================================================================================================================
bool simulation::end() { return (Verilated::gotFinish() || m_cycles > m_maxSimTime); }
// ====================================================================================================================
simulation::~simulation() {
    LOG_I("Cleaning up simulation...\n");
    m_trace->close();
    delete m_cpu;
    m_cpu = nullptr;
    delete m_trace;
    m_trace = nullptr;
}