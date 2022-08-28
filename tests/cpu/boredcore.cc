#include <cstdio>
#include <string>
#include <vector>
#include <iostream>
#include <algorithm>
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"
#include "boredcore.hh"
#include "common.hh"

// ====================================================================================================================
boredcore::boredcore(vluint64_t maxSimTime) :
    m_trace(nullptr), m_cycles(0), m_maxSimTime(maxSimTime), m_cpu(nullptr), m_stimulus({}), m_dump(0) {}
// ====================================================================================================================
boredcore::~boredcore() {
    if (m_trace != nullptr) { m_trace->close(); delete m_trace; m_trace = nullptr; }
    if (m_cpu != nullptr)   { delete m_cpu; m_cpu = nullptr; }
}
// ====================================================================================================================
bool boredcore::create(Vboredcore* cpu, const char* traceFile) {
    if (cpu == nullptr) {
        LOG_E("Failed to create Verilated boredcore module!\n");
        return false;
    }
    m_cpu = cpu;
    Verilated::traceEverOn(true);
    if (m_trace == nullptr) {
        m_trace = new VerilatedVcdC;
        if (m_trace == nullptr) {
            LOG_W("Failed to create boredcore VCD dumper!\n");
            return true;
        }
        m_cpu->trace(m_trace, 99);
        m_trace->open(traceFile);
    }
    // Parse any passed option(s)
    for (int i=0; i<(*g_argc); ++i) {
        std::string s(g_argv[i]);
        if (s.find("-dump") != std::string::npos) {
            m_dump = m_dump > 0 ? m_dump : 1;
        }
        if (s.find("-dump-all") != std::string::npos) {
            m_dump = m_dump > 1 ? m_dump : 2;
        }
    }
    reset(1); // Reset CPU on create for 1cc
    return true;
}
// ====================================================================================================================
bool boredcore::createStimulus(std::string machineCodeFilePath, std::string initRegfilePath) {
    auto delEmptyStrElems = [](std::vector<std::string>& strList) {
        strList.erase(std::remove_if(
            strList.begin(),
            strList.end(),
            [](std::string const& s) { return s.empty(); }
        ), strList.end());
    };

    m_stimulus.machine_code = machineCodeFileReader(machineCodeFilePath);
    if (m_stimulus.machine_code.empty()) {
        return false;
    }
    delEmptyStrElems(m_stimulus.machine_code);

    // Read init regfile values (if given)
    if (!initRegfilePath.empty()) {
        m_stimulus.init_regfile = initRegfileReader(initRegfilePath);
        if (m_stimulus.init_regfile.empty()) {
            return false;
        }
        delEmptyStrElems(m_stimulus.init_regfile);
        // Update regfile
        for (auto it = m_stimulus.init_regfile.begin(); it != m_stimulus.init_regfile.end(); ++it) {
            int idx = it - m_stimulus.init_regfile.begin();
            writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
        }
    }
    return true;
}
// ====================================================================================================================
void boredcore::writeRegfile(int index, int val) {
    // Skip if x0 reg
    if (index == 0) { return; }
    // Need to write to both ports
    cpu(this)->boredcore__DOT__REGFILE_unit__DOT__RS1_PORT__DOT__ram[index] = val;
    cpu(this)->boredcore__DOT__REGFILE_unit__DOT__RS2_PORT__DOT__ram[index] = val;
}
// ====================================================================================================================
int boredcore::readRegfile(int index) {
    // Does not matter which port we read from
    return (index == 0) ? 0 : cpu(this)->boredcore__DOT__REGFILE_unit__DOT__RS1_PORT__DOT__ram[index];
}
// ====================================================================================================================
void boredcore::reset(int count) {
    // Some dummy values for now
    m_cpu->i_instr    = 0x0badc0de;
    m_cpu->i_dataIn   = 0xdecafbad;
    m_cpu->i_ifValid  = 0;
    m_cpu->i_memValid = 0;
    // Toggle reset
    m_cpu->i_rst = 1;
    for (int i=0; i<count; ++i) { tick(); }
    m_cpu->i_rst = 0;
}
// ====================================================================================================================
void boredcore::tick() {
    dump();
    m_cpu->i_clk = 0;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); }
    m_cpu->i_clk = 1;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(m_cycles++); m_trace->flush(); }
}
// =======================================================================  =============================================
void boredcore::dump() {
    if (!m_dump) { return; }
    std::string instr   = disassembleRv32i(m_cpu->i_instr);
    bool fStall         = cpu(this)->boredcore__DOT__FETCH_stall;
    bool eStall         = cpu(this)->boredcore__DOT__load_wait;
    bool mStall         = cpu(this)->boredcore__DOT__load_wait;
    bool fFlush         = cpu(this)->boredcore__DOT__FETCH_flush;
    bool eFlush         = cpu(this)->boredcore__DOT__EXEC_flush;
    bool mFlush         = cpu(this)->i_rst;
    bool wFlush         = cpu(this)->boredcore__DOT__WB_flush;
    // Status codes
    bool BRA            = cpu(this)->boredcore__DOT__braMispredict; // B
    bool JMP            = cpu(this)->boredcore__DOT__p_jmp[0];      // J
    bool LD_REQ         = cpu(this)->o_loadReq;                     // L
    bool SD_REQ         = cpu(this)->o_storeReq;                    // S
    bool RST            = cpu(this)->i_rst;                         // R
    bool iValid         = cpu(this)->i_ifValid;                     // I
    bool mValid         = cpu(this)->i_memValid;                    // M
    // Dump disassembled instruction:   "-dump"
    printf("%08x   0x%08x   %-22s", m_cpu->o_pcOut, m_cpu->i_instr, instr.c_str());
    if (m_dump < 2) { printf("\n"); return; }
    // Dump more detailed info:         "-dump-all"
    unsigned long long cycle = m_cycles > 1 ? (unsigned long long)(m_cycles/2) : (unsigned long long)0;
    printf("STALL:[%c%c%c-]  FLUSH:[%c%c%c%c]  STATUS:[%c%c%c%c%c%c%c]  CYCLE:[%llu]\n",
        fStall ? 'x':'-', eStall ? 'x':'-', mStall ? 'x':'-',
        fFlush ? 'x':'-', eFlush ? 'x':'-', mFlush ? 'x':'-', wFlush ? 'x':'-',
        iValid ? 'I':'-', mValid ? 'M':'-', RST    ? 'R':'-', BRA    ? 'B':'-',
        JMP    ? 'J':'-', LD_REQ ? 'L':'-', SD_REQ ? 'S':'-',
        cycle
    );
}
// ====================================================================================================================
bool boredcore::end() { return (Verilated::gotFinish() || m_cycles > m_maxSimTime); }
// ====================================================================================================================
