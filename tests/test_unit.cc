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

// Units
#include "VALU.h"
#include "VALU__Syms.h"
#include "VRegfile.h"
#include "VRegfile__Syms.h"
#include "VDualPortRam.h"
#include "VDualPortRam__Syms.h"
#include "VImmGen.h"
#include "VImmGen__Syms.h"
#include "VControlUnit.h"
#include "VControlUnit__Syms.h"

#include "utils.hh"
#include "types.hh"

// ====================================================================================================================
TEST(unit, alu) {
    std::unique_ptr<VALU> dut(new VALU);
    auto p_alu = dut.get();

    double TEST_OP_RANGE        = 1 << 5; // 2**5
    double TEST_RANGE           = 1 << 8; // 2**8

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
                case ALU_OP_PASSB : r = p_alu->i_b;                                         break;
                case ALU_OP_ADD4A : r = p_alu->i_a + 4;                                     break;
                case ALU_OP_XOR   : r = p_alu->i_a ^ p_alu->i_b;                            break;
                case ALU_OP_SRL   : r = p_alu->i_a >> p_alu->i_b;                           break;
                case ALU_OP_SRA   : r = static_cast<signed int>(p_alu->i_a) >> p_alu->i_b;  break;
                case ALU_OP_OR    : r = p_alu->i_a | p_alu->i_b;                            break;
                case ALU_OP_AND   : r = p_alu->i_a & p_alu->i_b;                            break;
                case ALU_OP_SUB   : r = p_alu->i_a - p_alu->i_b;                            break;
                case ALU_OP_SLL   : r = p_alu->i_a << p_alu->i_b;                           break;
                case ALU_OP_EQ    : r = p_alu->i_a == p_alu->i_b;                           break;
                case ALU_OP_NEQ   : r = p_alu->i_a != p_alu->i_b;                           break;
                case ALU_OP_SLT   : r = static_cast<signed int>(p_alu->i_a) <
                                        static_cast<signed int>(p_alu->i_b);                break;
                case ALU_OP_SLTU  : r = p_alu->i_a < p_alu->i_b;                            break;
                case ALU_OP_SGTE  : r = static_cast<signed int>(p_alu->i_a) >=
                                        static_cast<signed int>(p_alu->i_b);                break;
                case ALU_OP_SGTEU : r = p_alu->i_a >= p_alu->i_b;                           break;
                case ALU_OP_ADD   :
                default           : r = p_alu->i_a + p_alu->i_b;
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
// ====================================================================================================================
TEST(unit, ctrl_unit) {
    std::unique_ptr<VControlUnit> dut(new VControlUnit);
    auto p_ctrl = dut.get();
    constexpr int TEST_COUNT = 1 << 7; // 2**7
    uint INVALID        = p_ctrl->ControlUnit->INVALID_CTRL;
    uint SYSTEM_CTRL    = p_ctrl->ControlUnit->SYSTEM_CTRL;
    uint FENCE_CTRL     = p_ctrl->ControlUnit->FENCE_CTRL;

    for (int i=0; i<TEST_COUNT; ++i) {
        uint cm_addr    = i;
        uint ctrl_sigs  = 0;
        switch (get_bits(cm_addr, 0, 5)) {
            case OP:        ctrl_sigs = p_ctrl->ControlUnit->R_CTRL;                                break;
            case JALR:      ctrl_sigs = p_ctrl->ControlUnit->I_JUMP_CTRL;                           break;
            case LOAD:      ctrl_sigs = p_ctrl->ControlUnit->I_LOAD_CTRL;                           break;
            case OP_IMM:    ctrl_sigs = p_ctrl->ControlUnit->I_ARITH_CTRL;                          break;
            case STORE:     ctrl_sigs = p_ctrl->ControlUnit->S_CTRL;                                break;
            case BRANCH:    ctrl_sigs = p_ctrl->ControlUnit->B_CTRL;                                break;
            case LUI:       ctrl_sigs = p_ctrl->ControlUnit->LUI_CTRL;                              break;
            case AUIPC:     ctrl_sigs = p_ctrl->ControlUnit->AUIPC_CTRL;                            break;
            case JAL:       ctrl_sigs = p_ctrl->ControlUnit->J_CTRL;                                break;
            case SYSTEM:    ctrl_sigs = get_bits(cm_addr, 6, 3) == 0b000 ? SYSTEM_CTRL : INVALID;   break;
            case MISC_MEM:  ctrl_sigs = get_bits(cm_addr, 6, 3) == 0b000 ? FENCE_CTRL  : INVALID;   break;
            default:        ctrl_sigs = p_ctrl->ControlUnit->INVALID_CTRL;
        }
        p_ctrl->i_opcode = get_bits(i, 0, 5);
        p_ctrl->i_funct3 = get_bits(i, 6, 3);
        p_ctrl->eval();

        // TODO: Also test ALU exec fields
        uint core_ctl = get_bits(p_ctrl->o_ctrlSigs, 0, 7);
        EXPECT_EQ(core_ctl, ctrl_sigs);
    }
}
