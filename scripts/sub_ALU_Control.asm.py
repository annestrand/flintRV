#! /usr/bin/env python3

from common import *

# Try each immediate-based RV32I instruction with random operands as the test vector
test_assembly = f'''
L1:     lb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
        fence                                                                           # ADD
L6:     addi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # ADD
L19:    auipc   x{randReg(x0=False)},  {randImmU()}                                     # ADD
L15:    sb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
        add     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # ADD
L18:    lui     x{randReg(x0=False)},  {randImmU()}                                     # PASSB
        beq     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # EQ
L0:     jalr    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # ADD4A
L20:    jal     x{randReg(x0=False)}, L{random.randint(0,20)}                           # ADD4A
        ecall                                                                           # ADD
L2:     lh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
L12:    slli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}               # SLL
L16:    sh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
        sll     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SLL
        bne     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # NEQ
L3:     lw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
L7:     slti    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # SLT
L17:    sw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
        slt     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SLT
L8:     sltiu   x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # SLTU
        sltu    x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SLTU
L4:     lbu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
L9:     xori    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # XOR
        xor     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # XOR
        blt     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # SLT
L5:     lhu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})               # ADD
L13:    srli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}               # SRL
        srl     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SRL
        bge     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # SGTE
L10:    ori     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # OR
        or      x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # OR
        bltu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # SLTU
L11:    andi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}                # AND
        and     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # AND
        bgeu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}     # SGTEU
        ebreak                                                                          # ADD
        sub     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SUB
L14:    srai    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}               # SRA
        sra     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}         # SRA
'''

test_gold = getComments(test_assembly)

if __name__ == "__main__":
    # Input test vector
    outfile = f"{basenameNoExt(parseArgv(sys.argv).outDir, __file__)}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)

    outfileGold = f"{basenameNoExt(parseArgv(sys.argv).outDir, __file__)}_gold.mem"
    with open(outfileGold, 'w') as fp:
        for x in test_gold:
            print(f"{AluTypes[x[2:]].value:05b}", file=fp)
