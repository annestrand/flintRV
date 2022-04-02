#! /usr/bin/env python3

from common import *

# Try each immediate-based RV32I instruction with random operands as the test vector
test_assembly = f'''
# Need to use (L#) for jump labels here to later get imm. value from for gold vector
L0:     jalr    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L1:     lb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L2:     lh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L3:     lw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L4:     lbu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L5:     lhu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L6:     addi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L7:     slti    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L8:     sltiu   x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L9:     xori    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L10:    ori     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L11:    andi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L12:    slli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
L13:    srli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
L14:    srai    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
L15:    sb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L16:    sh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L17:    sw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L18:    lui     x{randReg(x0=False)},  {randImmU()}
L19:    auipc   x{randReg(x0=False)},  {randImmU()}
L20:    jal     x{randReg(x0=False)},  L{random.randint(0,20)}
        beq     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        bne     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        blt     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        bge     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        bltu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        bgeu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
'''

if __name__ == "__main__":
    # Input test vector
    outfile = f"{basenameNoExt('build', __file__)}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)

    # Output/gold test vector
    outfileGold = f"{basenameNoExt('build', __file__)}.gold.mem"
    test_gold   = asmStr2AsmList(test_assembly)
    with open(outfileGold, 'w') as fp:
        lineCount = 0
        for gold in test_gold:
            if len(gold) == 4:
                imm = gold[3] if 'b' not in gold[0] else (int(gold[3][1:]) - lineCount)*4
                print(f"{int(imm) & 0xffffffff:032b}", file=fp)
            else:
                if '(' in gold[2]:
                    imm = gold[2].split('(')[0]
                    print(f"{int(imm) & 0xffffffff:032b}", file=fp)
                else:
                    imm = gold[2] if 'j' not in gold[0] else (int(gold[2][1:]) - lineCount)*4
                    if 'lui' == gold[0] or 'auipc' == gold[0]:
                        print(f"{((int(imm) & 0xffffffff) << 12):032b}", file=fp)
                    else:
                        print(f"{int(imm) & 0xffffffff:032b}", file=fp)
            lineCount += 1
