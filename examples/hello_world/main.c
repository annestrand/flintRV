#include <stdio.h>

// Entry point
void _risa_start(void) {
    asm("jal _start");
    for (;;)
        ;
}

// Main program
int main(void) {
    printf("Hello World!\n");
    return 0;
}
