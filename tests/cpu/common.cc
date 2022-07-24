#include <iostream>
#include <string>
#include <fstream>
#include <sstream>

#include "common.hh"

// ====================================================================================================================
void endianFlipper(std::vector<std::string>& machineCode) {
    for (auto it = machineCode.begin(); it != machineCode.end(); ++it) {
        std::string item = *it;
        item = item.substr(6,2) + item.substr(4,2) + item.substr(2,2) + item.substr(0,2);
        machineCode[it-machineCode.begin()] = item;
    }
}
// ====================================================================================================================
void leftTrimWhitespace(std::string& s) {
    s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
}
// ====================================================================================================================
std::vector<std::string> machineCodeFileReader(std::string filePath) {
    std::vector<std::string> contents;
    std::ifstream f(filePath);
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", filePath.c_str());
        return contents;
    }
    std::string line;
    while (std::getline(f, line)) {
        std::string item;
        std::stringstream ss(line);
        while (ss >> item) {
            contents.push_back(item);
        }
    }
    f.close();
    for (auto it = contents.begin(); it != contents.end(); ++it) {
        if (it->find("@") != std::string::npos) {
            contents.erase(it);
        }
    }
    return contents;
}
// ====================================================================================================================
std::vector<std::string> asmFileReader(std::string filePath) {
    std::vector<std::string> contents;
    std::ifstream f(filePath);
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", filePath.c_str());
        return contents;
    }
    std::string line;
    while (std::getline(f, line)) {
        leftTrimWhitespace(line);
        // Skip line if it starts off as a code comment
        if (line.find("#") != std::string::npos && line.find("#") == 0) {
            continue;
        }
        contents.push_back(line);
    }
    f.close();
    return contents;
}
// ====================================================================================================================
std::vector<std::string> initRegfileReader(std::string filePath) {
    std::vector<std::string> contents;
    std::ifstream f(filePath);
    if (!f) {
        LOG_E("Failed reading from: [ %s ]", filePath.c_str());
        return contents;
    }
    std::string line;
    while (std::getline(f, line)) {
        leftTrimWhitespace(line);
        contents.push_back(line);
    }
    f.close();
    return contents;
}