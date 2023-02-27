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
#include "VImmGen.h"
#include "VImmGen__Syms.h"

#include "utils.hh"

// ====================================================================================================================
TEST(unit, alu) {
    std::unique_ptr<VALU> dut(new VALU);
    auto p_alu = dut.get();

    double TEST_OP_RANGE        = 1 << 5; // 2**5
    double TEST_RANGE           = 1 << 8; // 2**8
    const uint ALU_EXEC_OR      = p_alu->ALU->get_ALU_EXEC_OR();
    const uint ALU_EXEC_EQ      = p_alu->ALU->get_ALU_EXEC_EQ();
    const uint ALU_EXEC_XOR     = p_alu->ALU->get_ALU_EXEC_XOR();
    const uint ALU_EXEC_SRL     = p_alu->ALU->get_ALU_EXEC_SRL();
    const uint ALU_EXEC_SRA     = p_alu->ALU->get_ALU_EXEC_SRA();
    const uint ALU_EXEC_AND     = p_alu->ALU->get_ALU_EXEC_AND();
    const uint ALU_EXEC_SUB     = p_alu->ALU->get_ALU_EXEC_SUB();
    const uint ALU_EXEC_SLL     = p_alu->ALU->get_ALU_EXEC_SLL();
    const uint ALU_EXEC_NEQ     = p_alu->ALU->get_ALU_EXEC_NEQ();
    const uint ALU_EXEC_SLT     = p_alu->ALU->get_ALU_EXEC_SLT();
    const uint ALU_EXEC_SLTU    = p_alu->ALU->get_ALU_EXEC_SLTU();
    const uint ALU_EXEC_SGTE    = p_alu->ALU->get_ALU_EXEC_SGTE();
    const uint ALU_EXEC_PASSB   = p_alu->ALU->get_ALU_EXEC_PASSB();
    const uint ALU_EXEC_ADD4A   = p_alu->ALU->get_ALU_EXEC_ADD4A();
    const uint ALU_EXEC_SGTEU   = p_alu->ALU->get_ALU_EXEC_SGTEU();

    for (int i=0; i<TEST_OP_RANGE; ++i) {
        p_alu->i_op = i;
        for (int j=0; j<TEST_RANGE; ++j) {
            int r = 0;
            unsigned char x = static_cast<unsigned char>(j);
            unsigned char y = rev_byte_bits(x);
            p_alu->i_a = (x << 24) | (x << 16) | (x << 8) | x;
            p_alu->i_b = (y << 24) | (y << 16) | (y << 8) | y;
            dut.get()->eval();
            if      (p_alu->i_op == ALU_EXEC_PASSB) { r = p_alu->i_b;                                           }
            else if (p_alu->i_op == ALU_EXEC_ADD4A) { r = p_alu->i_a + 4;                                       }
            else if (p_alu->i_op == ALU_EXEC_XOR  ) { r = p_alu->i_a ^ p_alu->i_b;                              }
            else if (p_alu->i_op == ALU_EXEC_SRL  ) { r = p_alu->i_a >> p_alu->i_b;                             }
            else if (p_alu->i_op == ALU_EXEC_SRA  ) { r = static_cast<signed int>(p_alu->i_a) >> p_alu->i_b;    }
            else if (p_alu->i_op == ALU_EXEC_OR   ) { r = p_alu->i_a | p_alu->i_b;                              }
            else if (p_alu->i_op == ALU_EXEC_AND  ) { r = p_alu->i_a & p_alu->i_b;                              }
            else if (p_alu->i_op == ALU_EXEC_SUB  ) { r = p_alu->i_a - p_alu->i_b;                              }
            else if (p_alu->i_op == ALU_EXEC_SLL  ) { r = p_alu->i_a << p_alu->i_b;                             }
            else if (p_alu->i_op == ALU_EXEC_EQ   ) { r = p_alu->i_a == p_alu->i_b;                             }
            else if (p_alu->i_op == ALU_EXEC_NEQ  ) { r = p_alu->i_a != p_alu->i_b;                             }
            else if (p_alu->i_op == ALU_EXEC_SLT  ) {
                r = static_cast<signed int>(p_alu->i_a) < static_cast<signed int>(p_alu->i_b);
            }
            else if (p_alu->i_op == ALU_EXEC_SLTU ) { r = p_alu->i_a < p_alu->i_b;                              }
            else if (p_alu->i_op == ALU_EXEC_SGTE ) {
                r = static_cast<signed int>(p_alu->i_a) >= static_cast<signed int>(p_alu->i_b);                 }
            else if (p_alu->i_op == ALU_EXEC_SGTEU) { r = p_alu->i_a >= p_alu->i_b;                             }
            else                                    { r = p_alu->i_a + p_alu->i_b; /* Default == ADD */         }
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
// ====================================================================================================================
TEST(unit, immgen) {
    std::unique_ptr<VImmGen> dut(new VImmGen);
    auto p_immgen = dut.get();
    constexpr int UJ_TEST_COUNT     = 1 << 20; // 2**20
    constexpr int SBI_TEST_COUNT    = 1 << 12; // 2**12
    // U-type
    for (int i = 0; i < UJ_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 0, 20) << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= U_LUI;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, U_IMM(x));
    }
    for (int i = 0; i < UJ_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 0, 20) << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= U_AUIPC;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, U_IMM(x));
    }
    // J-type
    for (int i = 0; i < UJ_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 19, 1) << 31;
        x |= get_bits(i, 0, 9)  << 21;
        x |= get_bits(i, 10, 1) << 20;
        x |= get_bits(i, 11, 8) << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= J;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, J_IMM(x));
    }
    // S-type
    for (int i = 0; i < SBI_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 19, 1) << 31;
        x |= get_bits(i, 0, 9)  << 21;
        x |= get_bits(i, 10, 1) << 20;
        x |= get_bits(i, 11, 8) << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= S;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, S_IMM(x));
    }
    // B-type
    for (int i = 0; i < SBI_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 12, 1) << 31;
        x |= get_bits(i, 5, 6)  << 25;
        x |= get_bits(i, 0, 5)  << 20;
        x |= get_bits(i, 0, 5)  << 15;
        x |= get_bits(i, 0, 3)  << 12;
        x |= get_bits(i, 1, 4)  << 8;
        x |= get_bits(i, 11, 1) << 7;
        x |= B;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, B_IMM(x));
    }
    // I-type (Skip R, Fence, and System types)
    for (int i = 0; i < SBI_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 0, 12) << 20;
        x |= get_bits(i, 0, 5)  << 15;
        x |= get_bits(i, 0, 3)  << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= I_JUMP;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, I_IMM(x));
    }
    for (int i = 0; i < SBI_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 0, 12) << 20;
        x |= get_bits(i, 0, 5)  << 15;
        x |= get_bits(i, 0, 3)  << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= I_LOAD;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, I_IMM(x));
    }
    for (int i = 0; i < SBI_TEST_COUNT; ++i) {
        int x = 0;
        x |= get_bits(i, 0, 12) << 20;
        x |= get_bits(i, 0, 5)  << 15;
        x |= get_bits(i, 0, 3)  << 12;
        x |= get_bits(i, 0, 5)  << 7;
        x |= I_ARITH;
        p_immgen->i_instr = x;
        p_immgen->eval();
        EXPECT_EQ(p_immgen->o_imm, I_IMM(x));
    }
}