// Copyright (c) 2022 Austin Annestrand
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <cstdio>
#include <string>
#include <vector>
#include <iostream>
#include <algorithm>
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "Vdrop32.h"
#include "Vdrop32__Syms.h"
#include "drop32.hh"
#include "common.hh"

// ====================================================================================================================
drop32::drop32(vluint64_t maxSimTime, int dumpLevel) :
    m_cpu(nullptr), m_cycles(0), m_trace(nullptr), m_maxSimTime(maxSimTime), m_dump(dumpLevel), m_mem(nullptr),
        m_memSize(0) {}
// ====================================================================================================================
drop32::~drop32() {
    m_cpu->final();
    if (m_trace != nullptr) { m_trace->close(); delete m_trace; m_trace = nullptr;  }
    if (m_cpu != nullptr)   { delete m_cpu; m_cpu = nullptr;                        }
    if (m_mem != nullptr)   { delete[] m_mem; m_mem = nullptr;                      }
}
// ====================================================================================================================
bool drop32::create(Vdrop32* cpu, const char* traceFile) {
    if (cpu == nullptr) {
        LOG_E("Failed to create Verilated drop32 module!\n");
        return false;
    }
    m_cpu = cpu;
    Verilated::traceEverOn(true);
    if (m_trace == nullptr) {
        m_trace = new VerilatedVcdC;
        if (m_trace == nullptr) {
            LOG_W("Failed to create drop32 VCD dumper!\n");
        } else if (traceFile != nullptr) {
            m_cpu->trace(m_trace, 99);
            m_trace->open(traceFile);
        }
    }
    reset(1); // Reset CPU on create for 1cc
    return true;
}
// ====================================================================================================================
bool drop32::createMemory(size_t memSize) {
    if (memSize == 0) { LOG_E("Memory cannot be of size 0!\n"); return false; }
    m_memSize   = memSize;
    m_mem       = new char[memSize];
    if (m_mem == nullptr) { LOG_E("Failed to allocate %ld bytes!\n", m_memSize); return false; }
    std::memset(m_mem, 0, m_memSize);
    return true;
}
// ====================================================================================================================
bool drop32::createMemory(size_t memSize, std::string initHexfile) {
    if (memSize == 0) { LOG_E("Memory cannot be of size 0!\n"); return false; }
    m_memSize   = memSize;
    m_mem       = new char[memSize];
    if (m_mem == nullptr) { LOG_E("Failed to allocate %ld bytes!\n", m_memSize); return false; }
    std::memset(m_mem, 0, m_memSize);
    // Init mem from hexfile
    return loadMem(initHexfile, m_mem, m_memSize);
}
// ====================================================================================================================
bool drop32::createMemory(size_t memSize, unsigned char* initHexarray, unsigned int initHexarrayLen) {
    if (memSize == 0) { LOG_E("Memory cannot be of size 0!\n"); return false; }
    if (memSize < initHexarrayLen) { LOG_E("Cannot fit initialization hex char array into memory!\n"); return false; }
    m_memSize   = memSize;
    m_mem       = new char[memSize];
    if (m_mem == nullptr) { LOG_E("Failed to allocate %ld bytes!\n", m_memSize); return false; }
    std::memset(m_mem, 0, m_memSize);
    // Init mem from char array
    std::memcpy(m_mem, initHexarray, initHexarrayLen);
    return true;
}
// ====================================================================================================================
bool drop32::instructionUpdate() {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot fetch instruction from NULL memory!\n"); return false; }
    if (m_cpu->o_pcOut >= m_memSize) {
        LOG_E("PC address [ 0x%x ] is out-of-bounds from memory [ 0x0 - 0x%lx ]!\n", m_cpu->o_pcOut, m_memSize);
        return false;
    }
    // Fetch the next instruction
    m_cpu->i_instr = *(int*)&m_mem[m_cpu->o_pcOut];
    return true;
}
// ====================================================================================================================
bool drop32::loadStoreUpdate() {
    // Request and error checking
    if (!m_cpu->o_loadReq && !m_cpu->o_storeReq) { return true; } // Skip if there was no load/store request
    if (m_mem == nullptr) { LOG_E("Cannot loadStoreUpdate on NULL memory!\n"); return false; }
    if (m_cpu->o_dataAddr >= m_memSize) {
        LOG_E("Address [ 0x%x ] is out-of-bounds from memory [ 0x0 - 0x%lx ]!\n", m_cpu->o_dataAddr, m_memSize);
        return false;
    }

    if (m_cpu->o_loadReq) { // Load
        m_cpu->i_dataIn = *(int*)&m_mem[m_cpu->o_dataAddr];
    } else { // Store
        if (CPU(this)->MEMORY_unit->i_funct3 == CPU(this)->MEMORY_unit->S_B_OP) {
            *(int*)&m_mem[m_cpu->o_dataAddr] &= 0xffffff00;
            *(int*)&m_mem[m_cpu->o_dataAddr] |= m_cpu->o_dataOut;
        } else if (CPU(this)->MEMORY_unit->i_funct3 == CPU(this)->MEMORY_unit->S_H_OP) {
            *(int*)&m_mem[m_cpu->o_dataAddr] &= 0xffff0000;
            *(int*)&m_mem[m_cpu->o_dataAddr] |= m_cpu->o_dataOut;
        } else {
            *(int*)&m_mem[m_cpu->o_dataAddr] = m_cpu->o_dataOut;
        }
    }
    return true;
}
// ====================================================================================================================
bool drop32::peekMem(int addr, int& val) {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot 'peek' in NULL memory!\n"); return false; }
    if (addr >= m_memSize) {
        LOG_E("'Peek' address 0x%x is out-of-bounds from memory [ 0x0 - 0x%lx ]!\n", addr, m_memSize);
        return false;
    }
    val = *(int*)&m_mem[addr];
    return true;
}
// ====================================================================================================================
bool drop32::pokeMem(int addr, int val) {
    // Error check
    if (m_mem == nullptr) { LOG_E("Cannot 'poke' at NULL memory!\n"); return false; }
    if (addr >= m_memSize) {
        LOG_E("'Poke' address 0x%x is out-of-bounds from memory [ 0x0 - 0x%lx ]!\n", addr, m_memSize);
        return false;
    }
    *(int*)&m_mem[addr] = val;
    return true;
}
// ====================================================================================================================
void drop32::writeRegfile(int index, int val) {
    // Skip if x0 reg
    if (index == 0) { return; }
    // Need to write to both ports
    CPU(this)->FETCH_DECODE_unit->REGFILE_unit->RS1_PORT_RAM->ram[index] = val;
    CPU(this)->FETCH_DECODE_unit->REGFILE_unit->RS2_PORT_RAM->ram[index] = val;
}
// ====================================================================================================================
int drop32::readRegfile(int index) {
    // Does not matter which port we read from
    return (index == 0) ? 0 : CPU(this)->FETCH_DECODE_unit->REGFILE_unit->RS1_PORT_RAM->ram[index];
}
// ====================================================================================================================
void drop32::reset(int cycles) {
    // Some dummy values for now
    m_cpu->i_instr    = 0x0badc0de;
    m_cpu->i_dataIn   = 0xdecafbad;
    m_cpu->i_ifValid  = 0;
    m_cpu->i_memValid = 0;
    // Toggle reset
    m_cpu->i_rst = 1;
    for (int i=0; i<cycles; ++i) { tick(); }
    m_cpu->i_rst = 0;
}
// ====================================================================================================================
void drop32::tick(bool enableDump) {
    if (enableDump) { dump(); }
    m_cycles++;
    m_cpu->i_clk = 0;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(10*m_cycles-2); }
    m_cpu->i_clk = 1;
    m_cpu->eval();
    if(m_trace) { m_trace->dump(10*m_cycles); m_trace->flush(); }
}
// ====================================================================================================================
void drop32::dump() {
    if (!m_dump) { return; }
    std::string instr   = m_cpu->i_rst ? "CPU Reset!" : disassembleRv32i(m_cpu->i_instr);
    bool fStall         = CPU(this)->FETCH_stall;
    bool eStall         = CPU(this)->EXEC_stall;
    bool mStall         = CPU(this)->MEM_stall;
    bool fFlush         = CPU(this)->FETCH_flush;
    bool eFlush         = CPU(this)->EXEC_flush;
    bool mFlush         = CPU(this)->MEM_flush;
    bool wFlush         = CPU(this)->WB_flush;
    // Status codes
    bool BRA            = CPU(this)->braMispredict;             // B
    bool JMP            = CPU(this)->p_jmp[CPU(this)->EXEC];    // J
    bool LD_REQ         = m_cpu->o_loadReq;                     // L
    bool SD_REQ         = m_cpu->o_storeReq;                    // S
    bool RST            = m_cpu->i_rst;                         // R
    bool iValid         = m_cpu->i_ifValid;                     // I
    bool mValid         = m_cpu->i_memValid;                    // M
    // Dump disassembled instruction
    printf("%8x:   0x%08x   %-22s", m_cpu->o_pcOut, m_cpu->i_instr, instr.c_str());
    if (m_dump < 2) { printf("\n"); return; }
    // Dump more detailed info
    printf("STALL:[%c%c%c-]  FLUSH:[%c%c%c%c]  STATUS:[%c%c%c%c%c%c%c]  CYCLE:[%" PRIu64 "]\n",
        fStall ? 'x':'-', eStall ? 'x':'-', mStall ? 'x':'-',
        fFlush ? 'x':'-', eFlush ? 'x':'-', mFlush ? 'x':'-', wFlush ? 'x':'-',
        iValid ? 'I':'-', mValid ? 'M':'-', RST    ? 'R':'-', BRA    ? 'B':'-',
        JMP    ? 'J':'-', LD_REQ ? 'L':'-', SD_REQ ? 'S':'-',
        m_cycles
    );
}
// ====================================================================================================================
bool drop32::end() {
    bool isEbreak   = CPU(this)->ebreak && !CPU(this)->pcJump;
    bool isFinished = Verilated::gotFinish() || m_cycles > m_maxSimTime || isEbreak;
    if (isEbreak) {
        // Need to finish draining pipeline here...
        for (int i=0; i<3; i++) {
            loadStoreUpdate();
            tick(false);
        }
    }
    return isFinished;
}
// ====================================================================================================================
