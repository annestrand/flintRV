// Copyright (c) 2024 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <stdio.h>
#include <string.h>

typedef struct ParsedArgs_s {
    int used1;
    int used2;
    int used3;
} ParsedArgs;

void _start(void);
void _flintRV_start(void) {
    _start();
    for (;;)
        ;
}

ParsedArgs returnParsedArgs(int argc, char **argv) {
    ParsedArgs parsedArgs = {0};
    for (int i = 0; i < argc; ++i) {
        if (strcmp(argv[i], "hello") == 0) {
            parsedArgs.used1 = 1;
        }
        if (strcmp(argv[i], "world!") == 0) {
            parsedArgs.used2 = 1;
        }
        if (strcmp(argv[i], "other") == 0) {
            parsedArgs.used1 = 1;
        }
    }
    return parsedArgs;
}

int paramSizes(void *a, long b, int c, short d, char e) {
    return sizeof(a) + sizeof(b) + sizeof(c) + sizeof(d) + sizeof(e);
}

int factorial(int x) {
    if (x == 1) {
        return 1;
    }
    return x * factorial(x - 1);
}

int main(void) {
    int result1 = factorial(3);
    int result2 = factorial(6);
    int result3 = factorial(9);

    void *testPtr = NULL;
    int result4 =
        paramSizes(testPtr, (long)1000000, (int)10000, (short)1000, (int)100);

    int argc = 6;
    char *argv[] = {"-h", "world!", "", "--Value", "hello", " "};
    ParsedArgs parsedArgs = returnParsedArgs(argc, argv);
    int result5 = parsedArgs.used1;
    int result6 = parsedArgs.used2;
    int result7 = parsedArgs.used3;

    // Write results directly to CPU regs and signal to Simulation that we
    // are done
    register long s1 asm("s1") = result1; // Should be (6)
    register long s2 asm("s2") = result2; // Should be (720)
    register long s3 asm("s3") = result3; // Should be (362880)
    register long s4 asm("s4") = result4; // Should be (15)
    register long s5 asm("s5") = result5; // Should be (1)
    register long s6 asm("s6") = result6; // Should be (1)
    register long s7 asm("s7") = result7; // Should be (0)
    asm("ebreak");
    return 0;
}
