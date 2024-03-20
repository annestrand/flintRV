// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <stddef.h>

void _start(void);
void _drop32_start(void) {
    _start();
    for (;;)
        ;
}

int binsearch(int val, int *arr, int len) {
    int left = 0;
    int right = len - 1;
    while (left <= right) {
        int mid = (left + right) / 2;
        if (arr[mid] < val) {
            left = mid + 1;
        } else if (arr[mid] > val) {
            right = mid - 1;
        } else {
            return mid;
        }
    }
    return -1;
}

int main(void) {
    int testArr[] = {3,   6,   23,  26,  45,  52,  53,  56,  57,  59,  71,  90,
                     106, 107, 108, 114, 118, 121, 124, 135, 137, 145, 150, 152,
                     154, 156, 163, 164, 166, 168, 172, 175, 177, 180, 182, 184,
                     193, 197, 201, 208, 211, 215, 220, 229, 235, 238, 239, 241,
                     242, 248, 259, 268, 269, 270, 283, 284, 290, 295, 301, 313,
                     319, 324, 325, 327, 328, 337, 343, 360, 365, 366, 369, 371,
                     373, 385, 386, 387, 390, 393, 401, 405, 409, 412, 416, 419,
                     424, 426, 427, 439, 449, 452, 454, 455, 468, 469, 471, 478,
                     481, 482, 484, 499};
    int testArrLen = sizeof(testArr) / sizeof(int);

    // Test-out 3 values that exist in testArr and 1 non-existent value in
    // testArr
    int exists1 = binsearch(478, testArr, testArrLen) >= 0 ? 1 : 0;
    int exists2 = binsearch(90, testArr, testArrLen) >= 0 ? 1 : 0;
    int exists3 = binsearch(313, testArr, testArrLen) >= 0 ? 1 : 0;
    int notExist = binsearch(670, testArr, testArrLen) >= 0 ? 1 : 0;
    // Write results directly to CPU regs and signal to Simulation that we are
    // done
    register long s1 asm("s1") = exists1;  // Should be (1)
    register long s2 asm("s2") = exists2;  // Should be (1)
    register long s3 asm("s3") = exists3;  // Should be (1)
    register long s4 asm("s4") = notExist; // Should be (0)
    asm("ebreak");
    return 0;
}
