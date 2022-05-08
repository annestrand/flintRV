#! /usr/bin/env python3

from common import *

# Nonsensical test program for now
test_assembly = f'''
        addi x6, x7, 5
        xori x8, x6, 15
        add  x4, x0, x0
        add  x5, x0, x0
        addi x5, x0, 10
LOOP:   addi x8, x8, 1
        addi x4, x4, 1
        bne  x4, x5, LOOP
STALL:  jal  x2, STALL
'''

if __name__ == "__main__":
    # Input test vector
    outfile = f"{basenameNoExt('build', __file__)}.s"
    with open(outfile, 'w') as fp:
        asmList = asmStr2AsmList(test_assembly)
        test_assembly = f"# [Instruction Count]: {len(asmList)}\n" + test_assembly
        print(test_assembly, file=fp)
