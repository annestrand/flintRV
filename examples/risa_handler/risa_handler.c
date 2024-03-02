#include <stdio.h>
#include "risa.h"

EXPORT void risaMmioHandler(rv32iHart_t *cpu) {
    printf("MMIO HELLO WORLD - target address is: ( 0x%08x )\n", cpu->targetAddress);
    return;
}
EXPORT void risaIntHandler(rv32iHart_t *cpu) {
    printf("INTERRUPT HELLO WORLD - interrupt timeout is ( %d )\n", cpu->intPeriodVal);
}
EXPORT void risaInitHandler(rv32iHart_t *cpu) {
    printf("INIT HELLO WORLD\n");
    return;
}
EXPORT void risaExitHandler(rv32iHart_t *cpu) {
    printf("EXIT HELLO WORLD\n");
    return;
}