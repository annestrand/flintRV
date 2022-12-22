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
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vdrop32.h"
#include "Vdrop32__Syms.h"
#include "drop32.hh"
#include "common.hh"

namespace {
// Embed the test programs binaries here
#include "arith.inc"
#include "logic.inc"
#include "jump_branch.inc"
#include "load_store.inc"
#include "simple_loop.inc"
}

extern int g_dumpLevel;

// ====================================================================================================================
TEST(basic, loop) { // Basic test loop summation for 10 iterations
    drop32 dut = drop32(200, g_dumpLevel);
    if (!dut.create(new Vdrop32(), "obj_dir/simple_loop.vcd"))                               { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_simple_loop_hex, build_tests_simple_loop_hex_len)) { FAIL(); }

    constexpr int resultReg     = S2;
    constexpr int expectedVal   = 45;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), expectedVal);
}
// ====================================================================================================================
TEST(basic, logic) { // Tests all the core logic functions of ALU (e.g. AND, OR, XOR, etc.)
    drop32 dut = drop32(200, g_dumpLevel);
    if (!dut.create(new Vdrop32(), "obj_dir/simple_logic.vcd"))                  { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_logic_hex, build_tests_logic_hex_len)) { FAIL(); }

    // Init regfile contents
    constexpr int cpu_logic_test_regs_len = 10;
    long int cpu_logic_test_regs[] = {
        0 /* x0 reg */, 834, 391, 258, 967, 709, 391, 258, 967, 709
    };
    for (int i=0; i<cpu_logic_test_regs_len; ++i) {
        dut.writeRegfile(i, cpu_logic_test_regs[i]);
    }

    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(basic, arith) { // Tests all the core arithmetic functions of ALU (e.g. ADD, SUB, SRL etc.)
    drop32 dut = drop32(200, g_dumpLevel);
    if (!dut.create(new Vdrop32(), "obj_dir/simple_arith.vcd"))                  { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_arith_hex, build_tests_arith_hex_len)) { FAIL(); }

    // Init regfile contents
    constexpr int cpu_arith_test_regs_len = 13;
    long int cpu_arith_test_regs[cpu_arith_test_regs_len] = {
        0 /* x0 reg */, 439, -371, 68, 810, 230162432, 1182793728, 0, 511, 0, 4294967295, 23, 19
    };
    for (int i=0; i<cpu_arith_test_regs_len; ++i) {
        dut.writeRegfile(i, cpu_arith_test_regs[i]);
    }

    constexpr int resultReg     = 31;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(basic, jump) { // Tests all the core branch instructions (e.g. BEQ, JAL, BNE, etc.)
    drop32 dut = drop32(200, g_dumpLevel);
    if (!dut.create(new Vdrop32(), "obj_dir/simple_jump.vcd"))                               { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_jump_branch_hex, build_tests_jump_branch_hex_len)) { FAIL(); }

    constexpr int resultReg     = S1;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end()) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
        // Evaluate
        dut.tick();
    }

    EXPECT_EQ(dut.readRegfile(resultReg), 0);
}
// ====================================================================================================================
TEST(basic, load_store) { // Tests load and store based instructions
    drop32 dut = drop32(200, g_dumpLevel);
    if (!dut.create(new Vdrop32(), "obj_dir/simple_load_store.vcd"))                         { FAIL(); }
    if (!dut.createMemory(0x200, build_tests_load_store_hex, build_tests_load_store_hex_len))   { FAIL(); }

    constexpr int resultReg     = S7;
    constexpr int testAddress   = 0x100; // Lower half of test memory for data
    constexpr int sbGold        = 0xef;
    constexpr int shGold        = 0xbeef;
    constexpr int swGold        = 0xdeadbeef;
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory
    // Init test location of memory
    if(!dut.pokeMem(testAddress, swGold)) { FAIL(); }

    while (!dut.end()) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadStoreUpdate())      { FAIL(); }
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
