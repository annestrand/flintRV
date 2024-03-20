// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#pragma once

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <string>
#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#ifdef _WIN32
#define LOAD_LIB(libpath) LoadLibrary(libpath)
#define CLOSE_LIB(handle) FreeLibrary(handle)
#define LOAD_SYM(handle, fname) GetProcAddress(handle, fname)
#define LIB_HANDLE HINSTANCE
#define OPEN_FILE(fp, filename, mode)                                          \
    do {                                                                       \
        if ((fopen_s(&fp, filename, mode)) != 0) {                             \
            fp = NULL;                                                         \
        }                                                                      \
    } while (0)
#define EXPORT __declspec(dllexport)
#define SIGINT_RET_TYPE BOOL WINAPI
#define SIGINT_PARAM DWORD
#define SIGINT_RET return TRUE
#define SIGINT_REGISTER(cpu, function)                                         \
    do {                                                                       \
        if (!SetConsoleCtrlHandler((PHANDLER_ROUTINE)function, TRUE)) {        \
            LOG_ERROR("Error. Couldn't register sigint handler.");             \
            cleanupSimulator(cpu);                                             \
            return ECANCELED;                                                  \
        }                                                                      \
    } while (0)
#else
#define LOAD_LIB(libpath) dlopen(libpath, RTLD_LAZY)
#define CLOSE_LIB(handle) dlclose(handle)
#define LOAD_SYM(handle, fname) dlsym(handle, fname)
#define LIB_HANDLE void *
#define OPEN_FILE(fp, filename, mode)                                          \
    do {                                                                       \
        fp = fopen(filename, mode);                                            \
    } while (0)
#define EXPORT __attribute__((visibility("default")))
#define SIGINT_RET_TYPE void
#define SIGINT_PARAM int
#define SIGINT_RET                                                             \
    do {                                                                       \
    } while (0)
#define SIGINT_REGISTER(cpu, function)                                         \
    do {                                                                       \
        if ((signal(SIGINT, function) == SIG_ERR)) {                           \
            LOG_ERROR("Couldn't register sigint handler.");                    \
            cleanupSimulator(cpu);                                             \
            return ECANCELED;                                                  \
        }                                                                      \
    } while (0)
#endif

#define LOG_LINE_BREAK                                                         \
    "========================================================================" \
    "=="                                                                       \
    "======================================\n"

#define OUTPUT_LINE                                                            \
    "===[ OUTPUT "                                                             \
    "]=======================================================================" \
    "=="                                                                       \
    "==========================\n"

// Prefer shortened __FILE__ expansion if available
#if defined(__FILE_NAME__)
#define FILENAME __FILE_NAME__
#else
#define FILENAME __FILE__
#endif

#define STRINGIFY_INTERNAL(x) #x
#define STRINGIFY(x) STRINGIFY_INTERNAL(x)

#define LINE STRINGIFY(__LINE__)

// Log/trace macros
#define LOG_INFO(msg) printf("[INFO][" FILENAME ":" LINE "]: " msg "\n")
#define LOG_WARNING(msg) printf("[WARN][" FILENAME ":" LINE "]: " msg "\n")
#define LOG_ERROR(msg) printf("[ERR ][" FILENAME ":" LINE "]: " msg "\n")
#define LOG_INFO_PRINTF(fmt, ...)                                              \
    printf("[INFO][" FILENAME ":" LINE "]: " fmt "\n", ##__VA_ARGS__)
#define LOG_WARNING_PRINTF(fmt, ...)                                           \
    printf("[WARN][" FILENAME ":" LINE "]: " fmt "\n", ##__VA_ARGS__)
#define LOG_ERROR_PRINTF(fmt, ...)                                             \
    printf("[ERR ][" FILENAME ":" LINE "]: " fmt "\n", ##__VA_ARGS__)

// Anonymous helpers
namespace {
auto get_bits = [](unsigned int instr, int pos, int width) -> unsigned int {
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
} // namespace

// Get RV32I value(s) from instruction (x)
#define OPCODE(x) get_bits(x, 0, 7)
#define RD(x) get_bits(x, 7, 5)
#define RS1(x) get_bits(x, 15, 5)
#define RS2(x) get_bits(x, 20, 5)
#define FUNCT3(x) get_bits(x, 12, 3)
#define FUNCT7(x) get_bits(x, 25, 7)
#define IMM_10_5(x) get_bits(x, 25, 6)
#define IMM_11_B(x) get_bits(x, 7, 1)
#define IMM_4_1(x) get_bits(x, 8, 4)
#define IMM_4_0(x) get_bits(x, 7, 5)
#define IMM_11_5(x) get_bits(x, 25, 7)
#define IMM_12(x) get_bits(x, 31, 1)
#define IMM_20(x) get_bits(x, 31, 1)
#define IMM_11_0(x) get_bits(x, 20, 12)
#define IMM_11_J(x) get_bits(x, 20, 1)
#define IMM_19_12(x) get_bits(x, 12, 8)
#define IMM_10_1(x) get_bits(x, 21, 10)
#define IMM_31_12(x) get_bits(x, 12, 20)
#define SUCC(x) get_bits(x, 20, 4)
#define PRED(x) get_bits(x, 24, 4)
#define FM(x) get_bits(x, 28, 4)

// Get immediate value from instruction (x)
#define I_IMM(x) ((int)IMM_11_0(x) << 20) >> 20
#define S_IMM(x) ((int)(IMM_4_0(x) | IMM_11_5(x) << 5) << 20) >> 20
#define B_IMM(x)                                                               \
    (int)((IMM_4_1(x) | IMM_10_5(x) << 4 | IMM_11_B(x) << 10 |                 \
           IMM_12(x) << 11)                                                    \
          << 20) >>                                                            \
        19
#define U_IMM(x) IMM_31_12(x) << 12
#define J_IMM(x)                                                               \
    (int)((IMM_10_1(x) | IMM_11_J(x) << 10 | IMM_19_12(x) << 11 |              \
           IMM_20(x) << 19)                                                    \
          << 12) >>                                                            \
        11
#define I_FENCE_IMM(x) S_IMM(x)

#define KB_MULTIPLIER (1024)
#define MB_MULTIPLIER (1024 * 1024)
#define DEFAULT_VIRT_MEM_SIZE (KB_MULTIPLIER * 32) // Default to 32 KB
#define DEFAULT_INT_PERIOD 500

#define ACCESS_MEM_W(virtMem, offset) (*(u32 *)((u8 *)virtMem + offset))
#define ACCESS_MEM_H(virtMem, offset) (*(u16 *)((u8 *)virtMem + offset))
#define ACCESS_MEM_B(virtMem, offset) (*(u8 *)((u8 *)virtMem + offset))

using u8 = uint8_t;
using u16 = uint16_t;
using u32 = uint32_t;
using u64 = uint64_t;
using s8 = int8_t;
using s16 = int16_t;
using s32 = int32_t;

// RV32I instructions
enum {
    EBREAK = (0x1 << 20) | (0x0 << 7) | (0x73),
    SUB = (0x20 << 10) | (0x0 << 7) | (0x33),
    SRA = (0x20 << 10) | (0x5 << 7) | (0x33),
    SRAI = (0x20 << 10) | (0x5 << 7) | (0x13),
    ADD = (0x0 << 10) | (0x0 << 7) | (0x33),
    SLL = (0x0 << 10) | (0x1 << 7) | (0x33),
    SLT = (0x0 << 10) | (0x2 << 7) | (0x33),
    SLTU = (0x0 << 10) | (0x3 << 7) | (0x33),
    XOR = (0x0 << 10) | (0x4 << 7) | (0x33),
    SRL = (0x0 << 10) | (0x5 << 7) | (0x33),
    OR = (0x0 << 10) | (0x6 << 7) | (0x33),
    AND = (0x0 << 10) | (0x7 << 7) | (0x33),
    SLLI = (0x0 << 10) | (0x1 << 7) | (0x13),
    SRLI = (0x0 << 10) | (0x5 << 7) | (0x13),
    ECALL = (0x0 << 7) | (0x73),
    JALR = (0x0 << 7) | (0x67),
    BGEU = (0x7 << 7) | (0x63),
    BLTU = (0x6 << 7) | (0x63),
    BGE = (0x5 << 7) | (0x63),
    BLT = (0x4 << 7) | (0x63),
    BNE = (0x1 << 7) | (0x63),
    BEQ = (0x0 << 7) | (0x63),
    SW = (0x2 << 7) | (0x23),
    SH = (0x1 << 7) | (0x23),
    SB = (0x0 << 7) | (0x23),
    ANDI = (0x7 << 7) | (0x13),
    ORI = (0x6 << 7) | (0x13),
    XORI = (0x4 << 7) | (0x13),
    SLTIU = (0x3 << 7) | (0x13),
    SLTI = (0x2 << 7) | (0x13),
    ADDI = (0x0 << 7) | (0x13),
    FENCE = (0x0 << 7) | (0x0f),
    LHU = (0x5 << 7) | (0x03),
    LBU = (0x4 << 7) | (0x03),
    LW = (0x2 << 7) | (0x03),
    LH = (0x1 << 7) | (0x03),
    LB = (0x0 << 7) | (0x03),
    JAL = (0x6f),
    LUI = (0x37),
    AUIPC = (0x17)
};

// Util functions
std::string disassembleRv32i(unsigned int instr);
bool loadMem(std::string filePath, char *mem, ssize_t memLen);
