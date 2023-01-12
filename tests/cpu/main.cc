// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <gtest/gtest.h>
#include "drop32.hh"

int g_dumpLevel = 0;

int main(int argc, char *argv[]) {
    // Parse any passed option(s)
    // | -dump      : Prints disassembled instruction
    // | -dump-all  : Prints disassembled instruction + CPU state
    for (int i=0; i<argc; ++i) {
        std::string s(argv[i]);
        if (s.find("-dump") != std::string::npos) {
            g_dumpLevel = g_dumpLevel > 0 ? g_dumpLevel : 1;
        }
        if (s.find("-dump-all") != std::string::npos) {
            g_dumpLevel = g_dumpLevel > 1 ? g_dumpLevel : 2;
        }
    }
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
