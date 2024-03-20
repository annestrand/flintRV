// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include "Vdrop32/drop32.h"
#include <gtest/gtest.h>

bool g_testTracing = false;

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
                           "    -h             : Prints help and exits\n"
                           "    -v             : Prints version and exits\n"
                           "    --tracing      : Prints disassembled "
                           "instructions + CPU state\n");
            return 0;
        }
        if (s.find("--tracing") != std::string::npos) {
            g_testTracing = true;
        }
    }
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
