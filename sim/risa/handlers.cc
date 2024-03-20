#include <stdio.h>
#include <stdlib.h>

#include "risa.h"

// Syscalls (taken from "riscv64-unknown-elf/include/machine/syscall.h")
#define SYS_exit 93
#define SYS_write 64

void defaultMmioHandler(rv32iHart_t *cpu) { return; }
void defaultIntHandler(rv32iHart_t *cpu) { return; }
void defaultExitHandler(rv32iHart_t *cpu) { return; }
void defaultInitHandler(rv32iHart_t *cpu) { return; }

// Provide a default simple/basic syscall handler
void defaultEnvHandler(rv32iHart_t *cpu) {
    if ((ItypeInstructions)cpu->ID == EBREAK) {
        // Default handler will just end simulation on EBREAK
        cpu->endTime = clock();
        printf(LOG_LINE_BREAK);
        cpu->cleanupSimulator(cpu);
        exit(0);
    }

    // Otherwise we are processing an ECALL
    switch (cpu->regFile[A7]) {
        case SYS_exit: {
            cpu->endTime = clock();
            // Print out return error code (if there is an error)
            printf(LOG_LINE_BREAK);
            int err = (int)cpu->regFile[A0];
            if (err) {
                LOG_INFO_PRINTF(
                    "Program code on simulator has returned error code: [ %d ]",
                    err);
            }
            cpu->cleanupSimulator(cpu);
            exit(0);
        }
        case SYS_write: {
            int base = cpu->regFile[A1];
            u32 len = cpu->regFile[A2];
            for (u32 i = 0; i < len; ++i) {
                printf("%c", ACCESS_MEM_B(cpu->virtMem, base + i));
                fflush(stdout);
            }
            break;
        }
        default:
            LOG_WARNING_PRINTF("Unknown syscall code encountered: [ %d ]",
                               cpu->regFile[A7]);
            break;
    }
}
