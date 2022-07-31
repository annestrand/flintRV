#! /usr/bin/env python3

import random

from math import log
from common import *

jumpTestProgram    = f'''
    # --- Jump/Branch tests ---
    #   (Fails if x30 is non-zero)
        addi  x30, x30, 1
        add   x0, x0, x0    # NOP
        addi  x30, x30, 1
        jal   x0, L0
        add   x0, x0, x0
        jal   x0, FAIL
    L0: addi x30, x30, 1
        jalr  x0, x0, 32    # Jump to: (8th instruction * 4) + 0 = 32
        jal   x0, FAIL
        addi  x30, x30, 1
        beq   x0, x0, L1
        jal   x0, FAIL
    L1: addi  x30, x30, 1
        bne   x0, x30, L2
        jal   x0, FAIL
    L2: addi  x30, x30, 1
        blt   x0, x30, L3
        jal   x0, FAIL
    L3: addi  x30, x30, 1
        bge   x30, x0, L4
        jal   x0, FAIL
    L4: addi  x30, x30, 1
        bltu  x0, x30, L5
        jal   x0, FAIL
    L5: addi  x30, x30, 1
        bgeu  x30, x0, L6
        jal   x0, FAIL
    L6: addi  x30, x30, 1
        jal   x0, STALL

    FAIL:   addi x13, x0, -1  # DONE
            addi x14, x0, 15
            add  x31, x0, x30
    STALL:  addi x13, x0, -1  # DONE
            jal  x0, STALL
            # Add some NOP padding
            nop
            nop
            nop
            nop
'''

if __name__ == "__main__":
    # Input test vectors
    outfile = f"{basenameNoExt(parseArgv(sys.argv).outDir, __file__)}.s"
    with open(outfile, 'w') as fp:
        print(jumpTestProgram, file=fp)