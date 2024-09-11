// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <cstdio>
#include <gtest/gtest.h>
#include <iostream>
#include <string>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VflintRV.h"
#include "VflintRV__Syms.h"

#include "common/utils.h"

#include "flintRV/flintRV.h"

namespace {
// Embed the test programs binaries here
#include "arith.inc"
#include "jump_branch.inc"
#include "load_store.inc"
#include "logic.inc"
#include "simple_loop.inc"
} // namespace

extern int g_testTracing;

TEST(basic, loop) { // Basic test loop summation for 10 iterations
    flintRV dut = flintRV(200, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(0x200, simple_loop_hex, simple_loop_hex_len)) {
        FAIL();
    }

    constexpr int resultReg = S2;
    constexpr int expectedVal = 45;
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            FAIL();
        }
        if (!dut.loadStoreUpdate()) {
            FAIL();
        }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), expectedVal);
}

TEST(basic, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR,
                     // XOR, etc.)
    flintRV dut = flintRV(200, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(0x200, logic_hex, logic_hex_len)) {
        FAIL();
    }

    // Init regfile contents
    constexpr int cpu_logic_test_regs_len = 10;
    long int cpu_logic_test_regs[] = {
        0 /* x0 reg */, 834, 391, 258, 967, 709, 391, 258, 967, 709};
    for (int i = 0; i < cpu_logic_test_regs_len; ++i) {
        dut.writeRegfile(i, cpu_logic_test_regs[i]);
    }

    constexpr int resultReg = 31;
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            FAIL();
        }
        if (!dut.loadStoreUpdate()) {
            FAIL();
        }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}

TEST(basic, arith) { // Tests all the core arithmetic functions of ALU (e.g.
                     // ADD, SUB, SRL etc.)
    flintRV dut = flintRV(200, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(0x200, arith_hex, arith_hex_len)) {
        FAIL();
    }

    // Init regfile contents
    constexpr int cpu_arith_test_regs_len = 13;
    long int cpu_arith_test_regs[cpu_arith_test_regs_len] = {
        0 /* x0 reg */, 439, -371, 68, 810, 230162432, 1182793728, 0, 511, 0,
        4294967295,     23,  19};
    for (int i = 0; i < cpu_arith_test_regs_len; ++i) {
        dut.writeRegfile(i, cpu_arith_test_regs[i]);
    }

    constexpr int resultReg = 31;
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            FAIL();
        }
        if (!dut.loadStoreUpdate()) {
            FAIL();
        }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}

TEST(
    basic,
    jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    flintRV dut = flintRV(200, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(0x200, jump_branch_hex, jump_branch_hex_len)) {
        FAIL();
    }

    constexpr int resultReg = S1;
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            FAIL();
        }
        if (!dut.loadStoreUpdate()) {
            FAIL();
        }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}

TEST(basic, load_store) { // Tests load and store based instructions
    flintRV dut = flintRV(200, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(0x200, load_store_hex, load_store_hex_len)) {
        FAIL();
    }

    constexpr int resultReg = S7;
    constexpr int testAddress = 0x100; // Lower half of test memory for data
    constexpr int sbGold = 0xef;
    constexpr int shGold = 0xbeef;
    constexpr int swGold = 0xdeadbeef;
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory
    // Init test location of memory
    if (!dut.pokeMem(testAddress, swGold)) {
        FAIL();
    }

    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            FAIL();
        }
        if (!dut.loadStoreUpdate()) {
            FAIL();
        }
        // Evaluate
        dut.tick();
    }

    // Load instructions
    EXPECT_EQ(dut.readRegfile(resultReg), 0);
    // Store instructions
    int resultSb, resultSh, resultSw;
    if (!dut.peekMem(testAddress + 4, resultSb)) {
        FAIL();
    }
    if (!dut.peekMem(testAddress + 8, resultSh)) {
        FAIL();
    }
    if (!dut.peekMem(testAddress + 12, resultSw)) {
        FAIL();
    }
    EXPECT_EQ(resultSb, sbGold);
    EXPECT_EQ(resultSh, shGold);
    EXPECT_EQ(resultSw, swGold);
}
