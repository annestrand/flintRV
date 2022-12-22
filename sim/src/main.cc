#include "boredcore.hh"
#include "common.hh"

#include "miniargparse.h"

#define KB_MULTIPLIER           (1024)
#define MB_MULTIPLIER           (1024*1024)
#define DEFAULT_VIRT_MEM_SIZE   (KB_MULTIPLIER * 32) // Default to 32 KB
#define OUTPUT_LINE \
    "===[ OUTPUT ]===================================================================================================\n"
#define LOG_LINE_BREAK \
    "================================================================================================================\n"

void printHelp(void) {
    printf("Vboredcore - Verilated boredcore simulator\n"
        "[Usage]: Vboredcore [OPTIONS] <program_binary>.hex\n\n"
        "OPTIONS:\n"
    );
    miniargparsePrint();
}

int main(int argc, char *argv[]) {
    // Define opts
    MINIARGPARSE_OPT(virtMem, "m", "memSize", 1,
        "Virtual memory/IO size (in bytes - decimal or hex format) [DEFAULT=32KB].");
    MINIARGPARSE_OPT(help, "h", "help", 0, "Print help and exit.");
    MINIARGPARSE_OPT(dumpLvl, "d", "dumpLevel", 1, "Verbose trace print-level [DEFAULT=0].");
    MINIARGPARSE_OPT(simTime, "t", "timeout", 1, "Simulation timeout value [DEFAULT=1000].");

    // Parse the args
    int unknownOpt = miniargparseParse(argc, argv);
    if (unknownOpt > 0) {
        LOG_E("Unknown option ( %s ) used.\n\n", argv[unknownOpt]);
        printHelp();
        return 1;
    }

    // Exit early if help was defined
    if (help.infoBits.used) {
        printHelp();
        return 0;
    }

    // Check if any option had an error
    miniargparseOpt *tmp = miniargparseOptlistController(NULL);
    while (tmp != NULL) {
        if (tmp->infoBits.hasErr) {
            LOG_E("%s ( Option: %s )\n\n", tmp->errValMsg, argv[tmp->index]);
            printHelp();
            return 1;
        }
        tmp = tmp->next;
    }

    // Get needed positional arg (i.e. program binary)
    int programIndex = miniargparseGetPositionalArg(argc, argv, 0);
    if (programIndex == 0) {
        LOG_E("No program binary given.\n\n");
        printHelp();
        return 1;
    }
    const char* programFile = argv[programIndex];

    // Get value items
    int memSize = atoi(virtMem.value);
    if (memSize == 0) {
        // If value was passed as a hex string - use default if still 0
        memSize = strtol(virtMem.value, NULL, 16);
        if (memSize == 0) { memSize = DEFAULT_VIRT_MEM_SIZE; }
    }
    int simTimeVal = atoi(simTime.value);
    if (simTimeVal == 0) { simTimeVal = 1000; }
    LOG_I("Memory size set to: [ %f MB ].\n", (float)memSize / (float)(MB_MULTIPLIER));
    LOG_I("Simulation timeout value:  [ %d ].\n", simTimeVal);

    // Instantiate CPU
    boredcore dut = boredcore(simTimeVal, atoi(dumpLvl.value));
    LOG_I("Starting simulation...\n\n%s", OUTPUT_LINE);
    if (!dut.create(new Vboredcore(), NULL))        { LOG_E("Failed to create Vboredcore.\n");  return 1; }
    if (!dut.createMemory(memSize, programFile))    { LOG_E("Failed to create memory.\n");      return 1; }
    dut.m_cpu->i_ifValid        = 1; // Always valid since we assume combinatorial read/write for test memory
    dut.m_cpu->i_memValid       = 1; // Always valid since we assume combinatorial read/write for test memory
    // Init stack and frame pointers
    dut.writeRegfile(SP, memSize-1);
    dut.writeRegfile(FP, memSize-1);

    // Run
    while(!dut.end()) {
        if (!dut.instructionUpdate())    { LOG_E("Failed instruction fetch.\n"); return 1; }
        if (!dut.loadStoreUpdate())      { LOG_E("Failed load/store fetch.\n");  return 1; }
        // Evaluate
        dut.tick();
    }

    printf("%s\n", LOG_LINE_BREAK);
    LOG_I("Simulation done.\n");
    return 0;
}
