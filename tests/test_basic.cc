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
#include "functions.inc"
} // namespace

extern int g_testTracing;

TEST(basic, functions) {
    constexpr int memSize = 0x80000;
    flintRV dut = flintRV(1000000, g_testTracing);
    if (!dut.create(new VflintRV(), nullptr)) {
        FAIL();
    }
    if (!dut.createMemory(memSize, functions_hex, functions_hex_len)) {
        FAIL();
    }

    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory
    // Init stack and frame pointers
    dut.writeRegfile(SP, memSize - 1);
    dut.writeRegfile(FP, memSize - 1);

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

    EXPECT_EQ(dut.readRegfile(S1), 6);
    EXPECT_EQ(dut.readRegfile(S2), 720);
    EXPECT_EQ(dut.readRegfile(S3), 362880);
    EXPECT_EQ(dut.readRegfile(S4), 15);
    EXPECT_EQ(dut.readRegfile(S5), 1);
    EXPECT_EQ(dut.readRegfile(S6), 1);
    EXPECT_EQ(dut.readRegfile(S7), 0);
}
