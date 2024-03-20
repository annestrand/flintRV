// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <algorithm>
#include <atomic>
#include <cstdio>
#include <iostream>
#include <string>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "Vdrop32.h"
#include "Vdrop32/drop32.h"
#include "Vdrop32__Syms.h"

#include "common/utils.h"

drop32::drop32(vluint64_t maxSimTime, bool tracing)
    : m_cpu(nullptr), m_cycles(0), m_trace(nullptr), m_maxSimTime(maxSimTime),
      m_tracing(tracing), m_mem(nullptr), m_memSize(0) {}

drop32::~drop32() {
    m_cpu->final();
    if (m_trace != nullptr) {
        m_trace->close();
        delete m_trace;
        m_trace = nullptr;
    }
    if (m_cpu != nullptr) {
        delete m_cpu;
        m_cpu = nullptr;
    }
    if (m_mem != nullptr) {
        delete[] m_mem;
        m_mem = nullptr;
    }
}

bool drop32::create(Vdrop32 *cpu, const char *traceFile) {
    if (cpu == nullptr) {
        LOG_ERROR("Failed to create Verilated drop32 module!\n");
        return false;
    }
    m_cpu = cpu;
    if (traceFile != nullptr) {
        Verilated::traceEverOn(true);
        m_trace = new VerilatedVcdC;
        if (m_trace == nullptr) {
            LOG_WARNING("Failed to create drop32 VCD dumper!\n");
        } else if (traceFile != nullptr) {
            m_cpu->trace(m_trace, 99);
            m_trace->open(traceFile);
        }
    }
    reset(1); // Reset CPU on create for 1cc
    return true;
}

bool drop32::createMemory(size_t memSize) {
    if (memSize == 0) {
        LOG_ERROR("Memory cannot be of size 0!\n");
        return false;
    }
    m_memSize = memSize;
    m_mem = new char[memSize];
    if (m_mem == nullptr) {
        LOG_ERROR_PRINTF("Failed to allocate %ld bytes!\n", m_memSize);
        return false;
    }
    std::memset(m_mem, 0, m_memSize);
    return true;
}

bool drop32::createMemory(size_t memSize, std::string initHexfile) {
    if (memSize == 0) {
        LOG_ERROR("Memory cannot be of size 0!\n");
        return false;
    }
    m_memSize = memSize;
    m_mem = new char[memSize];
    if (m_mem == nullptr) {
        LOG_ERROR_PRINTF("Failed to allocate %ld bytes!\n", m_memSize);
        return false;
    }
    std::memset(m_mem, 0, m_memSize);
    // Init mem from hexfile
    return loadMem(initHexfile, m_mem, m_memSize);
}

bool drop32::createMemory(size_t memSize, unsigned char *initHexarray,
                          unsigned int initHexarrayLen) {
    if (memSize == 0) {
        LOG_ERROR("Memory cannot be of size 0!\n");
        return false;
    }
    if (memSize < initHexarrayLen) {
        LOG_ERROR("Cannot fit initialization hex char array into memory!\n");
        return false;
    }
    m_memSize = memSize;
    m_mem = new char[memSize];
    if (m_mem == nullptr) {
        LOG_ERROR_PRINTF("Failed to allocate %ld bytes!\n", m_memSize);
        return false;
    }
    std::memset(m_mem, 0, m_memSize);
    // Init mem from char array
    std::memcpy(m_mem, initHexarray, initHexarrayLen);
    return true;
}

bool drop32::instructionUpdate() {
    // Error check
    if (m_mem == nullptr) {
        LOG_ERROR("Cannot fetch instruction from NULL memory!\n");
        return false;
    }
    if (m_cpu->o_pcOut >= m_memSize) {
        LOG_ERROR_PRINTF(
            "PC address [ 0x%x ] is out-of-bounds from memory [ 0x0 - 0x%lx "
            "]!\n",
            m_cpu->o_pcOut, m_memSize);
        return false;
    }
    // Fetch the next instruction
    m_cpu->i_instr = *(int *)&m_mem[m_cpu->o_pcOut];
    return true;
}

bool drop32::loadStoreUpdate() {
    // Request and error checking
    if (!m_cpu->o_loadReq && !m_cpu->o_storeReq) {
        return true;
    } // Skip if there was no load/store request
    if (m_mem == nullptr) {
        LOG_ERROR("Cannot loadStoreUpdate on NULL memory!\n");
        return false;
    }
    if (m_cpu->o_dataAddr >= m_memSize) {
        LOG_ERROR_PRINTF(
            "Address [ 0x%x ] is out-of-bounds from memory [ 0x0 - 0x%lx ]!\n",
            m_cpu->o_dataAddr, m_memSize);
        return false;
    }

    if (m_cpu->o_loadReq) { // Load
        m_cpu->i_dataIn = *(int *)&m_mem[m_cpu->o_dataAddr];
    } else { // Store
        if (CPU(this)->p_funct3[CPU(this)->MEM] == CPU(this)->S_B_OP) {
            *(int *)&m_mem[m_cpu->o_dataAddr] &= 0xffffff00;
            *(int *)&m_mem[m_cpu->o_dataAddr] |= m_cpu->o_dataOut;
        } else if (CPU(this)->p_funct3[CPU(this)->MEM] == CPU(this)->S_H_OP) {
            *(int *)&m_mem[m_cpu->o_dataAddr] &= 0xffff0000;
            *(int *)&m_mem[m_cpu->o_dataAddr] |= m_cpu->o_dataOut;
        } else {
            *(int *)&m_mem[m_cpu->o_dataAddr] = m_cpu->o_dataOut;
        }
    }
    return true;
}

bool drop32::peekMem(size_t addr, int &val) {
    // Error check
    if (m_mem == nullptr) {
        LOG_ERROR("Cannot 'peek' in NULL memory!\n");
        return false;
    }
    if (addr >= m_memSize) {
        LOG_ERROR_PRINTF(
            "'Peek' address 0x%lx is out-of-bounds from memory [ 0x0 - 0x%lx "
            "]!\n",
            addr, m_memSize);
        return false;
    }
    val = *(int *)&m_mem[addr];
    return true;
}

bool drop32::pokeMem(size_t addr, int val) {
    // Error check
    if (m_mem == nullptr) {
        LOG_ERROR("Cannot 'poke' at NULL memory!\n");
        return false;
    }
    if (addr >= m_memSize) {
        LOG_ERROR_PRINTF(
            "'Poke' address 0x%lx is out-of-bounds from memory [ 0x0 - 0x%lx "
            "]!\n",
            addr, m_memSize);
        return false;
    }
    *(int *)&m_mem[addr] = val;
    return true;
}

void drop32::writeRegfile(int index, int val) {
    // Skip if x0 reg
    if (index == 0) {
        return;
    }
    // Need to write to both ports
    CPU(this)->REGFILE_unit->RS1_PORT_RAM->ram[index] = val;
    CPU(this)->REGFILE_unit->RS2_PORT_RAM->ram[index] = val;
}

int drop32::readRegfile(int index) {
    // Does not matter which port we read from
    return (index == 0) ? 0 : CPU(this)->REGFILE_unit->RS1_PORT_RAM->ram[index];
}

void drop32::reset(int cycles) {
    // Some dummy values for now
    m_cpu->i_instr = 0x0badc0de;
    m_cpu->i_dataIn = 0xdecafbad;
    m_cpu->i_ifValid = 0;
    m_cpu->i_memValid = 0;
    // Toggle reset
    m_cpu->i_rst = 1;
    for (int i = 0; i < cycles; ++i) {
        tick();
    }
    m_cpu->i_rst = 0;
}

void drop32::tick(bool enableDump) {
    static std::atomic<vluint64_t> global_time{0};
    if (enableDump) {
        dump();
    }
    m_cpu->i_clk = 0;
    m_cpu->eval();
    if (m_trace) {
        m_trace->dump(global_time++);
    }
    m_cpu->i_clk = 1;
    m_cpu->eval();
    if (m_trace) {
        m_trace->dump(global_time++);
    }
    m_cycles++;
}

void drop32::dump() {
    if (m_tracing) {
        std::string instr =
            m_cpu->i_rst ? "CPU Reset!" : disassembleRv32i(m_cpu->i_instr);
        printf("%8x:   0x%08x   %-30s CYCLE:[%" PRIu64 "]\n", m_cpu->o_pcOut,
               m_cpu->i_instr, instr.c_str(), m_cycles);
    }
}

bool drop32::end() {
    bool isEbreak = m_cpu->i_instr == EBREAK;
    bool isFinished =
        Verilated::gotFinish() || m_cycles > m_maxSimTime || isEbreak;
    if (isEbreak) {
        // Need to finish draining pipeline here...
        for (int i = 0; i < 3; i++) {
            loadStoreUpdate();
            tick(false);
        }
    }
    return isFinished;
}
