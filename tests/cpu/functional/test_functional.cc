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
TEST(functional, loop) { // Basic test loop summation for 10 iterations
    boredcore dut                   = boredcore(200);
    const char *testMachCodePath    = BASE_PATH "/cpu_simple_loop.mem";
    if (!dut.create(new Vboredcore(), "obj_dir/simple_loop.vcd"))   { FAIL(); }
    if (!dut.createStimulus(testMachCodePath))                      { FAIL(); }

    bool done                   = false;
    constexpr int j             = 8;
    constexpr int doneReg       = 1;
    constexpr int simDoneVal    = -1;
    constexpr int expectedVal   = 45;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = 0xdeadc0de;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    EXPECT_EQ(dut.readRegfile(j), expectedVal);
}
// ====================================================================================================================
TEST(functional, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    boredcore dut                   = boredcore(200);
    const char *testMachCodePath    = BASE_PATH "/cpu_logic_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_logic_test.regs";
    if (!dut.create(new Vboredcore(), "obj_dir/simple_logic.vcd")) { FAIL(); }
    if (!dut.createStimulus(testMachCodePath, initRegfileValPath)) { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 6;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = 0xdeadc0de;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    boredcore dut                   = boredcore(200);
    const char *testMachCodePath    = BASE_PATH "/cpu_arith_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_arith_test.regs";
    if (!dut.create(new Vboredcore(), "obj_dir/simple_arith.vcd")) { FAIL(); }
    if (!dut.createStimulus(testMachCodePath, initRegfileValPath)) { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 13;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = 0xdeadc0de;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    boredcore dut                   = boredcore(200);
    const char *testMachCodePath    = BASE_PATH "/cpu_jump_test.mem";
    if (!dut.create(new Vboredcore(), "obj_dir/simple_jump.vcd"))   { FAIL(); }
    if (!dut.createStimulus(testMachCodePath))                      { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 13;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = 0xdeadc0de;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, load_store) { // Tests load and store based instructions
    boredcore dut                   = boredcore(200);
    const char *testMachCodePath    = BASE_PATH "/cpu_load_store.mem";
    if (!dut.create(new Vboredcore(), "obj_dir/simple_load_store.vcd")) { FAIL(); }
    if (!dut.createStimulus(testMachCodePath))                          { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 1;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    constexpr int testAddress   = 0xcafebabe;
    constexpr int sbGold        = 0xffffffef;
    constexpr int shGold        = 0xffffbeef;
    constexpr int swGold        = 0xdeadbeef;

    // Create a dummy/test memory (and access helpers)
    constexpr int testMemLen    = 16;
    int testMem[testMemLen]     = {0};
    auto checkAddr = [](int addr) {
        if (addr < testAddress || addr >= testAddress + testMemLen) { FAIL() << "Test address is out of bounds!"; }
    };
    auto readMem    = [checkAddr](int addr, int* mem)           { checkAddr(addr); return mem[addr - testAddress];  };
    auto writeMem   = [checkAddr](int addr, int* mem, int val)  { checkAddr(addr); mem[addr - testAddress] = val;   };
    writeMem(testAddress, testMem, swGold); // Init the memory

    while (!dut.end() && !done) {
        dut.m_cpu->i_ifValid    = 1; // We assume combinatorial read/write for memories in this test
        dut.m_cpu->i_memValid   = 1; // We assume combinatorial read/write for memories in this test
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = dut.m_cpu->o_loadReq ? readMem(cpu(&dut)->o_dataAddr, testMem) : 0xffffffff;
        // Update test mem on a store
        if (dut.m_cpu->o_storeReq) {
            writeMem(cpu(&dut)->o_dataAddr, testMem, cpu(&dut)->o_dataOut);
        }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    // Load instructions
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
    // Store instructions
    EXPECT_EQ(testMem[4] , sbGold);
    EXPECT_EQ(testMem[8] , shGold);
    EXPECT_EQ(testMem[12], swGold);
}
