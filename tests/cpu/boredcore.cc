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
    printf("\n");
    LOG_I("Cleaning up simulation...\n");
    m_trace->close();
    delete m_cpu;
    m_cpu = nullptr;
    delete m_trace;
    m_trace = nullptr;
}

void endianFlipper(std::vector<std::string>& machineCode) {
    for (auto it = machineCode.begin(); it != machineCode.end(); ++it) {
        std::string item = *it;
        item = item.substr(6,2) + item.substr(4,2) + item.substr(2,2) + item.substr(0,2);
        machineCode[it-machineCode.begin()] = item;
    }
}

void leftTrimWhitespace(std::string& s) {
    s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
}

std::vector<std::string> machineCodeFileReader(std::string filePath) {
    std::vector<std::string> contents;
    std::ifstream f(filePath);
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", filePath.c_str());
        return contents;
    }
    std::string line;
    while (std::getline(f, line)) {
        std::string item;
        std::stringstream ss(line);
        while (ss >> item) {
            contents.push_back(item);
        }
    }
    f.close();
    for (auto it = contents.begin(); it != contents.end(); ++it) {
        if (it->find("@") != std::string::npos) {
            contents.erase(it);
        }
    }
    return contents;
}

std::vector<std::string> asmFileReader(std::string filePath) {
    std::vector<std::string> contents;
    std::ifstream f(filePath);
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", filePath.c_str());
        return contents;
    }
    std::string line;
    while (std::getline(f, line)) {
        if (line.find("#") != std::string::npos) {
            continue;
        }
        leftTrimWhitespace(line);
        contents.push_back(line);
    }
    f.close();
    return contents;
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

    // Read test vector files
    std::vector<std::string> instructions;
    std::vector<std::string> machine_code;
    std::string basedir(argv[0]);
    basedir = basedir.substr(0, basedir.find_last_of('/'));
    instructions = asmFileReader(basedir + "/../tests/cpu/src/test_asm.s");
    machine_code = machineCodeFileReader(basedir + "/test_asm.mem");
    endianFlipper(machine_code);

    // Simulation loop
    sim.reset(2); // Hold reset line for 2cc
    int reg_x4 = 0;
    bool done = false;
    while (!sim.end() && !done) {
        std::string instr   = instructions[cpu->pcOut >> 2];
        int machine_instr   = (int)std::strtol(machine_code[cpu->pcOut >> 2].c_str(), NULL, 16);
        cpu->instr          = machine_instr;
        cpu->dataIn         = 0xdeadc0de;
        cpu->ifValid        = 1;
        cpu->memValid       = 1;
        bool pipelineFlush  = cpu->boredcore__DOT__EXEC_flush;

        LOG_I("0x%08x: %s\n", machine_instr, instr.c_str());
        if (cpu->boredcore__DOT__RS1_PORT__DOT__ram[4] == 10) {
            done = true;
            LOG_I("    cpu->regFile[x4] = %d\n", cpu->boredcore__DOT__RS1_PORT__DOT__ram[4]);
            LOG_I("    cpu->regFile[x5] = %d\n", cpu->boredcore__DOT__RS1_PORT__DOT__ram[5]);
        } else if (reg_x4 != cpu->boredcore__DOT__RS1_PORT__DOT__ram[4]) {
            LOG_I("    cpu->regFile[x4] = %d\n", cpu->boredcore__DOT__RS1_PORT__DOT__ram[4]);
            LOG_I("    cpu->regFile[x5] = %d\n", cpu->boredcore__DOT__RS1_PORT__DOT__ram[5]);
            reg_x4 = cpu->boredcore__DOT__RS1_PORT__DOT__ram[4];
        }

        // Evaluate
        sim.tick();
    }
    return 0;
}
