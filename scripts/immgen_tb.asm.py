#! /usr/bin/env python3

from common import *

# Try each immediate-based RV32I instruction with random operands as the test vector
test_assembly = f'''
    jalr    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    lb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    lh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    lw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    lbu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    lhu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    addi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    slti    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    sltiu   x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    xori    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    ori     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    andi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    slli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
    srli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
    srai    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
    sb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    sh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    sw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
    beq     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    bne     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    blt     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    bge     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    bltu    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    bgeu    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
    lui     x{randReg(x0=False)},  {randImmU()}
    auipc   x{randReg(x0=False)},  {randImmU()}
'''
test_gold = test_assembly

if __name__ == "__main__":
    # Input test vector
    outfile = f"{basenameNoExt('build', __file__)}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)

    # Output/gold test vector
    test_gold = test_gold.split('\n')
    test_gold = [x.strip(' ') for x in test_gold]
    test_gold = [x for x in test_gold if x]
    test_gold = [x.split(' ') for x in test_gold]
    test_gold = [[y for y in x if y][1:] for x in test_gold]
    outfileGold = f"{basenameNoExt('build', __file__)}.gold.mem"
    with open(outfileGold, 'w') as fp:
        for gold in test_gold:
            if len(gold) == 3:
                imm = gold[2]
                print(f"{int(imm) & 0xffffffff:08x}", file=fp)
            else:
                if '(' in gold[1]:
                    imm = gold[1].split('(')[0]
                    print(f"{int(imm) & 0xffffffff:08x}", file=fp)
                else:
                    imm = gold[1]
                    print(f"{int(imm) & 0xffffffff:08x}", file=fp)
