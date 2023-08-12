// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <cmath>
#include <cstdio>
#include <string>
#include <vector>
#include <iostream>

#include <cstdint>

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

#if VERILATOR_VER >= 4210
#define UNIT(sim) (sim)->rootp
#else
#define UNIT(sim) (sim)
#endif

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
    uint32_t test_data[TEST_DATA_SIZE] = {
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
    uint32_t test_data[TEST_DATA_SIZE] = {
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
TEST(unit, ctrl_unit_rv32i) {
    std::unique_ptr<VControlUnit> dut(new VControlUnit);
    auto p_ctrl = dut.get();
    auto CTRL = UNIT(p_ctrl)->ControlUnit;
    constexpr int TEST_COUNT = 1 << 8; // 2**8

    for (int instr=0; instr<TEST_COUNT; ++instr) {
        p_ctrl->i_opcode = get_bits(instr, 0, 5);
        p_ctrl->i_funct3 = get_bits(instr, 6, 3);
        p_ctrl->i_funct7 = get_bits(instr, 17, 7);
        // Select instr op table
        uint32_t ctl_gold = 0;
        uint32_t tbl_addr = 0;
        if (p_ctrl->i_opcode == OP_MAP_OP) { // R Type
            tbl_addr = p_ctrl->i_funct3;
            switch(tbl_addr) {
                case 0b000:
                    if (p_ctrl->i_funct7 == 0b0100000) {
                        ctl_gold = CTRL->SUB;
                    } else {
                        ctl_gold = CTRL->ADD;
                    }
                    break;
                case 0b001: ctl_gold = CTRL->SLL; break;
                case 0b010: ctl_gold = CTRL->SLT; break;
                case 0b011: ctl_gold = CTRL->SLTU; break;
                case 0b100: ctl_gold = CTRL->XOR; break;
                case 0b101:
                    if (p_ctrl->i_funct7 == 0b0100000) {
                        ctl_gold = CTRL->SRA;
                    }  else {
                        ctl_gold = CTRL->SRL;
                    }
                    break;
                case 0b110: ctl_gold = CTRL->OR; break;
                case 0b111: ctl_gold = CTRL->AND; break;
                default:    ctl_gold = CTRL->INVALID; break;
            }
        } else { // I,J,U,B Type
            tbl_addr = p_ctrl->i_funct3 << 5 | p_ctrl->i_opcode;
            switch (p_ctrl->i_opcode) {
                case OP_MAP_LOAD: switch (p_ctrl->i_funct3) {
                    case 0b000: ctl_gold = CTRL->LB; break;
                    case 0b001: ctl_gold = CTRL->LH; break;
                    case 0b010: ctl_gold = CTRL->LW; break;
                    case 0b100: ctl_gold = CTRL->LBU; break;
                    case 0b101: ctl_gold = CTRL->LHU; break;
                    default:    ctl_gold = CTRL->INVALID; break;
                } break;
                case OP_MAP_STORE: switch (p_ctrl->i_funct3) {
                    case 0b000: ctl_gold = CTRL->SB; break;
                    case 0b001: ctl_gold = CTRL->SH; break;
                    case 0b010: ctl_gold = CTRL->SW; break;
                    default:    ctl_gold = CTRL->INVALID; break;
                } break;
                case OP_MAP_BRANCH: switch (p_ctrl->i_funct3) {
                    case 0b000: ctl_gold = CTRL->BEQ; break;
                    case 0b001: ctl_gold = CTRL->BNE; break;
                    case 0b100: ctl_gold = CTRL->BLT; break;
                    case 0b101: ctl_gold = CTRL->BGE; break;
                    case 0b110: ctl_gold = CTRL->BLTU; break;
                    case 0b111: ctl_gold = CTRL->BGEU; break;
                    default:    ctl_gold = CTRL->INVALID; break;
                } break;
                case OP_MAP_OP_IMM: switch (p_ctrl->i_funct3) {
                    case 0b000: ctl_gold = CTRL->ADDI; break;
                    case 0b010: ctl_gold = CTRL->SLTI; break;
                    case 0b011: ctl_gold = CTRL->SLTIU; break;
                    case 0b100: ctl_gold = CTRL->XORI; break;
                    case 0b110: ctl_gold = CTRL->ORI; break;
                    case 0b111: ctl_gold = CTRL->ANDI; break;
                    case 0b001: ctl_gold = CTRL->SLLI; break;
                    case 0b101:
                        if (p_ctrl->i_funct7 == 0b0100000) {
                            ctl_gold = CTRL->SRAI;
                        } else {
                            ctl_gold = CTRL->SRLI;
                        }
                        break;
                    default:    ctl_gold = CTRL->INVALID; break;
                } break;
                case OP_MAP_SYSTEM:
                    if (p_ctrl->i_funct3 == 0b000) {
                        ctl_gold = CTRL->ECALL;
                    } else {
                        ctl_gold = CTRL->INVALID;
                    }
                    break;
                case OP_MAP_MISC_MEM:
                    if (p_ctrl->i_funct3 == 0b000) {
                        ctl_gold = CTRL->FENCE;
                    } else {
                        ctl_gold = CTRL->INVALID;
                    }
                    break;
                case OP_MAP_LUI:      ctl_gold = CTRL->LUI; break;
                case OP_MAP_AUIPC:    ctl_gold = CTRL->AUIPC; break;
                case OP_MAP_JAL:      ctl_gold = CTRL->JAL; break;
                case OP_MAP_JALR:     ctl_gold = CTRL->JALR; break;
                default:              ctl_gold = CTRL->INVALID; break;
            }
        }
        p_ctrl->eval();
        EXPECT_EQ(p_ctrl->o_ctrlSigs, ctl_gold);
    }
}
