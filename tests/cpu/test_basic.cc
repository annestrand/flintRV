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
TEST(boredcore, simple_loop) {
    simulation sim  = simulation(200);
    if (!sim.create(new Vboredcore(), "obj_dir/waveform.vcd")) {
        FAIL() << "Failed to create waveform.vcd file!";
    }
    // --- Create test stimuli
    const char *testAsmPath         = BASE_PATH "/../tests/cpu/programs/cpu_simple_loop.s";
    const char *testMachCodePath    = BASE_PATH "/cpu_simple_loop.mem";
    if (!sim.createStimuli(testAsmPath, testMachCodePath)) {
        FAIL();
    }
    // --- Simulation loop
    sim.reset(2); // Hold reset line for 2cc
    bool done = false;
    constexpr int j = 8;
    constexpr int doneReg = 1;
    constexpr int simDoneVal = -1;
    constexpr int expectedResult = 45;
    while (!sim.end() && !done) {
        std::string instr       = sim.m_stimulus.instructions[sim.m_cpu->o_pcOut >> 2];
        int machine_instr       = (int)std::strtol(
            sim.m_stimulus.machine_code[sim.m_cpu->o_pcOut >> 2].c_str(), NULL, 16
        );
        sim.m_cpu->i_instr      = machine_instr;
        sim.m_cpu->i_dataIn     = 0xdeadc0de;
        sim.m_cpu->i_ifValid    = 1;
        sim.m_cpu->i_memValid   = 1;
        LOG_I("%08x: 0x%08x   %s\n", cpu->o_pcOut, machine_instr, instr.c_str());
        done = cpu(&sim)->boredcore__DOT__REGFILE_unit__DOT__RS1_PORT__DOT__ram[doneReg] == simDoneVal;
        // Evaluate
        sim.tick();
    }
    EXPECT_EQ(cpu(&sim)->boredcore__DOT__REGFILE_unit__DOT__RS1_PORT__DOT__ram[j], expectedResult);
}
