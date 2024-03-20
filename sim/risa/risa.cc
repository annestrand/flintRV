#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <inttypes.h>

#include <string>

#include "common/utils.h"
#include "gdbserver.h"
#include "miniargparse/miniargparse.h"
#include "risa.h"
#include "types.h"

static volatile int g_sigIntDet = 0;
static SIGINT_RET_TYPE sigintHandler(SIGINT_PARAM sig) {
    g_sigIntDet = 1;
    SIGINT_RET;
}

risa_handler g_defaultHandlerTable[RISA_HANDLER_PROC_COUNT] = {
    defaultMmioHandler, defaultIntHandler, defaultEnvHandler,
    defaultExitHandler, defaultInitHandler};
const char *g_handlerProcNames[RISA_HANDLER_PROC_COUNT] = {
    "risaMmioHandler", "risaIntHandler",  "risaEnvHandler",
    "risaInitHandler", "risaExitHandler",
};

void printHelp(void) {
    printf("\n"
           "[Usage  ]: risa [OPTIONS] <program_binary>\n"
           "[Example]: risa -m 1024 my_riscv_program.hex"
           "\n\n"
           "OPTIONS:\n");
    miniargparsePrint();
}

void cleanupSimulator(rv32iHart *cpu) {
    if (cpu->handlerProcs[RISA_EXIT_HANDLER_PROC] != NULL) {
        cpu->handlerProcs[RISA_EXIT_HANDLER_PROC](cpu);
    }
    if (cpu->virtMem != NULL) {
        free(cpu->virtMem);
    }
    if (cpu->handlerData != NULL) {
        free(cpu->handlerData);
    }
    if (cpu->handlerLib != NULL) {
        CLOSE_LIB(cpu->handlerLib);
    }
    LOG_INFO_PRINTF("Simulation stopping, time elapsed: %f seconds.",
                    ((double)(cpu->endTime - cpu->startTime)) / CLOCKS_PER_SEC);
}

bool setupSimulator(int argc, char **argv, rv32iHart *cpu) {
    // Define opts
    MINIARGPARSE_OPT(
        virtMem, "m", "memSize", 1,
        "Virtual memory/IO size (in bytes - decimal or hex format) "
        "[DEFAULT=32KB].");
    MINIARGPARSE_OPT(handlerLib, "l", "handlerLibrary", 1,
                     "Shared library file to user-defined handler functions "
                     "[DEFAULT=stubs].");
    MINIARGPARSE_OPT(help, "h", "help", 0, "Print help and exit.");
    MINIARGPARSE_OPT(tracing, "", "tracing", 0,
                     "Enable trace printing to stdout.");
    MINIARGPARSE_OPT(timeout, "t", "timeout", 1,
                     "Simulator cycle timeout value [DEFAULT=INT32_MAX].");
    MINIARGPARSE_OPT(interrupt, "i", "interruptPeriod", 1,
                     "Simulator interrupt-check timeout value [DEFAULT=500].");
    MINIARGPARSE_OPT(gdb, "g", "gdb", 0, "Run the simulator in GDB-mode.");

    // Parse the args
    int unknownOpt = miniargparseParse(argc, argv);
    if (unknownOpt > 0) {
        LOG_ERROR_PRINTF("Unknown option ( %s ) used.", argv[unknownOpt]);
        printHelp();
        return false;
    }

    // Exit early if help was defined
    if (help.infoBits.used) {
        printHelp();
        exit(0);
    }

    // Check if any option had an error
    miniargparseOpt *tmp = miniargparseOptlistController(NULL);
    while (tmp != NULL) {
        if (tmp->infoBits.hasErr) {
            LOG_ERROR_PRINTF("%s ( Option: %s )", tmp->errValMsg,
                             argv[tmp->index]);
            printHelp();
            return false;
        }
        tmp = tmp->next;
    }

    // Get needed positional arg (i.e. program binary)
    int programIndex = miniargparseGetPositionalArg(argc, argv, 0);
    if (programIndex == 0) {
        LOG_ERROR("No program binary given.");
        printHelp();
        return false;
    }
    cpu->programFile = argv[programIndex];

    // Get value items
    cpu->virtMemSize = (u32)atoi(virtMem.value);
    if (cpu->virtMemSize == 0) {
        // If value was passed as a hex string
        cpu->virtMemSize = strtol(virtMem.value, NULL, 16);
    }
    cpu->timeoutVal = (long)atol(timeout.value);
    cpu->intPeriodVal = (u32)atoi(interrupt.value);
    cpu->opts.o_timeout = timeout.infoBits.used;
    cpu->opts.o_tracePrintEnable = tracing.infoBits.used;
    cpu->opts.o_gdbEnabled = gdb.infoBits.used;

    // Load handler lib and syms (if given)
    cpu->handlerLib = LOAD_LIB(handlerLib.value);
    if (handlerLib.infoBits.used && cpu->handlerLib == NULL) {
        LOG_WARNING_PRINTF("Could not load dynamic library ( %s ).",
                           handlerLib.value);
    }
    for (int i = 0; i < RISA_HANDLER_PROC_COUNT; ++i) {
        cpu->handlerProcs[i] =
            (risa_handler)LOAD_SYM(cpu->handlerLib, g_handlerProcNames[i]);
        if (cpu->handlerProcs[i] == NULL) {
            cpu->handlerProcs[i] = g_defaultHandlerTable[i];
            if (handlerLib.infoBits.used) {
                LOG_WARNING_PRINTF(
                    "Could not load %s - using default stub instead.",
                    g_handlerProcNames[i]);
            }
        }
    }
    cpu->cleanupSimulator = cleanupSimulator;

    // Interrupt period and virtual memory config
    if (cpu->intPeriodVal == 0) {
        cpu->intPeriodVal = DEFAULT_INT_PERIOD;
    }
    if (cpu->virtMemSize == 0) {
        cpu->virtMemSize = DEFAULT_VIRT_MEM_SIZE;
    }
    LOG_INFO_PRINTF("Interrupt period set to: %d cycles.", cpu->intPeriodVal);
    LOG_INFO_PRINTF("Virtual memory size set to: %f MB.",
                    (float)cpu->virtMemSize / (float)(MB_MULTIPLIER));

    // Alloc vmem and load program binary
    cpu->virtMem = (u32 *)malloc(cpu->virtMemSize);
    if (cpu->virtMem == NULL) {
        LOG_ERROR("Could not allocate virtual memory.");
        return ENOMEM;
    }
    return loadMem(cpu->programFile, reinterpret_cast<char *>(cpu->virtMem),
                   cpu->virtMemSize);
}

// Simulation loop entrypoint
int executionLoop(rv32iHart *cpu) {
    // Init stack and frame pointer
    cpu->regFile[SP] = cpu->regFile[FP] = cpu->virtMemSize - 1;

    cpu->startTime = clock();
    if (cpu->opts.o_gdbEnabled) {
        gdbserverInit(cpu);
    }
    SIGINT_REGISTER(cpu, sigintHandler);

    LOG_INFO("Running simulator...");
    printf(OUTPUT_LINE);
    for (;;) {
        // Sim timeout value or sigint detected - normal cleanup/exit
        if (g_sigIntDet ||
            (cpu->opts.o_timeout && cpu->cycleCounter == cpu->timeoutVal)) {
            cpu->endTime = clock();
            printf(LOG_LINE_BREAK);
            if (cpu->opts.o_timeout) {
                LOG_INFO_PRINTF("Timeout value reached - ( %d cycles ).",
                                cpu->timeoutVal);
            }
            cleanupSimulator(cpu);
            return 0;
        }
        // Process GDB commands
        if (cpu->opts.o_gdbEnabled) {
            gdbserverCall(cpu);
        }

        // Fetch
        cpu->cycleCounter++;
        cpu->IF = ACCESS_MEM_W(cpu->virtMem, cpu->pc);
        if (cpu->opts.o_tracePrintEnable) {
            printf("%8x:   0x%08x   %-30s CYCLE:[%" PRIu64 "]\n", cpu->pc,
                   cpu->IF, disassembleRv32i(cpu->IF).c_str(),
                   (long unsigned int)cpu->cycleCounter);
        }
        cpu->instFields.opcode = OPCODE(cpu->IF);
        switch (cpu->instFields.opcode) {
            case R: {
                // Decode
                cpu->instFields.rd = RD(cpu->IF);
                cpu->instFields.rs1 = RS1(cpu->IF);
                cpu->instFields.rs2 = RS2(cpu->IF);
                cpu->instFields.funct3 = FUNCT3(cpu->IF);
                cpu->instFields.funct7 = FUNCT7(cpu->IF);
                cpu->ID = (cpu->instFields.funct7 << 10) |
                          (cpu->instFields.funct3 << 7) |
                          cpu->instFields.opcode;
                // Execute
                switch (cpu->ID) {
                    case ADD: { // Addition
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] +
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SUB: { // Subtraction
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] -
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SLL: { // Shift left logical
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1]
                            << cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SLT: { // Set if less than (signed)
                        cpu->regFile[cpu->instFields.rd] =
                            ((s32)cpu->regFile[cpu->instFields.rs1] <
                             (s32)cpu->regFile[cpu->instFields.rs2])
                                ? 1
                                : 0;
                        break;
                    }
                    case SLTU: { // Set if less than (unsigned)
                        cpu->regFile[cpu->instFields.rd] =
                            (cpu->regFile[cpu->instFields.rs1] <
                             cpu->regFile[cpu->instFields.rs2])
                                ? 1
                                : 0;
                        break;
                    }
                    case XOR: { // Bitwise xor
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] ^
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SRL: { // Shift right logical
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] >>
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SRA: { // Shift right arithmetic
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)((s32)cpu->regFile[cpu->instFields.rs1] >>
                                  cpu->regFile[cpu->instFields.rs2]);
                        break;
                    }
                    case OR: { // Bitwise or
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] |
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case AND: { // Bitwise and
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] &
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                }
                break;
            }
            case I_ARITH:
            case I_FENCE:
            case I_JUMP:
            case I_LOAD:
            case I_SYS: {
                // Decode
                cpu->instFields.rd = RD(cpu->IF);
                cpu->instFields.rs1 = RS1(cpu->IF);
                cpu->instFields.funct3 = FUNCT3(cpu->IF);
                cpu->immFields.imm11_0 = IMM_11_0(cpu->IF);
                cpu->immFields.succ = SUCC(cpu->IF);
                cpu->immFields.pred = PRED(cpu->IF);
                cpu->immFields.fm = FM(cpu->IF);
                cpu->immFinal = (((s32)cpu->immFields.imm11_0 << 20) >> 20);
                cpu->ID =
                    (cpu->instFields.funct3 << 7) | cpu->instFields.opcode;
                cpu->targetAddress =
                    cpu->regFile[cpu->instFields.rs1] + cpu->immFinal;
                // Execute
                switch (cpu->ID) {
                    case SLLI: { // Shift left logical by immediate (i.e. rs2 is
                                 // shamt)
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] << cpu->immFinal;
                        break;
                    }
                    case SRLI: { // Shift right logical by immediate (i.e. rs2
                                 // is shamt)
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] >> cpu->immFinal;
                        break;
                    }
                    case SRAI: { // Shift right arithmetic by immediate (i.e.
                                 // rs2 is shamt)
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)((s32)cpu->regFile[cpu->instFields.rs1] >>
                                  cpu->immFinal);
                        break;
                    }
                    case JALR: { // Jump and link register
                        cpu->regFile[cpu->instFields.rd] = cpu->pc + 4;
                        cpu->pc = ((cpu->targetAddress) & 0xfffffffe) - 4;
                        break;
                    }
                    case LB: { // Load byte (signed)
                        u32 loadByte =
                            (u32)ACCESS_MEM_B(cpu->virtMem, cpu->targetAddress);
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)((s32)(loadByte << 24) >> 24);
                        break;
                    }
                    case LH: { // Load halfword (signed)
                        u32 loadHalfword =
                            (u32)ACCESS_MEM_H(cpu->virtMem, cpu->targetAddress);
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)((s32)(loadHalfword << 16) >> 16);
                        break;
                    }
                    case LW: { // Load word
                        cpu->regFile[cpu->instFields.rd] =
                            ACCESS_MEM_W(cpu->virtMem, cpu->targetAddress);
                        break;
                    }
                    case LBU: { // Load byte (unsigned)
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)ACCESS_MEM_B(cpu->virtMem, cpu->targetAddress);
                        break;
                    }
                    case LHU: { // Load halfword (unsigned)
                        cpu->regFile[cpu->instFields.rd] =
                            (u32)ACCESS_MEM_H(cpu->virtMem, cpu->targetAddress);
                        break;
                    }
                    case ADDI: { // Add immediate
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] + cpu->immFinal;
                        break;
                    }
                    case SLTI: { // Set if less than immediate (signed)
                        cpu->regFile[cpu->instFields.rd] =
                            ((s32)cpu->regFile[cpu->instFields.rs1] <
                             cpu->immFinal)
                                ? 1
                                : 0;
                        break;
                    }
                    case SLTIU: { // Set if less than immediate (unsigned)
                        cpu->regFile[cpu->instFields.rd] =
                            (cpu->regFile[cpu->instFields.rs1] <
                             (u32)cpu->immFinal)
                                ? 1
                                : 0;
                        break;
                    }
                    case XORI: { // Bitwise exclusive or immediate
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] ^ cpu->immFinal;
                        break;
                    }
                    case ORI: { // Bitwise or immediate
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] | cpu->immFinal;
                        break;
                    }
                    case ANDI: { // Bitwise and immediate
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->regFile[cpu->instFields.rs1] & cpu->immFinal;
                        break;
                    }
                    case FENCE: { // FENCE - order device I/O and memory
                                  // accesses
                        cpu->handlerProcs[RISA_ENV_HANDLER_PROC](cpu);
                        break;
                    }
                    // Catch environment-type instructions
                    default: {
                        cpu->ID = (cpu->immFields.imm11_0 << 20) |
                                  (cpu->instFields.funct3 << 7) |
                                  cpu->instFields.opcode;
                        switch (cpu->ID) {
                            case ECALL: { // ECALL - request a syscall
                                cpu->handlerProcs[RISA_ENV_HANDLER_PROC](cpu);
                                break;
                            }
                            case EBREAK: { // EBREAK - halt processor execution,
                                           // transfer control to debugger
                                cpu->handlerProcs[RISA_ENV_HANDLER_PROC](cpu);
                                break;
                            }
                            default: { // Invalid instruction
                                cpu->endTime = clock();
                                printf(LOG_LINE_BREAK);
                                LOG_ERROR_PRINTF(
                                    "(0x%08x) is an invalid instruction.",
                                    cpu->IF);
                                cleanupSimulator(cpu);
                                return EILSEQ;
                            }
                        }
                    }
                }
                break;
            }
            case S: {
                // Decode
                cpu->instFields.funct3 = FUNCT3(cpu->IF);
                cpu->immFields.imm4_0 = IMM_4_0(cpu->IF);
                cpu->instFields.rs1 = RS1(cpu->IF);
                cpu->instFields.rs2 = RS2(cpu->IF);
                cpu->immFields.imm11_5 = IMM_11_5(cpu->IF);
                cpu->immPartial =
                    cpu->immFields.imm4_0 | (cpu->immFields.imm11_5 << 5);
                cpu->immFinal = (((s32)cpu->immPartial << 20) >> 20);
                cpu->ID =
                    (cpu->instFields.funct3 << 7) | cpu->instFields.opcode;
                cpu->targetAddress =
                    cpu->regFile[cpu->instFields.rs1] + cpu->immFinal;
                // Execute
                switch (cpu->ID) {
                    case SB: { // Store byte
                        ACCESS_MEM_B(cpu->virtMem, cpu->targetAddress) =
                            (u8)cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SH: { // Store halfword
                        ACCESS_MEM_H(cpu->virtMem, cpu->targetAddress) =
                            (u16)cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                    case SW: { // Store word
                        ACCESS_MEM_W(cpu->virtMem, cpu->targetAddress) =
                            cpu->regFile[cpu->instFields.rs2];
                        break;
                    }
                }
                cpu->handlerProcs[RISA_MMIO_HANDLER_PROC](cpu);
                break;
            }
            case B: {
                // Decode
                cpu->instFields.rs1 = RS1(cpu->IF);
                cpu->instFields.rs2 = RS2(cpu->IF);
                cpu->instFields.funct3 = FUNCT3(cpu->IF);
                cpu->immFields.imm11 = IMM_11_B(cpu->IF);
                cpu->immFields.imm4_1 = IMM_4_1(cpu->IF);
                cpu->immFields.imm10_5 = IMM_10_5(cpu->IF);
                cpu->immFields.imm12 = IMM_12(cpu->IF);
                cpu->immPartial =
                    cpu->immFields.imm4_1 | (cpu->immFields.imm10_5 << 4) |
                    (cpu->immFields.imm11 << 10) | (cpu->immFields.imm12 << 11);
                cpu->targetAddress = (s32)(cpu->immPartial << 20) >> 19;
                cpu->ID =
                    (cpu->instFields.funct3 << 7) | cpu->instFields.opcode;
                // Execute
                switch (cpu->ID) {
                    case BEQ: { // Branch if Equal
                        if ((s32)cpu->regFile[cpu->instFields.rs1] ==
                            (s32)cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                    case BNE: { // Branch if Not Equal
                        if ((s32)cpu->regFile[cpu->instFields.rs1] !=
                            (s32)cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                    case BLT: { // Branch if Less Than
                        if ((s32)cpu->regFile[cpu->instFields.rs1] <
                            (s32)cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                    case BGE: { // Branch if Greater Than or Equal
                        if ((s32)cpu->regFile[cpu->instFields.rs1] >=
                            (s32)cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                    case BLTU: { // Branch if Less Than (unsigned)
                        if (cpu->regFile[cpu->instFields.rs1] <
                            cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                    case BGEU: { // Branch if Greater Than or Equal (unsigned)
                        if (cpu->regFile[cpu->instFields.rs1] >=
                            cpu->regFile[cpu->instFields.rs2]) {
                            cpu->pc += cpu->targetAddress - 4;
                        }
                        break;
                    }
                }
                break;
            }
            case U_AUIPC:
            case U_LUI: {
                // Decode
                cpu->instFields.rd = RD(cpu->IF);
                cpu->immFields.imm31_12 = IMM_31_12(cpu->IF);
                cpu->immFinal = cpu->immFields.imm31_12 << 12;
                // Execute
                switch (cpu->instFields.opcode) {
                    case LUI: { // Load Upper Immediate
                        cpu->regFile[cpu->instFields.rd] = cpu->immFinal;
                        break;
                    }
                    case AUIPC: { // Add Upper Immediate to cpu->pc
                        cpu->regFile[cpu->instFields.rd] =
                            cpu->pc + cpu->immFinal;
                        break;
                    }
                }
                break;
            }
            case J: {
                // Decode
                cpu->instFields.rd = RD(cpu->IF);
                cpu->immFields.imm19_12 = IMM_19_12(cpu->IF);
                cpu->immFields.imm11 = IMM_11_J(cpu->IF);
                cpu->immFields.imm10_1 = IMM_10_1(cpu->IF);
                cpu->immFields.imm20 = IMM_20(cpu->IF);
                cpu->immPartial = cpu->immFields.imm10_1 |
                                  (cpu->immFields.imm11 << 10) |
                                  (cpu->immFields.imm19_12 << 11) |
                                  (cpu->immFields.imm20 << 19);
                cpu->targetAddress = (s32)(cpu->immPartial << 12) >> 11;
                // Execute
                cpu->regFile[cpu->instFields.rd] = cpu->pc + 4;
                cpu->pc += cpu->targetAddress - 4;
                break;
            }
            default: {
                // Invalid instruction
                cpu->endTime = clock();
                printf(LOG_LINE_BREAK);
                LOG_ERROR_PRINTF("( 0x%08x ) is an invalid instruction.",
                                 cpu->IF);
                cleanupSimulator(cpu);
                return EILSEQ;
            }
        }
        // If PC is out-of-bounds
        if (cpu->pc > cpu->virtMemSize) {
            cpu->endTime = clock();
            printf(LOG_LINE_BREAK);
            LOG_ERROR("Program counter is out of range.");
            cleanupSimulator(cpu);
            return EFAULT;
        }

        if ((cpu->cycleCounter % cpu->intPeriodVal) == 0) {
            cpu->handlerProcs[RISA_INT_HANDLER_PROC](cpu);
        }
        cpu->pc += 4;
        cpu->regFile[ZERO] = 0;
    }
}
