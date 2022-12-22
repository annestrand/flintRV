// Copyright (c) 2022 Austin Annestrand
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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