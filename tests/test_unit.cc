// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <cmath>
#include <cstdio>
#include <string>
#include <vector>
#include <iostream>
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VALU.h"
#include "VALU__Syms.h"
#include "VRegfile.h"
#include "VRegfile__Syms.h"
#include "VDualPortRam.h"
#include "VDualPortRam__Syms.h"

#include "utils.hh"

// ====================================================================================================================
TEST(unit, alu) {
    std::unique_ptr<VALU> dut(new VALU);
    auto p_alu = dut.get();

    double TEST_OP_RANGE            = std::pow(2, 5);
    double TEST_RANGE               = std::pow(2, 8);
    // TODO: Can we grab these values from RTL defines?
    constexpr int ALU_EXEC_ADD      = 0b00000;
    constexpr int ALU_EXEC_PASSB    = 0b00001;
    constexpr int ALU_EXEC_ADD4A    = 0b00010;
    constexpr int ALU_EXEC_XOR      = 0b00011;
    constexpr int ALU_EXEC_SRL      = 0b00100;
    constexpr int ALU_EXEC_SRA      = 0b00101;
    constexpr int ALU_EXEC_OR       = 0b00110;
    constexpr int ALU_EXEC_AND      = 0b00111;
    constexpr int ALU_EXEC_SUB      = 0b01000;
    constexpr int ALU_EXEC_SLL      = 0b01001;
    constexpr int ALU_EXEC_EQ       = 0b01010;
    constexpr int ALU_EXEC_NEQ      = 0b01011;
    constexpr int ALU_EXEC_SLT      = 0b01100;
    constexpr int ALU_EXEC_SLTU     = 0b01101;
    constexpr int ALU_EXEC_SGTE     = 0b01110;
    constexpr int ALU_EXEC_SGTEU    = 0b01111;

    for (int i=0; i<TEST_OP_RANGE; ++i) {
        p_alu->i_op = i;
        for (int j=0; j<TEST_RANGE; ++j) {
            int r = 0;
            unsigned char x = static_cast<unsigned char>(j);
            unsigned char y = rev_byte_bits(x);
            p_alu->i_a = (x << 24) | (x << 16) | (x << 8) | x;
            p_alu->i_b = (y << 24) | (y << 16) | (y << 8) | y;
            dut.get()->eval();
            switch (p_alu->i_op) {
                case ALU_EXEC_PASSB : r = p_alu->i_b;                                           break;
                case ALU_EXEC_ADD4A : r = p_alu->i_a + 4;                                       break;
                case ALU_EXEC_XOR   : r = p_alu->i_a ^ p_alu->i_b;                              break;
                case ALU_EXEC_SRL   : r = p_alu->i_a >> p_alu->i_b;                             break;
                case ALU_EXEC_SRA   : r = static_cast<signed int>(p_alu->i_a) >> p_alu->i_b;    break;
                case ALU_EXEC_OR    : r = p_alu->i_a | p_alu->i_b;                              break;
                case ALU_EXEC_AND   : r = p_alu->i_a & p_alu->i_b;                              break;
                case ALU_EXEC_SUB   : r = p_alu->i_a - p_alu->i_b;                              break;
                case ALU_EXEC_SLL   : r = p_alu->i_a << p_alu->i_b;                             break;
                case ALU_EXEC_EQ    : r = p_alu->i_a == p_alu->i_b;                             break;
                case ALU_EXEC_NEQ   : r = p_alu->i_a != p_alu->i_b;                             break;
                case ALU_EXEC_SLT   : r = static_cast<signed int>(p_alu->i_a) <
                                          static_cast<signed int>(p_alu->i_b);                  break;
                case ALU_EXEC_SLTU  : r = p_alu->i_a < p_alu->i_b;                              break;
                case ALU_EXEC_SGTE  : r = static_cast<signed int>(p_alu->i_a) >=
                                          static_cast<signed int>(p_alu->i_b);                  break;
                case ALU_EXEC_SGTEU : r = p_alu->i_a >= p_alu->i_b;                             break;
                case ALU_EXEC_ADD   :
                default             : r = p_alu->i_a + p_alu->i_b;
            }
            EXPECT_EQ(r, p_alu->o_result) << "ALU operation was: " << i;
        }
    }
}
// ====================================================================================================================
TEST(unit, regfile) {
    std::unique_ptr<VRegfile> dut(new VRegfile);
    auto p_regfile = dut.get();
    constexpr int TEST_DATA_SIZE = 10;
    uint test_data[TEST_DATA_SIZE] = {
        0xdeadbeef,
        0x8badf00d,
        0x00c0ffee,
        0xdeadc0de,
        0xbadf000d,
        0xdefac8ed,
        0xcafebabe,
        0xdeadd00d,
        0xcafed00d,
        0xdeadbabe
    };
    auto tick = [](VRegfile* regfile, int tick_count=1) {
        for (int i=0; i<tick_count; ++i) {
            regfile->i_clk = 0;
            regfile->eval();
            regfile->i_clk = 1;
            regfile->eval();
        }
    };
    p_regfile->i_wrEn = 1;
    for (int i=0; i<TEST_DATA_SIZE; ++i) {
        p_regfile->i_rdAddr = i;
        p_regfile->i_rdData = test_data[i];
        tick(p_regfile);
    }
    p_regfile->i_wrEn = 0;
    for (int i=0; i<TEST_DATA_SIZE; i++) {
        p_regfile->i_rs1Addr = i;
        p_regfile->i_rs2Addr = i;
        tick(p_regfile);
        EXPECT_EQ(p_regfile->o_rs1Data, test_data[i]);
        EXPECT_EQ(p_regfile->o_rs2Data, test_data[i]);
    }
    tick(p_regfile);
    p_regfile->i_wrEn = 1;
    p_regfile->i_rdAddr = 5;
    p_regfile->i_rdData = 0xffffffff;
    p_regfile->i_rs1Addr = 5;
    p_regfile->i_rs2Addr = 5;
    tick(p_regfile);
    EXPECT_EQ(p_regfile->o_rs1Data, 0xffffffff);
    EXPECT_EQ(p_regfile->o_rs2Data, 0xffffffff);
}
// ====================================================================================================================
TEST(unit, dualportram) {
    std::unique_ptr<VDualPortRam> dut(new VDualPortRam);
    auto p_dpr = dut.get();
    constexpr int TEST_DATA_SIZE = 10;
    uint test_data[TEST_DATA_SIZE] = {
        0xdeadbeef,
        0x8badf00d,
        0x00c0ffee,
        0xdeadc0de,
        0xbadf000d,
        0xdefac8ed,
        0xcafebabe,
        0xdeadd00d,
        0xcafed00d,
        0xdeadbabe
    };
    auto tick = [](VDualPortRam* dpr, int tick_count=1) {
        for (int i=0; i<tick_count; ++i) {
            dpr->i_clk = 0;
            dpr->eval();
            dpr->i_clk = 1;
            dpr->eval();
        }
    };
    p_dpr->i_we = 1;
    for (int i=0; i<TEST_DATA_SIZE; ++i) {
        p_dpr->i_wAddr = i;
        p_dpr->i_dataIn = test_data[i];
        tick(p_dpr);
    }
    p_dpr->i_we = 0;
    for (int i=0; i<TEST_DATA_SIZE; ++i) {
        p_dpr->i_rAddr = i;
        tick(p_dpr);
        EXPECT_EQ(p_dpr->o_q, test_data[i]);
    }
}
