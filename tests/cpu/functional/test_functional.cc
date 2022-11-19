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
#include "functional/test_binaries.h"

// Initial regfile content files
namespace {
#include "cpu_logic_test_regs.inc"
#include "cpu_arith_test_regs.inc"
}

extern int g_dumpLevel;

// ====================================================================================================================
TEST(functional, loop) { // Basic test loop summation for 10 iterations
    boredcore dut = boredcore(200, g_dumpLevel);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_loop.vcd"))                               { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_simple_loop_hex, build_tests_simple_loop_hex_len)) { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = S1;
    constexpr int resultReg     = S2;
    constexpr int expectedVal   = 45;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        done = dut.readRegfile(doneReg) == SIM_DONE_VAL;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(done, true) << "Simulation timeout!";
    EXPECT_EQ(dut.readRegfile(resultReg), expectedVal);
}
// ====================================================================================================================
TEST(functional, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    boredcore dut = boredcore(200, g_dumpLevel);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_logic.vcd"))                                      { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_cpu_logic_test_hex, build_tests_cpu_logic_test_hex_len))   { FAIL(); }

    // Init regfile contents
    for (int i=0; i<sizeof(cpu_logic_test_regs)/sizeof(cpu_logic_test_regs[0]); ++i) {
        dut.writeRegfile(i, cpu_logic_test_regs[i]);
    }

    bool done                   = false;
    constexpr int doneReg       = 6;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(doneReg), simDoneVal) << "Simulation timeout!";
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    boredcore dut = boredcore(200, g_dumpLevel);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_arith.vcd"))                                      { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_cpu_arith_test_hex, build_tests_cpu_arith_test_hex_len))   { FAIL(); }

    // Init regfile contents
    for (int i=0; i<sizeof(cpu_arith_test_regs)/sizeof(cpu_arith_test_regs[0]); ++i) {
        dut.writeRegfile(i, cpu_arith_test_regs[i]);
    }

    bool done                   = false;
    constexpr int doneReg       = 13;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(doneReg), simDoneVal) << "Simulation timeout!";
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    boredcore dut = boredcore(200, g_dumpLevel);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_jump.vcd"))                               { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_jump_branch_hex, build_tests_jump_branch_hex_len)) { FAIL(); }

    bool done                   = false;
    constexpr int resultReg     = S1;
    constexpr int doneReg       = S2;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        done = dut.readRegfile(doneReg) == SIM_DONE_VAL;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(done, true) << "Simulation timeout!";
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, load_store) { // Tests load and store based instructions
    boredcore dut = boredcore(200, g_dumpLevel);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_load_store.vcd"))                         { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_load_store_hex, build_tests_load_store_hex_len))   { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = S8;
    constexpr int resultReg     = S7;
    constexpr int testAddress   = 0x100; // Lower half of test memory for data
    constexpr int sbGold        = 0xffffffef;
    constexpr int shGold        = 0xffffbeef;
    constexpr int swGold        = 0xdeadbeef;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory
    // Init test location of memory
    if(!dut.pokeMem(testAddress, swGold)) { FAIL(); }

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        done = dut.readRegfile(doneReg) == SIM_DONE_VAL;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(done, true) << "Simulation timeout!";
    // Load instructions
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
    // Store instructions
    int resultSb, resultSh, resultSw;
    if (!dut.peekMem(testAddress+4,  resultSb)) { FAIL(); }
    if (!dut.peekMem(testAddress+8,  resultSh)) { FAIL(); }
    if (!dut.peekMem(testAddress+12, resultSw)) { FAIL(); }
    EXPECT_EQ(resultSb, sbGold);
    EXPECT_EQ(resultSh, shGold);
    EXPECT_EQ(resultSw, swGold);
}
