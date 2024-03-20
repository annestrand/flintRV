#include "gdbserver.h"
#include "minigdbstub.h"
#include "risa.h"
#include "socket.h"

void gdbserverInit(rv32iHart_t *cpu) {
    cpu->gdbFields.serverPort = 3333;

    if ((cpu->gdbFields.socketFd > 0) || (cpu->gdbFields.connectFd > 0)) {
        stopServer(cpu);
    }

    if (startServer(cpu) < 0) {
        printf(LOG_LINE_BREAK);
        cleanupSimulator(cpu);
        exit(-1);
    }

    if (cpu->gdbFields.socketFd > 0) {
        LOG_INFO("GDB server started.");
    } else {
        LOG_WARNING(
            "Could not start GDB server. Falling back to regular simulator "
            "execution.");
        cpu->opts.o_gdbEnabled = 0;
    }
    return;
}

void gdbserverCall(rv32iHart_t *cpu) {
    // Check gdb flags
    if (cpu->gdbFields.gdbFlags.dbgBreak &&
        cpu->pc == cpu->gdbFields.breakAddr) {
        cpu->gdbFields.gdbFlags.dbgBreak = 0;
        cpu->gdbFields.gdbFlags.dbgContinue = 0;
        cpu->gdbFields.gdbFlags.dbgStep = 0;
    } else if (cpu->gdbFields.gdbFlags.dbgStep) {
        cpu->gdbFields.gdbFlags.dbgContinue = 0;
        cpu->gdbFields.gdbFlags.dbgStep = 0;
    } else if (cpu->gdbFields.gdbFlags.dbgContinue) {
        return;
    }

    // Update regs
    u32 regs[REGISTER_COUNT + 1];
    for (int i = 0; i < REGISTER_COUNT; ++i) {
        regs[i] = cpu->regFile[i];
    }
    // Append PC reg
    regs[REGISTER_COUNT] = cpu->pc;

    // Create and write values to minigdbstub process call object
    mgdbProcObj mgdbObj = {0};
    mgdbObj.regs = (char *)regs;
    mgdbObj.regsSize = sizeof(regs);
    mgdbObj.regsCount = REGISTER_COUNT;
    if (cpu->cycleCounter > 0) {
        mgdbObj.opts.o_signalOnEntry = 1;
    }
    mgdbObj.opts.o_enableLogging = GDBLOG;
    mgdbObj.usrData = (void *)cpu;

    // Call into minigdbstub
    minigdbstubProcess(&mgdbObj);
}

// User-defined minigdbstub handlers
static void minigdbstubUsrWriteMem(size_t addr, unsigned char data,
                                   void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    ACCESS_MEM_W(cpuHandle->virtMem, addr) = data;
    return;
}

static unsigned char minigdbstubUsrReadMem(size_t addr, void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    return ACCESS_MEM_B(cpuHandle->virtMem, addr);
}

static void minigdbstubUsrContinue(void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    cpuHandle->gdbFields.gdbFlags.dbgContinue = 1;
    return;
}

static void minigdbstubUsrStep(void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    cpuHandle->gdbFields.gdbFlags.dbgStep = 1;
    return;
}

static char minigdbstubUsrGetchar(void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    while (1) {
        char packet;
        size_t len = sizeof(packet);
        readSocket(cpuHandle->gdbFields.connectFd, &packet, len);
        return packet;
    }
}

static void minigdbstubUsrPutchar(char data, void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    writeSocket(cpuHandle->gdbFields.connectFd, (const char *)&data,
                sizeof(char));
}

static void minigdbstubUsrProcessBreakpoint(int type, size_t addr,
                                            void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    cpuHandle->gdbFields.breakAddr = (u32)addr;
    cpuHandle->gdbFields.gdbFlags.dbgBreak = 1;
    return;
}

static void minigdbstubUsrKillSession(void *usrData) {
    rv32iHart_t *cpuHandle = (rv32iHart_t *)usrData;
    cpuHandle->endTime = clock();
    printf(LOG_LINE_BREAK);
    cleanupSimulator(cpuHandle);
    exit(0);
}
