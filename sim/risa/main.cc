#include <stdio.h>

#include "common/utils.h"

#include "risa.h"

const char *toolBanner =
    " ________  ___  ________  ________     \n"
    "|\\   __  \\|\\  \\|\\   ____\\|\\   __  \\    \n"
    "\\ \\  \\|\\  \\ \\  \\ \\  \\___|\\ \\  \\|\\  \\   \n"
    " \\ \\   _  _\\ \\  \\ \\_____  \\ \\   __  \\  \n"
    "  \\ \\  \\\\  \\\\ \\  \\|____|\\  \\ \\  \\ \\  \\ \n"
    "   \\ \\__\\\\ _\\\\ \\__\\____\\_\\  \\ \\__\\ \\__\\\n"
    "    \\|__|\\|__|\\|__|\\_________\\|__|\\|__| - RISC-V (RV32I) ISA "
    "simulator\n"
    "                  \\|_________|         \n\n";

int main(int argc, char **argv) {
    // Init simulator
    printf("%s", toolBanner);
    rv32iHart cpu = {0};
    if (!setupSimulator(argc, argv, &cpu)) {
        return -1;
    }
    cpu.handlerProcs[RISA_INIT_HANDLER_PROC](&cpu);
    // Run
    return executionLoop(&cpu);
}
