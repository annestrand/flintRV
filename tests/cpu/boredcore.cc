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
    m_trace(nullptr), m_cycles(0), m_maxSimTime(maxSimTime), m_cpu(nullptr), m_dump(0), m_mem(nullptr), m_memSize(0) {}
// ====================================================================================================================
boredcore::~boredcore() {
    if (m_trace != nullptr) { m_trace->close(); delete m_trace; m_trace = nullptr;  }
    if (m_cpu != nullptr)   { delete m_cpu; m_cpu = nullptr;                        }
    if (m_mem != nullptr)   { delete[] m_mem; m_mem = nullptr;                      }
}
// ====================================================================================================================
bool boredcore::create(Vboredcore* cpu, const char* traceFile, std::string initRegfilePath) {
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

    // Init the register file (if given) - needs to happen after reset
    if (!initRegfilePath.empty()) {
        auto delEmptyStrElems = [](std::vector<std::string>& strList) {
            strList.erase(std::remove_if(
                strList.begin(),
                strList.end(),
                [](std::string const& s) { return s.empty(); }
            ), strList.end());
        };
        auto init_regfile = initRegfileReader(initRegfilePath);
        if (init_regfile.empty()) {
            return false;
        }
        delEmptyStrElems(init_regfile);
        // Update regfile
        for (auto it = init_regfile.begin(); it != init_regfile.end(); ++it) {
            int idx = it - init_regfile.begin();
            writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
        }
    }
    return true;
}
// ====================================================================================================================
bool boredcore::registerMemory(size_t memSize, std::string memfile) {
    if (memSize == 0) { LOG_E("Memory cannot be of size 0!\n"); return false; }
    m_memSize   = memSize;
    m_mem       = new char[memSize];
    if (m_mem == nullptr) { LOG_E("Failed to allocate %ld bytes!\n", m_memSize); return false; }
    // Init mem from memfile (if given)
    if (!memfile.empty()) {
        auto memfileList = machineCodeFileReader(memfile);
        size_t memfileListSize = memfileList.size() * 4;
        if (memfileListSize >= m_memSize) {
            LOG_E("Cannot fit memfile in m_mem! %ld >= %ld\n", memfileListSize, m_memSize);
            return false;
        }
        for (size_t i=0; i<memfileList.size(); ++i) {
            ((int*)m_mem)[i] = (int)HEX_DECODE_ASCII(memfileList[i].c_str());
        }
    }
    return true;
}
// ====================================================================================================================
bool boredcore::instructionUpdate() {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot fetch instruction from NULL memory!\n"); return false; }
    if (cpu(this)->o_pcOut >= m_memSize) {
        LOG_E("PC address [ %d ] is out-of-bounds from memory [ %ld ]!\n", cpu(this)->o_pcOut, m_memSize);
        return false;
    }
    // Fetch the next instruction
    cpu(this)->i_instr = *(int*)&m_mem[cpu(this)->o_pcOut];
    return true;
}
// ====================================================================================================================
bool boredcore::loadMemUpdate() {
    if (!cpu(this)->o_loadReq) { return true; } // Skip if there was no load request
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot load data from NULL memory!\n"); return false; }
    if (cpu(this)->o_dataAddr >= m_memSize) {
        LOG_E("Load data address [ %d ] is out-of-bounds from memory [ %ld ]!\n", cpu(this)->o_dataAddr, m_memSize);
        return false;
    }
    // Fetch the data
    cpu(this)->i_dataIn = *(int*)&m_mem[cpu(this)->o_dataAddr];
    return true;
}
// ====================================================================================================================
bool boredcore::storeMemUpdate() {
    if (!cpu(this)->o_storeReq) { return true; } // Skip if there was no store request
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot store data to NULL memory!\n"); return false; }
    if (cpu(this)->o_dataAddr >= m_memSize) {
        LOG_E("Store data address [ %d ] is out-of-bounds from memory [ %ld ]!\n", cpu(this)->o_dataAddr, m_memSize);
        return false;
    }
    // Store the data
    *(int*)&m_mem[cpu(this)->o_dataAddr] = cpu(this)->o_dataOut;
    return true;
}
// ====================================================================================================================
bool boredcore::peekMem(int addr, int& val) {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot 'peek' in NULL memory!\n"); return false; }
    if (addr >= m_memSize) {
        LOG_E("'Peek' address [ %d ] is out-of-bounds from memory [ %ld ]!\n", addr, m_memSize);
        return false;
    }
    val = *(int*)&m_mem[addr];
    return true;
}
// ====================================================================================================================
bool boredcore::pokeMem(int addr, int val) {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot 'poke' at NULL memory!\n"); return false; }
    if (addr >= m_memSize) {
        LOG_E("'Poke' address [ %d ] is out-of-bounds from memory [ %ld ]!\n", addr, m_memSize);
        return false;
    }
    *(int*)&m_mem[addr] = val;
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
// ====================================================================================================================
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
