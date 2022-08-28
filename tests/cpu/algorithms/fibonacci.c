#include <stddef.h>

int main (void);
void _start(void) {
    asm (
        "la sp, __stack_top\n\t"
        "add s0, sp, zero\n\t"
        "jal main\n\t"
        "STALL: j STALL\n\t"
        "nop\n\t"
        "nop\n\t"
        "nop\n\t"
        "nop\n\t"
    );
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
    register long s11 asm("s11")    = -1; // Done.
    return 0;
}
