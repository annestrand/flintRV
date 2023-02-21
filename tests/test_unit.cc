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
#include "common.hh"

#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER
/*
    NOTE:   Verilator changes its internal-module interface scheme from v4.210 and up (i.e. rootp).
            Making utility wrapper here to easily handle and access module internals.
            (As well as keep track of any future-version interface changes)
*/
#if VERILATOR_VER >= 4210
#define DUT(sim) (sim).get()->rootp
#else
#define DUT(sim) (sim).get()
#endif

namespace
{
auto rev_byte_bits = [](unsigned char x) -> unsigned char {
    unsigned char y = 0;
    y |= (x & 0x01) << 7;
    y |= (x & 0x02) << 5;
    y |= (x & 0x04) << 3;
    y |= (x & 0x08) << 1;
    y |= (x & 0x10) >> 1;
    y |= (x & 0x20) >> 3;
    y |= (x & 0x40) >> 5;
    y |= (x & 0x80) >> 7;
    return y;
};
}

// ====================================================================================================================
TEST(unit, alu) { // ALU testing
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