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
TEST(basic, loop) { // Basic test loop summation for 10 iterations
    boredcore dut  = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_loop.vcd")) {
        FAIL();
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_simple_loop.mem";
    if (!dut.createStimuli(testMachCodePath)) {
        FAIL();
    }
    dut.reset(2); // Hold reset line for 2cc

    bool done = false;
    constexpr int j = 8;
    constexpr int doneReg = 1; // x1
    constexpr int simDoneVal = -1;
    constexpr int expectedResult= 45;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = 0xdeadc0de;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }
    EXPECT_EQ(dut.readRegfile(j), expectedResult);
}
// ====================================================================================================================
TEST(basic, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    boredcore dut  = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_logic.vcd")) {
        FAIL();
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_logic_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_logic_test.regs";
    if (!dut.createStimuli(testMachCodePath, initRegfileValPath)) {
        FAIL();
    }
    dut.reset(2); // Hold reset line for 2cc

    // Init regfile
    for (auto it = dut.m_stimulus.init_regfile.begin(); it != dut.m_stimulus.init_regfile.end(); ++it) {
        int idx = it - dut.m_stimulus.init_regfile.begin();
        dut.writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
    }

    bool done = false;
    constexpr int doneReg = 6;      // x6
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
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
TEST(basic, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    boredcore dut  = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_arith.vcd")) {
        FAIL();
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_arith_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_arith_test.regs";
    if (!dut.createStimuli(testMachCodePath, initRegfileValPath)) {
        FAIL();
    }
    dut.reset(2); // Hold reset line for 2cc

    // Init regfile
    for (auto it = dut.m_stimulus.init_regfile.begin(); it != dut.m_stimulus.init_regfile.end(); ++it) {
        int idx = it - dut.m_stimulus.init_regfile.begin();
        dut.writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
    }

    bool done = false;
    constexpr int doneReg = 13;     // x13
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
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
TEST(basic, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    boredcore dut  = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_jump.vcd")) {
        FAIL();
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_jump_test.mem";
    if (!dut.createStimuli(testMachCodePath)) {
        FAIL();
    }
    dut.reset(2); // Hold reset line for 2cc

    bool done = false;
    constexpr int doneReg = 13;     // x13
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
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
