#include <cstdio>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <gtest/gtest.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"
#include "boredcore.hh"
#include "common.hh"

// ====================================================================================================================
TEST(algorithms, fibonacci) {
    boredcore dut                   = boredcore(100000);
    const char *testMachCodePath    = BASE_PATH "/fibonacci.mem";
    if (!dut.create(new Vboredcore(), "obj_dir/fibonacci.vcd")) { FAIL(); }
    if (!dut.createStimulus(testMachCodePath))                      { FAIL(); }

    // Create a dummy/test memory (and access helpers)
    constexpr unsigned int testMemLen   = 0x2000;
    int testMem[testMemLen]             = {0};
    auto checkAddr  = [](unsigned int addr) { if (addr >= testMemLen) { FAIL() << "Address is out of bounds!";} };
    auto readMem    = [checkAddr](int addr, int* mem)           { checkAddr(addr); return mem[addr >> 2];   };
    auto writeMem   = [checkAddr](int addr, int* mem, int val)  { checkAddr(addr); mem[addr >> 2] = val;    };
    // Init dummy memory
    auto dummyMemInit = machineCodeFileReader(testMachCodePath);
    for (int i=0; i<dummyMemInit.size(); ++i) { testMem[i] = (int)HEX_DECODE_ASCII(dummyMemInit[i].c_str()); }
    // Test checker function
    std::function<int(int)> fibonacci = [&](int x) {
        if (x <= 1) { return x; }
        return fibonacci(x - 1) + fibonacci(x - 2);
    };

    bool done                   = false;
    constexpr int doneReg       = 27; // s11
    constexpr int simDoneVal    = -1;
    while (!dut.end() && !done) {
        dut.m_cpu->i_instr      = (int)HEX_DECODE_ASCII(dut.m_stimulus.machine_code[dut.m_cpu->o_pcOut >> 2].c_str());
        dut.m_cpu->i_dataIn     = dut.m_cpu->o_loadReq ? readMem(cpu(&dut)->o_dataAddr, testMem) : 0xffffffff;
        dut.m_cpu->i_ifValid    = 1;
        dut.m_cpu->i_memValid   = 1;
        if (dut.m_cpu->o_storeReq) { writeMem(cpu(&dut)->o_dataAddr, testMem, cpu(&dut)->o_dataOut); }
        done = dut.readRegfile(doneReg) == simDoneVal;
        // Evaluate
        dut.tick();
    }

    // Check results
    EXPECT_EQ(dut.readRegfile(22 /*s6*/ ), fibonacci(6));
    EXPECT_EQ(dut.readRegfile(23 /*s7*/ ), fibonacci(7));
    EXPECT_EQ(dut.readRegfile(24 /*s8*/ ), fibonacci(8));
    EXPECT_EQ(dut.readRegfile(25 /*s9*/ ), fibonacci(9));
    EXPECT_EQ(dut.readRegfile(26 /*s10*/), fibonacci(10));
}