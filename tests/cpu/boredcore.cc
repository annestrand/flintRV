#include <cstdio>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <iostream>

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

void simulation::reset(int count) {
    // Some dummy values for now
    m_cpu->instr    = 0x0badc0de;
    m_cpu->dataIn   = 0x00c0ffee;
    m_cpu->ifValid  = 0;
    m_cpu->memValid = 0;
    m_cpu->boredcore__DOT__RS1_PORT__DOT__ram[4] = 0xcafebabe;

    // Toggle reset
    m_cpu->rst = 1;
    for (int i=0; i<count; ++i) { tick(); }
    m_cpu->rst = 0;
}

void simulation::tick() {
    m_cpu->clk = 0;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); }
    m_cpu->clk = 1;
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
    // Init
    Verilated::commandArgs(argc, argv);
    Vboredcore *cpu = new Vboredcore;
    simulation sim  = simulation(200);
    if (!sim.create(cpu, "obj_dir/waveform.vcd")) {
        return -1;
    }

    // Read test vector file
    std::vector<std::string> instructions;
    std::string basedir(argv[0]);
    basedir = basedir.substr(0, basedir.find_last_of('/'));
    std::ifstream f(basedir + "/test_asm.mem");
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", basedir.c_str());
        return -1;
    }
    std::string line;
    while (std::getline(f, line)) {
        std::string item;
        std::stringstream ss(line);
        while (ss >> item) {
            if (item.find("@") != std::string::npos) { continue; }
            // Flip the endian here
            item = item.substr(6,2) + item.substr(4,2) + item.substr(2,2) + item.substr(0,2);
            instructions.push_back(item);
        }
    }
    // Pad rest of program with invalid instructions
    for (int i=0; i<8; ++i) { instructions.push_back("0badc0de"); }
    f.close();

    // Simulation loop
    sim.reset(2); // Hold reset line for 2cc
    while (!sim.end()) {
        int x = cpu->pcOut >> 2;
        cpu->instr      = (int)std::strtol(instructions[x].c_str(), NULL, 16);
        cpu->dataIn     = 0xdeadc0de;
        cpu->ifValid    = 1;
        cpu->memValid   = 1;
        LOG_I("cpu->pcOut  = %d\n", cpu->pcOut);
        LOG_I("cpu->instr  = %x\n", cpu->instr);
        LOG_I("cpu->x4_reg = %x\n", cpu->boredcore__DOT__RS1_PORT__DOT__ram[4]);

        // Evaluate
        sim.tick();
    }
    return 0;
}
