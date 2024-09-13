// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include "flintRV/flintRV.h"

#include "common/utils.h"

#include "miniargparse/miniargparse.h"

void printHelp(void) {
    printf("[Usage]: flintRV [OPTIONS] <program_binary>.hex\n\n"
           "OPTIONS:\n");
    miniargparsePrint();
}

int main(int argc, char *argv[]) {
    // Define opts
    MINIARGPARSE_OPT(
        virtMem, "m", "memSize", 1,
        "Virtual memory/IO size (in bytes - decimal or hex format) "
        "[DEFAULT=32KB].");
    MINIARGPARSE_OPT(help, "h", "help", 0, "Print help and exit.");
    MINIARGPARSE_OPT(tracing, "", "tracing", 0,
                     "Enable trace printing to stdout.");
    MINIARGPARSE_OPT(simTime, "t", "timeout", 1,
                     "Simulation timeout value [DEFAULT=INT32_MAX].");
    MINIARGPARSE_OPT(simVcd, "V", "vcdDump", 1,
                     "Filename for VCD dump [DEFAULT=Disabled].");
    MINIARGPARSE_OPT(version, "v", "version", 0, "Prints version and exits");

    // Parse the args
    int unknownOpt = miniargparseParse(argc, argv);
    if (unknownOpt > 0) {
        LOG_ERROR_PRINTF("Unknown option ( %s ) used.", argv[unknownOpt]);
        printHelp();
        return 1;
    }

    // Exit early if help or version was defined
    if (help.infoBits.used) {
        printHelp();
        return 0;
    }
    if (version.infoBits.used) {
        printf("%s\n", flintRV_VERSION);
        return 0;
    }

    // Check if any option had an error
    miniargparseOpt *tmp = miniargparseOptlistController(NULL);
    while (tmp != NULL) {
        if (tmp->infoBits.hasErr) {
            LOG_ERROR_PRINTF("%s ( Option: %s )", tmp->errValMsg,
                             argv[tmp->index]);
            printHelp();
            return 1;
        }
        tmp = tmp->next;
    }

    // Get needed positional arg (i.e. program binary)
    int programIndex = miniargparseGetPositionalArg(argc, argv, 0);
    if (programIndex == 0) {
        LOG_ERROR("No program binary given.");
        printHelp();
        return 1;
    }
    const char *programFile = argv[programIndex];

    // Get value items
    int memSize = atoi(virtMem.value);
    if (memSize == 0) {
        // If value was passed as a hex string - use default if still 0
        memSize = strtol(virtMem.value, NULL, 16);
        if (memSize == 0) {
            memSize = DEFAULT_VIRT_MEM_SIZE;
        }
    }
    int simTimeVal = atoi(simTime.value);
    if (simTimeVal == 0) {
        simTimeVal = INT32_MAX;
    }

    printf("flintRV - Verilator based flintRV simulator\n");
    LOG_INFO_PRINTF("Simulation timeout value: %d cycles.", simTimeVal);
    LOG_INFO_PRINTF("Memory size set to: %f MB.",
                    (float)memSize / (float)(MB_MULTIPLIER));

    // Instantiate CPU
    flintRV dut = flintRV(simTimeVal, tracing.infoBits.used);
    LOG_INFO_PRINTF("Running simulator...");
    printf(OUTPUT_LINE);
    if (!dut.create(new VflintRV(), simVcd.value)) {
        LOG_ERROR("Failed to create flintRV.");
        return 1;
    }
    if (!dut.createMemory(memSize, programFile)) {
        LOG_ERROR("Failed to create memory.");
        return 1;
    }
    dut.m_cpu->i_ifValid = 1;  // Always valid since we assume combinatorial
                               // read/write for test memory
    dut.m_cpu->i_memValid = 1; // Always valid since we assume combinatorial
                               // read/write for test memory
    // Init stack and frame pointers
    dut.writeRegfile(SP, memSize - 1);
    dut.writeRegfile(FP, memSize - 1);

    clock_t startTime = clock();

    // Run
    while (!dut.end()) {
        if (!dut.instructionUpdate()) {
            LOG_ERROR("Failed instruction fetch.");
            return 1;
        }
        if (!dut.loadStoreUpdate()) {
            LOG_ERROR("Failed load/store fetch.");
            return 1;
        }
        // Evaluate
        dut.tick();
    }
    printf("%s", LOG_LINE_BREAK);

    clock_t endTime = clock();
    LOG_INFO_PRINTF("Simulation stopping, time elapsed: %f seconds.",
                    ((double)(endTime - startTime)) / CLOCKS_PER_SEC);

    return 0;
}
