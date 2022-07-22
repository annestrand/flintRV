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

#ifndef BASE_PATH // This is defined to be in "obj_dir/" by default - just adding placeholder here
#define BASE_PATH "."
#endif

// ====================================================================================================================
TEST(boredcore, placeholder) {
    Vboredcore *cpu = new Vboredcore;
    simulation sim  = simulation(200);
    if (!sim.create(cpu, "obj_dir/waveform.vcd")) {
        FAIL() << "Failed to create waveform.vcd file!";
    }
    // Read test vector files
    std::vector<std::string> instructions;
    std::vector<std::string> machine_code;
    std::string basedir(BASE_PATH);
    instructions = asmFileReader(basedir + "/../tests/cpu/programs/test_asm.s");
    if (instructions.empty()) {
        FAIL() << "Could not read ASM file!";
    }
    machine_code = machineCodeFileReader(basedir + "/test_asm.mem");
    if (machine_code.empty()) {
        FAIL() << "Could not read machine-code file!";
    }
    endianFlipper(machine_code); // Since objdump does output Verilog in big-endian

    // Simulation loop
    sim.reset(2); // Hold reset line for 2cc
    int reg_x4 = 0;
    bool done = false;
    while (!sim.end() && !done) {
        std::string instr   = instructions[cpu->o_pcOut >> 2];
        int machine_instr   = (int)std::strtol(machine_code[cpu->o_pcOut >> 2].c_str(), NULL, 16);
        cpu->i_instr          = machine_instr;
        cpu->i_dataIn         = 0xdeadc0de;
        cpu->i_ifValid        = 1;
        cpu->i_memValid       = 1;
        LOG_I("%08x: 0x%08x   %s\n",cpu->o_pcOut, machine_instr, instr.c_str());
        // Evaluate
        sim.tick();
    }
}
