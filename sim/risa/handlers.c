#include "stdlib.h"
#include "stdio.h"
#include "risa.h"

// Syscalls
#define	syscall_exit    1
#define	syscall_read    4
#define	syscall_write   5

void defaultMmioHandler(rv32iHart_t *cpu)  { return; }
void defaultIntHandler(rv32iHart_t *cpu)   { return; }
void defaultExitHandler(rv32iHart_t *cpu)  { return; }
void defaultInitHandler(rv32iHart_t *cpu)  { return; }

// Provide a default simple/basic syscall handler
void defaultEnvHandler(rv32iHart_t *cpu) {
    switch(cpu->regFile[A7]) {
        default:
            break;
        // Detect what syscall we encountered
        case syscall_exit: {
            cpu->endTime = clock();
            // Print out return error code (if there is an error)
            printf(LOG_LINE_BREAK);
            int err = (int)cpu->regFile[A0];
            if (err) {
                LOG_INFO_PRINTF("Program code on simulator has returned error code: [ %d ]", err);
            }
            cpu->cleanupSimulator(cpu);
            exit(0);
        }
        case syscall_write: {
            int base = cpu->regFile[A1];
            u32 len = cpu->regFile[A2];
            for (u32 i=0; i<len; ++i) {
                printf("%c", ACCESS_MEM_B(cpu->virtMem, base + i));
                fflush(stdout);
            }
            break;
        }
    }
}
