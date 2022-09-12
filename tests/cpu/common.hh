#pragma once

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#define HEX_DECODE_ASCII(in) strtol(in, NULL, 16)
#define INT_DECODE_ASCII(in) strtol(in, NULL, 10)

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define LOG_I(msg, ...) \
    printf("[INFO ]:[%s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_W(msg, ...) \
    printf("[WARN ]:[%s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_E(msg, ...) \
    printf("[ERROR]:[%s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)

std::vector<std::string> asmFileReader(std::string filePath);
std::vector<std::string> initRegfileReader(std::string filePath);
std::string disassembleRv32i(unsigned int instr);
bool loadMem(std::string filePath, char* mem, ssize_t memLen);