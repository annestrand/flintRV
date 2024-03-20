#pragma once

#include "common/utils.h"

struct ImmediateFields {
    u32 imm11_0 : 12;
    u32 imm4_0 : 5;
    u32 imm11_5 : 7;
    u32 imm11 : 1;
    u32 imm4_1 : 4;
    u32 imm10_5 : 6;
    u32 imm12 : 1;
    u32 imm31_12 : 20;
    u32 imm19_12 : 8;
    u32 imm10_1 : 10;
    u32 imm20 : 1;
    u32 succ : 4;
    u32 pred : 4;
    u32 fm : 4;
};

struct InstructionFields {
    u32 opcode : 7;
    u32 rd : 5;
    u32 rs1 : 5;
    u32 rs2 : 5;
    u32 funct3 : 3;
    u32 funct7 : 7;
};

struct optFlags {
    u32 o_tracePrintEnable : 1;
    u32 o_virtMemSize : 1;
    u32 o_definedHandles : 1;
    u32 o_timeout : 1;
    u32 o_intPeriod : 1;
    u32 o_gdbEnabled : 1;
};

struct GdbFlags {
    u32 dbgContinue : 1;
    u32 dbgStep : 1;
    u32 dbgBreak : 1;
};

struct GdbFields {
    u16 serverPort;
    int socketFd;
    int connectFd;
    u32 breakAddr;
    GdbFlags gdbFlags;
};

struct rv32iHart;
using risa_handler = void (*)(rv32iHart *);
typedef enum {
    RISA_MMIO_HANDLER_PROC = 0,
    RISA_INT_HANDLER_PROC,
    RISA_ENV_HANDLER_PROC,
    RISA_INIT_HANDLER_PROC,
    RISA_EXIT_HANDLER_PROC,
    RISA_HANDLER_PROC_COUNT
} HandlerProcNames;

struct rv32iHart {
    u32 pc;
    u32 regFile[32];
    u32 IF;
    u32 ID;
    s32 immFinal;
    s32 immPartial;
    ImmediateFields immFields;
    InstructionFields instFields;
    u32 targetAddress;
    u32 cycleCounter;
    char *programFile;
    u32 *virtMem;
    u32 virtMemSize;
    u32 intPeriodVal;
    u32 timeoutVal;
    clock_t startTime;
    clock_t endTime;
    optFlags opts;
    GdbFields gdbFields;
    LIB_HANDLE handlerLib;
    risa_handler handlerProcs[RISA_HANDLER_PROC_COUNT];
    void (*cleanupSimulator)(rv32iHart *);
    void *handlerData;
};

// Regfile aliases
typedef enum {
    ZERO,
    RA,
    SP,
    GP,
    TP,
    T0,
    T1,
    T2,
    S0,
    FP = S0,
    S1,
    A0,
    A1,
    A2,
    A3,
    A4,
    A5,
    A6,
    A7,
    S2,
    S3,
    S4,
    S5,
    S6,
    S7,
    S8,
    S9,
    S10,
    S11,
    T3,
    T4,
    T5,
    T6,
    REGISTER_COUNT
} regfileAliases;

void defaultMmioHandler(rv32iHart *cpu);
void defaultIntHandler(rv32iHart *cpu);
void defaultEnvHandler(rv32iHart *cpu);
void defaultInitHandler(rv32iHart *cpu);
void defaultExitHandler(rv32iHart *cpu);
void printHelp(void);
void cleanupSimulator(rv32iHart *cpu);
bool setupSimulator(int argc, char **argv, rv32iHart *cpu);
int executionLoop(rv32iHart *cpu);

// Default handlers
void defaultMmioHandler(rv32iHart *cpu);
void defaultIntHandler(rv32iHart *cpu);
void defaultEnvHandler(rv32iHart *cpu);
void defaultExitHandler(rv32iHart *cpu);
void defaultInitHandler(rv32iHart *cpu);
