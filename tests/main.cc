// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include "drop32.h"
#include <gtest/gtest.h>

int g_dumpLevel = 0;

int main(int argc, char *argv[]) {
    // Parse any passed option(s)
    for (int i = 0; i < argc; ++i) {
        std::string s(argv[i]);
        if (s.find("-v") != std::string::npos) {
            printf("%s\n", DROP32_VERSION);
            return 0;
        }
        if (s.find("-h") != std::string::npos) {
            printf("%s\n", "Vdrop32_tests option(s):\n"
                           "    -h         : Prints help and exits\n"
                           "    -v         : Prints version and exits\n"
                           "    -dump      : Prints disassembled instruction\n"
                           "    -dump-all  : Prints disassembled instruction + "
                           "CPU state\n");
            return 0;
        }
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
