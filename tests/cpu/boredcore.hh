#pragma once

#include <cstdio>
#include <verilated_vcd_c.h>

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define LOG_TAG "boredcore"
#define LOG_I(msg, ...) \
    printf("[INFO ]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)
#define LOG_W(msg, ...) \
    printf("[WARN ]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)
#define LOG_E(msg, ...) \
    printf("[ERROR]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)

class simulation {
public:
    simulation(vluint64_t maxSimTime);
    ~simulation();
    bool create(Vboredcore* cpu, const char* traceFile);
    void reset(int count=1);
    void tick();
    bool end();

private:
    vluint64_t              m_cycles;
    VerilatedVcdC*          m_trace;
    vluint64_t              m_maxSimTime;
    Vboredcore*             m_cpu; // Reference to CPU object
};