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
    if (!dut.create(new Vboredcore(), "obj_dir/fibonacci.vcd"))     { FAIL(); }
    if (!dut.registerMemory(0x2000, BASE_PATH "/fibonacci.mem"))    { FAIL(); }

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
}