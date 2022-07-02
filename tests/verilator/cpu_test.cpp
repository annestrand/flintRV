#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vboredcore.h"
#include "Vboredcore__Syms.h"

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vboredcore *dut = new Vboredcore;

    // VCD file setup
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("obj_dir/waveform.vcd");

    // Simulation loop
    constexpr int max_sim_time = 200;
    vluint64_t sim_time = 0;
    while (sim_time < max_sim_time) {
        // Initial reset
        if (sim_time == 1) {
            dut->rst = 1;
        } else {
            dut->rst = 0;
        }

        // Pulse clk
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    // Cleanup
    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
