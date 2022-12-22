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

#include <stddef.h>

void _start(void);
void _drop32_start(void) {
    _start();
    for(;;);
}

int fibonacci(int x) {
    if (x <= 1) { return x; }
    return fibonacci(x - 1) + fibonacci(x - 2);
}

// ====================================================================================================================
int main(void) {
    int test_6                      = fibonacci(6);
    int test_7                      = fibonacci(7);
    int test_8                      = fibonacci(8);
    int test_9                      = fibonacci(9);
    int test_10                     = fibonacci(10);
    // Write results directly to CPU regs and signal to Simulation that we are done
    register long s6  asm("s6")     = test_6;
    register long s7  asm("s7")     = test_7;
    register long s8  asm("s8")     = test_8;
    register long s9  asm("s9")     = test_9;
    register long s10 asm("s10")    = test_10;
    asm("ebreak");
    return 0;
}
