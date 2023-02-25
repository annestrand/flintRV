// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#pragma once

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#ifndef VERILATOR_VER
#define VERILATOR_VER 4028
#endif // VERILATOR_VER

#define HEX_DECODE_ASCII(in) strtol(in, NULL, 16)
#define INT_DECODE_ASCII(in) strtol(in, NULL, 10)

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define LOG_I(msg, ...) \
    printf("[Vdrop32 - Info ]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_W(msg, ...) \
    printf("[Vdrop32 - WARN ]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_E(msg, ...) \
    printf("[Vdrop32 - ERROR]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)

namespace
{
auto get_bits = [](unsigned int instr, int pos, int width) {
    return ((instr & ((((1 << width) - 1) << pos))) >> pos);
};
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

// Get RV32I value(s) from instruction (x)
#define OPCODE(x)       get_bits(x, 0, 7)
#define RD(x)           get_bits(x, 7, 5)
#define RS1(x)          get_bits(x, 15, 5)
#define RS2(x)          get_bits(x, 20, 5)
#define FUNCT3(x)       get_bits(x, 12, 3)
#define FUNCT7(x)       get_bits(x, 25, 7)
#define IMM_10_5(x)     get_bits(x, 25, 6)
#define IMM_11_B(x)     get_bits(x, 7, 1)
#define IMM_4_1(x)      get_bits(x, 8, 4)
#define IMM_4_0(x)      get_bits(x, 7, 5)
#define IMM_11_5(x)     get_bits(x, 25, 7)
#define IMM_12(x)       get_bits(x, 31, 1)
#define IMM_20(x)       get_bits(x, 31, 1)
#define IMM_11_0(x)     get_bits(x, 20, 12)
#define IMM_11_J(x)     get_bits(x, 20, 1)
#define IMM_19_12(x)    get_bits(x, 12, 8)
#define IMM_10_1(x)     get_bits(x, 21, 10)
#define IMM_31_12(x)    get_bits(x, 12, 20)
#define SUCC(x)         get_bits(x, 20, 4)
#define PRED(x)         get_bits(x, 24, 4)
#define FM(x)           get_bits(x, 28, 4)

// Get immediate value from instruction (x)
#define I_IMM(x)        (((int)IMM_11_0(x) << 20) >> 20)
#define S_IMM(x)        (((int)(IMM_4_0(x) | IMM_11_5(x) << 5) << 20) >> 20)
#define B_IMM(x)        (int)((IMM_4_1(x) | IMM_10_5(x) << 4 | IMM_11_B(x) << 10 | IMM_12(x) << 11) << 20) >> 19
#define U_IMM(x)        IMM_31_12(x) << 12
#define J_IMM(x)        (int)((IMM_10_1(x) | IMM_11_J(x) << 10 | IMM_19_12(x) << 11 | IMM_20(x) << 19) << 12) >> 11
#define I_FENCE_IMM(x)  S_IMM(x)

// RV32I types
enum {
    R       = 0b0110011,
    I_JUMP  = 0b1100111,
    I_LOAD  = 0b0000011,
    I_ARITH = 0b0010011,
    I_SYS   = 0b1110011,
    I_FENCE = 0b0001111,
    S       = 0b0100011,
    B       = 0b1100011,
    U_LUI   = 0b0110111,
    U_AUIPC = 0b0010111,
    J       = 0b1101111
};
// RV32I instructions
enum {
    EBREAK  = (0x1  << 20) | (0x0 << 7) | (0x73),
    SUB     = (0x20 << 10) | (0x0 << 7) | (0x33),
    SRA     = (0x20 << 10) | (0x5 << 7) | (0x33),
    SRAI    = (0x20 << 10) | (0x5 << 7) | (0x13),
    ADD     = (0x0  << 10) | (0x0 << 7) | (0x33),
    SLL     = (0x0  << 10) | (0x1 << 7) | (0x33),
    SLT     = (0x0  << 10) | (0x2 << 7) | (0x33),
    SLTU    = (0x0  << 10) | (0x3 << 7) | (0x33),
    XOR     = (0x0  << 10) | (0x4 << 7) | (0x33),
    SRL     = (0x0  << 10) | (0x5 << 7) | (0x33),
    OR      = (0x0  << 10) | (0x6 << 7) | (0x33),
    AND     = (0x0  << 10) | (0x7 << 7) | (0x33),
    SLLI    = (0x0  << 10) | (0x1 << 7) | (0x13),
    SRLI    = (0x0  << 10) | (0x5 << 7) | (0x13),
    ECALL   =                (0x0 << 7) | (0x73),
    JALR    =                (0x0 << 7) | (0x67),
    BGEU    =                (0x7 << 7) | (0x63),
    BLTU    =                (0x6 << 7) | (0x63),
    BGE     =                (0x5 << 7) | (0x63),
    BLT     =                (0x4 << 7) | (0x63),
    BNE     =                (0x1 << 7) | (0x63),
    BEQ     =                (0x0 << 7) | (0x63),
    SW      =                (0x2 << 7) | (0x23),
    SH      =                (0x1 << 7) | (0x23),
    SB      =                (0x0 << 7) | (0x23),
    ANDI    =                (0x7 << 7) | (0x13),
    ORI     =                (0x6 << 7) | (0x13),
    XORI    =                (0x4 << 7) | (0x13),
    SLTIU   =                (0x3 << 7) | (0x13),
    SLTI    =                (0x2 << 7) | (0x13),
    ADDI    =                (0x0 << 7) | (0x13),
    FENCE   =                (0x0 << 7) | (0x0f),
    LHU     =                (0x5 << 7) | (0x03),
    LBU     =                (0x4 << 7) | (0x03),
    LW      =                (0x2 << 7) | (0x03),
    LH      =                (0x1 << 7) | (0x03),
    LB      =                (0x0 << 7) | (0x03),
    JAL     =                             (0x6f),
    LUI     =                             (0x37),
    AUIPC   =                             (0x17)
};

std::string disassembleRv32i(unsigned int instr);
bool loadMem(std::string filePath, char* mem, ssize_t memLen);
