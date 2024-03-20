#ifndef RISA_H
#define RISA_H

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
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

#define KB_MULTIPLIER (1024)
#define MB_MULTIPLIER (1024 * 1024)
#define DEFAULT_VIRT_MEM_SIZE (KB_MULTIPLIER * 32) // Default to 32 KB
#define DEFAULT_INT_PERIOD 500

#define ACCESS_MEM_W(virtMem, offset) (*(u32 *)((u8 *)virtMem + offset))
#define ACCESS_MEM_H(virtMem, offset) (*(u16 *)((u8 *)virtMem + offset))
#define ACCESS_MEM_B(virtMem, offset) (*(u8 *)((u8 *)virtMem + offset))

#define GET_BITS(var, pos, width) ((var & ((((1 << width) - 1) << pos))) >> pos)
#define GET_OPCODE(instr) GET_BITS(instr, 0, 7)
#define GET_RD(instr) GET_BITS(instr, 7, 5)
#define GET_RS1(instr) GET_BITS(instr, 15, 5)
#define GET_RS2(instr) GET_BITS(instr, 20, 5)
#define GET_FUNCT3(instr) GET_BITS(instr, 12, 3)
#define GET_FUNCT7(instr) GET_BITS(instr, 25, 7)
#define GET_IMM_10_5(instr) GET_BITS(instr, 25, 6)
#define GET_IMM_11_B(instr) GET_BITS(instr, 7, 1)
#define GET_IMM_4_1(instr) GET_BITS(instr, 8, 4)
#define GET_IMM_4_0(instr) GET_BITS(instr, 7, 5)
#define GET_IMM_11_5(instr) GET_BITS(instr, 25, 7)
#define GET_IMM_12(instr) GET_BITS(instr, 31, 1)
#define GET_IMM_20(instr) GET_BITS(instr, 31, 1)
#define GET_IMM_11_0(instr) GET_BITS(instr, 20, 12)
#define GET_IMM_11_J(instr) GET_BITS(instr, 20, 1)
#define GET_IMM_19_12(instr) GET_BITS(instr, 12, 8)
#define GET_IMM_10_1(instr) GET_BITS(instr, 21, 10)
#define GET_IMM_31_12(instr) GET_BITS(instr, 12, 20)
#define GET_SUCC(instr) GET_BITS(instr, 20, 4)
#define GET_PRED(instr) GET_BITS(instr, 24, 4)
#define GET_FM(instr) GET_BITS(instr, 28, 4)

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;

typedef struct {
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
} ImmediateFields;

typedef struct {
    u32 opcode : 7;
    u32 rd : 5;
    u32 rs1 : 5;
    u32 rs2 : 5;
    u32 funct3 : 3;
    u32 funct7 : 7;
} InstructionFields;

typedef struct {
    u32 o_tracePrintEnable : 1;
    u32 o_virtMemSize : 1;
    u32 o_definedHandles : 1;
    u32 o_timeout : 1;
    u32 o_intPeriod : 1;
    u32 o_gdbEnabled : 1;
} optFlags;

typedef struct {
    u32 dbgContinue : 1;
    u32 dbgStep : 1;
    u32 dbgBreak : 1;
} GdbFlags;

typedef struct {
    u16 serverPort;
    int socketFd;
    int connectFd;
    u32 breakAddr;
    GdbFlags gdbFlags;
} GdbFields;

typedef struct rv32iHart rv32iHart_t;
typedef void (*pfn_risa_handlers)(rv32iHart_t *);
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
    pfn_risa_handlers handlerProcs[RISA_HANDLER_PROC_COUNT];
    void (*cleanupSimulator)(rv32iHart_t *);
    void *handlerData;
};

// --- RV32I Instructions ---
typedef enum {
    //     funct7         funct3       op
    ADD = (0x0 << 10) | (0x0 << 7) | (0x33),
    SUB = (0x20 << 10) | (0x0 << 7) | (0x33),
    SLL = (0x0 << 10) | (0x1 << 7) | (0x33),
    SLT = (0x0 << 10) | (0x2 << 7) | (0x33),
    SLTU = (0x0 << 10) | (0x3 << 7) | (0x33),
    XOR = (0x0 << 10) | (0x4 << 7) | (0x33),
    SRL = (0x0 << 10) | (0x5 << 7) | (0x33),
    SRA = (0x20 << 10) | (0x5 << 7) | (0x33),
    OR = (0x0 << 10) | (0x6 << 7) | (0x33),
    AND = (0x0 << 10) | (0x7 << 7) | (0x33)
} RtypeInstructions;

typedef enum {
    //       funct3       op
    JALR = (0x0 << 7) | (0x67),
    LB = (0x0 << 7) | (0x3),
    LH = (0x1 << 7) | (0x3),
    LW = (0x2 << 7) | (0x3),
    LBU = (0x4 << 7) | (0x3),
    LHU = (0x5 << 7) | (0x3),
    ADDI = (0x0 << 7) | (0x13),
    SLTI = (0x2 << 7) | (0x13),
    SLTIU = (0x3 << 7) | (0x13),
    XORI = (0x4 << 7) | (0x13),
    ORI = (0x6 << 7) | (0x13),
    ANDI = (0x7 << 7) | (0x13),
    FENCE = (0x0 << 7) | (0xf),
    ECALL = (0x0 << 7) | (0x73),
    //        imm             funct3       op
    SLLI = (0x0 << 10) | (0x1 << 7) | (0x13),
    SRLI = (0x0 << 10) | (0x5 << 7) | (0x13),
    SRAI = (0x20 << 10) | (0x5 << 7) | (0x13),
    EBREAK = (0x1 << 20) | (0x0 << 7) | (0x73)
} ItypeInstructions;

typedef enum {
    //   funct3       op
    SB = (0x0 << 7) | (0x23),
    SH = (0x1 << 7) | (0x23),
    SW = (0x2 << 7) | (0x23)
} StypeInstructions;

typedef enum {
    //     funct3       op
    BEQ = (0x0 << 7) | (0x63),
    BNE = (0x1 << 7) | (0x63),
    BLT = (0x4 << 7) | (0x63),
    BGE = (0x5 << 7) | (0x63),
    BLTU = (0x6 << 7) | (0x63),
    BGEU = (0x7 << 7) | (0x63)
} BtypeInstructions;

typedef enum {
    //      op
    LUI = (0x37),
    AUIPC = (0x17)
} UtypeInstructions;

typedef enum {
    JAL = (0x6f) // op
} JtypeInstructions;

// Opcode to instruction-format mappings
typedef enum { R, I, S, B, U, J, Undefined } InstFormats;
extern const InstFormats g_opcodeToFormat[128];

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
extern const char *g_regfileAliasLookup[];

// Log/trace macros
#define LOG_LINE_BREAK                                                         \
    "========================================================================" \
    "=="                                                                       \
    "==================\n"

// Prefer shortened __FILE__ expansion if available
#if defined(__FILE_NAME__)
#define FILENAME __FILE_NAME__
#else
#define FILENAME __FILE__
#endif

#define STRINGIFY_INTERNAL(x) #x
#define STRINGIFY(x) STRINGIFY_INTERNAL(x)

#define LINE STRINGIFY(__LINE__)

#define LOG_INFO(msg) printf("[rISA] [" FILENAME ":" LINE "] [INFO]: " msg "\n")
#define LOG_WARNING(msg)                                                       \
    printf("[rISA] [" FILENAME ":" LINE "] [WARNING]: " msg "\n")
#define LOG_ERROR(msg)                                                         \
    printf("[rISA] [" FILENAME ":" LINE "] [ERROR]: " msg "\n")
#define LOG_INFO_PRINTF(fmt, ...)                                              \
    printf("[rISA] [" FILENAME ":" LINE "] [INFO]: " fmt "\n", ##__VA_ARGS__)
#define LOG_WARNING_PRINTF(fmt, ...)                                           \
    printf("[rISA] [" FILENAME ":" LINE "] [WARNING]: " fmt "\n", ##__VA_ARGS__)
#define LOG_ERROR_PRINTF(fmt, ...)                                             \
    printf("[rISA] [" FILENAME ":" LINE "] [ERROR]: " fmt "\n", ##__VA_ARGS__)

// Tracing macro with Register type syntax
#define TRACE_R(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%s, %s\n",                                                 \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rd],             \
                   g_regfileAliasLookup[cpu->instFields.rs1],                  \
                   g_regfileAliasLookup[cpu->instFields.rs2]);                 \
        }                                                                      \
    } while (0)

// Tracing macro with Immediate type syntax
#define TRACE_I(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%s, %d\n",                                                 \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rd],             \
                   g_regfileAliasLookup[cpu->instFields.rs1], cpu->immFinal);  \
        }                                                                      \
    } while (0)

// Tracing macro with Load type syntax
#define TRACE_L(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%d(%s)\n",                                                 \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rd],             \
                   cpu->immFinal, g_regfileAliasLookup[cpu->instFields.rs1]);  \
        }                                                                      \
    } while (0)

// Tracing macro with Store type syntax
#define TRACE_S(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%d(%s)\n",                                                 \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rs2],            \
                   cpu->immFinal, g_regfileAliasLookup[cpu->instFields.rs1]);  \
        }                                                                      \
    } while (0)

// Tracing macro with Upper type syntax
#define TRACE_U(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%08x\n",                                                   \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rd],             \
                   cpu->immFinal);                                             \
        }                                                                      \
    } while (0)

// Tracing macro with Jump type syntax
#define TRACE_J(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf(                                                            \
                "[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, %d\n",  \
                cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4], name,   \
                g_regfileAliasLookup[cpu->instFields.rd], cpu->targetAddress); \
        }                                                                      \
    } while (0)

// Tracing macro with Branch type syntax
#define TRACE_B(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s %s, "    \
                   "%s, %d\n",                                                 \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, g_regfileAliasLookup[cpu->instFields.rs1],            \
                   g_regfileAliasLookup[cpu->instFields.rs2],                  \
                   cpu->targetAddress);                                        \
        }                                                                      \
    } while (0)

// Tracing macro for FENCE
#define TRACE_FEN(cpu, name)                                                   \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s fm:%d, " \
                   "pred:%d, succ:%d\n",                                       \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name, cpu->immFields.fm, cpu->immFields.pred,               \
                   cpu->immFields.succ);                                       \
        }                                                                      \
    } while (0)

// Tracing macro for Environment type syntax
#define TRACE_E(cpu, name)                                                     \
    do {                                                                       \
        if (cpu->opts.o_tracePrintEnable) {                                    \
            printf("[rISA]:[TRACE]:[ %12d cycles ]:  %8x:   %08x   %s\n",      \
                   cpu->cycleCounter, cpu->pc, cpu->virtMem[cpu->pc / 4],      \
                   name);                                                      \
        }                                                                      \
    } while (0)

void defaultMmioHandler(rv32iHart_t *cpu);
void defaultIntHandler(rv32iHart_t *cpu);
void defaultEnvHandler(rv32iHart_t *cpu);
void defaultInitHandler(rv32iHart_t *cpu);
void defaultExitHandler(rv32iHart_t *cpu);
void printHelp(void);
void cleanupSimulator(rv32iHart_t *cpu);
int loadProgram(rv32iHart_t *cpu);
int setupSimulator(int argc, char **argv, rv32iHart_t *cpu);
int executionLoop(rv32iHart_t *cpu);

#endif // RISA_H
