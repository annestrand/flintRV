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
    boredcore dut = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_loop.vcd"))       { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/simple_loop.mem"))  { FAIL(); }

    bool done                   = false;
    constexpr int j             = 8;
    constexpr int doneReg       = 1;
    constexpr int simDoneVal    = -1;
    constexpr int expectedVal   = 45;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(j), expectedVal);
}
// ====================================================================================================================
TEST(functional, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    boredcore dut = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_logic.vcd", BASE_PATH "/cpu_logic_test.regs"))    { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/cpu_logic_test.mem"))                                   { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 6;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    boredcore dut = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_arith.vcd", BASE_PATH "/cpu_arith_test.regs"))    { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/cpu_arith_test.mem"))                                   { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 13;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    boredcore dut = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_jump.vcd"))       { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/cpu_jump_test.mem"))    { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 13;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(functional, load_store) { // Tests load and store based instructions
    boredcore dut = boredcore(200);
    if (!dut.create(new Vboredcore(), "obj_dir/simple_load_store.vcd")) { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/load_store.mem"))   { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = 1;
    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    constexpr int testAddress   = 0x1000; // Lower 4KB of test memory for data
    constexpr int sbGold        = 0xffffffef;
    constexpr int shGold        = 0xffffbeef;
    constexpr int swGold        = 0xdeadbeef;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory
    // Init test location of memory
    if(!dut.pokeMem(testAddress, swGold)) { FAIL(); }

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

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
