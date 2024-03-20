// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <cstdio>
#include <fstream>
#include <gtest/gtest.h>
#include <iostream>
#include <string>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vdrop32.h"
#include "Vdrop32__Syms.h"

#include "common/utils.h"

#include "Vdrop32/drop32.h"

namespace {
// Embed the test programs binaries here
#include "add.inc"
#include "addi.inc"
#include "and.inc"
#include "andi.inc"
#include "auipc.inc"
#include "beq.inc"
#include "bge.inc"
#include "bgeu.inc"
#include "blt.inc"
#include "bltu.inc"
#include "bne.inc"
#include "j.inc"
#include "jal.inc"
#include "jalr.inc"
#include "lb.inc"
#include "lbu.inc"
#include "lh.inc"
#include "lhu.inc"
#include "lui.inc"
#include "lw.inc"
#include "or.inc"
#include "ori.inc"
#include "sb.inc"
#include "sh.inc"
#include "simple.inc"
#include "sll.inc"
#include "slli.inc"
#include "slt.inc"
#include "slti.inc"
#include "sra.inc"
#include "srai.inc"
#include "srl.inc"
#include "srli.inc"
#include "sub.inc"
#include "sw.inc"
#include "xor.inc"
#include "xori.inc"
} // namespace

extern int g_testTracing;

#define FUNCTIONAL_TEST(name, memsize, timeout, dumplvl)                       \
    TEST(functional, name) {                                                   \
        constexpr int memSize = memsize;                                       \
        drop32 dut = drop32(timeout, dumplvl);                                 \
        if (!dut.create(new Vdrop32(), nullptr)) {                             \
            FAIL();                                                            \
        }                                                                      \
        if (!dut.createMemory(memSize, name##_hex, name##_hex_len)) {          \
            FAIL();                                                            \
        }                                                                      \
        dut.m_cpu->i_ifValid = 1;                                              \
        dut.m_cpu->i_memValid = 1;                                             \
        dut.writeRegfile(SP, memSize - 1);                                     \
        dut.writeRegfile(FP, memSize - 1);                                     \
        while (!dut.end()) {                                                   \
            if (!dut.instructionUpdate()) {                                    \
                FAIL();                                                        \
            }                                                                  \
            if (!dut.loadStoreUpdate()) {                                      \
                FAIL();                                                        \
            }                                                                  \
            dut.tick();                                                        \
        }                                                                      \
        char resultStr[4] = {0};                                               \
        resultStr[0] = (char)dut.readRegfile(A1);                              \
        resultStr[1] = (char)dut.readRegfile(A2);                              \
        resultStr[2] = (char)dut.readRegfile(A3);                              \
        EXPECT_EQ(std::strcmp(resultStr, "OK"), 0)                             \
            << "resultStr: \"" << resultStr << "\"";                           \
    }

// FUNCTIONAL_TEST(name, memsize, timeout, dumplvl)

FUNCTIONAL_TEST(add, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(addi, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(and, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(andi, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(auipc, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(beq, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(bge, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(bgeu, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(blt, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(bltu, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(bne, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(j, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(jal, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(jalr, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lb, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lbu, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lh, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lhu, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lui, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(lw, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(or, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(ori, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sb, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sh, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(simple, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sll, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(slli, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(slt, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(slti, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sra, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(srai, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(srl, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(srli, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sub, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(sw, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(xor, 0x4000, 1000, g_testTracing)
FUNCTIONAL_TEST(xori, 0x4000, 1000, g_testTracing)
