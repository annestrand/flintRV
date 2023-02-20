// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#pragma once

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#define HEX_DECODE_ASCII(in) strtol(in, NULL, 16)
#define INT_DECODE_ASCII(in) strtol(in, NULL, 10)

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define LOG_I(msg, ...) \
    printf("[Vdrop32 - Info ]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_W(msg, ...) \
    printf("[Vdrop32 - WARN ]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)
#define LOG_E(msg, ...) \
    printf("[Vdrop32 - ERROR]:[%16s:%d] - " msg, __FILENAME__, __LINE__, ##__VA_ARGS__)

std::string disassembleRv32i(unsigned int instr);
bool loadMem(std::string filePath, char* mem, ssize_t memLen);