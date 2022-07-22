#pragma once

#include <cstdio>
#include <string>
#include <vector>

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define LOG_TAG "boredcore"
#define LOG_I(msg, ...) \
    printf("[INFO ]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)
#define LOG_W(msg, ...) \
    printf("[WARN ]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)
#define LOG_E(msg, ...) \
    printf("[ERROR]:[%14s]:[%6d]:[%14s] - " msg, __FILENAME__, __LINE__, __func__, ##__VA_ARGS__)

void endianFlipper(std::vector<std::string>& machineCode);
void leftTrimWhitespace(std::string& s);
std::vector<std::string> machineCodeFileReader(std::string filePath);
std::vector<std::string> asmFileReader(std::string filePath);