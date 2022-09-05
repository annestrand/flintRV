#include <cstdio>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"
#include "boredcore.hh"
#include "common.hh"

// ====================================================================================================================
TEST(algorithms, fibonacci) {
    boredcore dut = boredcore(100000);
    if (!dut.create(new Vboredcore(), "obj_dir/fibonacci.vcd")) { FAIL(); }
    if (!dut.createMemory(0x4000, BASE_PATH "/fibonacci.mem"))  { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = S11;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1;    // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1;    // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        dut.tick(); // Evaluate
    }

    // Check results
    std::function<int(int)> fibonacci = [&](int x) {
        if (x <= 1) { return x; }
        return fibonacci(x - 1) + fibonacci(x - 2);
    };
    EXPECT_EQ(dut.readRegfile(S6), fibonacci(6));
    EXPECT_EQ(dut.readRegfile(S7), fibonacci(7));
    EXPECT_EQ(dut.readRegfile(S8), fibonacci(8));
    EXPECT_EQ(dut.readRegfile(S9), fibonacci(9));
    EXPECT_EQ(dut.readRegfile(S10), fibonacci(10));
    EXPECT_EQ(dut.readRegfile(doneReg), -1); // Make sure we did not time-out in simulation
}
// ====================================================================================================================
TEST(algorithms, binsearch) {
    boredcore dut = boredcore(100000);
    if (!dut.create(new Vboredcore(), "obj_dir/binsearch.vcd")) { FAIL(); }
    if (!dut.createMemory(0x4000, BASE_PATH "/binsearch.mem"))  { FAIL(); }

    bool done                   = false;
    constexpr int doneReg       = S11;
    constexpr int simDoneVal    = -1;
    dut.m_cpu->i_ifValid        = 1;    // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1;    // Always valid since we assume combinatorial read/write for test memory

    while (!dut.end() && !done) {
        if (!dut.instructionUpdate())    { FAIL(); }
        if (!dut.loadMemUpdate())        { FAIL(); }
        if (!dut.storeMemUpdate())       { FAIL(); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        dut.tick(); // Evaluate
    }

    // Check results
    EXPECT_EQ(dut.readRegfile(S1),   1);        // Testing valid binsearch result
    EXPECT_EQ(dut.readRegfile(S2),   1);        // Testing valid binsearch result
    EXPECT_EQ(dut.readRegfile(S3),   1);        // Testing valid binsearch result
    EXPECT_EQ(dut.readRegfile(S4),   0);        // Testing invalid binsearch result
    EXPECT_EQ(dut.readRegfile(doneReg), -1);    // Make sure we did not time-out in simulation
}