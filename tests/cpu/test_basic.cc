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
TEST(simple, loop) { // Basic test loop summation for 10 iterations
    simulation sim  = simulation(200);
    if (!sim.create(new Vboredcore(), "obj_dir/simple_loop.vcd")) {
        FAIL() << "Failed to create vcd file!";
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_simple_loop.mem";
    if (!sim.createStimuli(testMachCodePath)) {
        FAIL();
    }
    sim.reset(2); // Hold reset line for 2cc

    bool done = false;
    constexpr int j = 8;
    constexpr int doneReg = 1; // x1
    constexpr int simDoneVal = -1;
    constexpr int expectedResult= 45;
    while (!sim.end() && !done) {
        std::string instr       = sim.m_stimulus.instructions[sim.m_cpu->o_pcOut >> 2];
        int machine_instr       = (int)HEX_DECODE_ASCII(sim.m_stimulus.machine_code[sim.m_cpu->o_pcOut >> 2].c_str());
        sim.m_cpu->i_instr      = machine_instr;
        sim.m_cpu->i_dataIn     = 0xdeadc0de;
        sim.m_cpu->i_ifValid    = 1;
        sim.m_cpu->i_memValid   = 1;
        LOG_I("%08x: 0x%08x   %s\n", sim.m_cpu->o_pcOut, machine_instr, instr.c_str());
        done = sim.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        sim.tick();
    }
    EXPECT_EQ(sim.readRegfile(j), expectedResult);
}
// ====================================================================================================================
TEST(simple, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    simulation sim  = simulation(200);
    if (!sim.create(new Vboredcore(), "obj_dir/simple_logic.vcd")) {
        FAIL() << "Failed to create vcd file!";
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_logic_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_logic_test.regs";
    if (!sim.createStimuli(testMachCodePath, initRegfileValPath)) {
        FAIL();
    }
    sim.reset(2); // Hold reset line for 2cc

    // Init regfile
    for (auto it = sim.m_stimulus.init_regfile.begin(); it != sim.m_stimulus.init_regfile.end(); ++it) {
        int idx = it - sim.m_stimulus.init_regfile.begin();
        sim.writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
    }

    bool done = false;
    constexpr int doneReg = 6;      // x6
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
    while (!sim.end() && !done) {
        std::string instr       = sim.m_stimulus.instructions[sim.m_cpu->o_pcOut >> 2];
        int machine_instr       = (int)HEX_DECODE_ASCII(sim.m_stimulus.machine_code[sim.m_cpu->o_pcOut >> 2].c_str());
        sim.m_cpu->i_instr      = machine_instr;
        sim.m_cpu->i_dataIn     = 0xdeadc0de;
        sim.m_cpu->i_ifValid    = 1;
        sim.m_cpu->i_memValid   = 1;
        LOG_I("%08x: 0x%08x   %s\n", sim.m_cpu->o_pcOut, machine_instr, instr.c_str());
        done = sim.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        sim.tick();
    }
    EXPECT_EQ(sim.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(simple, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    simulation sim  = simulation(200);
    if (!sim.create(new Vboredcore(), "obj_dir/simple_arith.vcd")) {
        FAIL() << "Failed to create vcd file!";
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_arith_test.mem";
    const char *initRegfileValPath  = BASE_PATH "/cpu_arith_test.regs";
    if (!sim.createStimuli(testMachCodePath, initRegfileValPath)) {
        FAIL();
    }
    sim.reset(2); // Hold reset line for 2cc

    // Init regfile
    for (auto it = sim.m_stimulus.init_regfile.begin(); it != sim.m_stimulus.init_regfile.end(); ++it) {
        int idx = it - sim.m_stimulus.init_regfile.begin();
        sim.writeRegfile(idx+1, INT_DECODE_ASCII((*it).c_str()));
    }

    bool done = false;
    constexpr int doneReg = 13;     // x13
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
    while (!sim.end() && !done) {
        std::string instr       = sim.m_stimulus.instructions[sim.m_cpu->o_pcOut >> 2];
        int machine_instr       = (int)HEX_DECODE_ASCII(sim.m_stimulus.machine_code[sim.m_cpu->o_pcOut >> 2].c_str());
        sim.m_cpu->i_instr      = machine_instr;
        sim.m_cpu->i_dataIn     = 0xdeadc0de;
        sim.m_cpu->i_ifValid    = 1;
        sim.m_cpu->i_memValid   = 1;
        LOG_I("%08x: 0x%08x   %s\n", sim.m_cpu->o_pcOut, machine_instr, instr.c_str());
        done = sim.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        sim.tick();
    }
    EXPECT_EQ(sim.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(simple, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    simulation sim  = simulation(200);
    if (!sim.create(new Vboredcore(), "obj_dir/simple_jump.vcd")) {
        FAIL() << "Failed to create vcd file!";
    }
    const char *testMachCodePath    = BASE_PATH "/cpu_jump_test.mem";
    if (!sim.createStimuli(testMachCodePath)) {
        FAIL();
    }
    sim.reset(2); // Hold reset line for 2cc

    bool done = false;
    constexpr int doneReg = 13;     // x13
    constexpr int resultReg = 31;   // x31
    constexpr int simDoneVal = -1;
    while (!sim.end() && !done) {
        std::string instr       = sim.m_stimulus.instructions[sim.m_cpu->o_pcOut >> 2];
        int machine_instr       = (int)HEX_DECODE_ASCII(sim.m_stimulus.machine_code[sim.m_cpu->o_pcOut >> 2].c_str());
        sim.m_cpu->i_instr      = machine_instr;
        sim.m_cpu->i_dataIn     = 0xdeadc0de;
        sim.m_cpu->i_ifValid    = 1;
        sim.m_cpu->i_memValid   = 1;
        LOG_I("%08x: 0x%08x   %s\n", sim.m_cpu->o_pcOut, machine_instr, instr.c_str());
        done = sim.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        sim.tick();
    }
    EXPECT_EQ(sim.readRegfile(resultReg), 0);
}
