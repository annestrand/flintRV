#! /usr/bin/env python3

from common import *

# Try each immediate-based RV32I instruction with random operands as the test vector
test_assembly = f'''
# Note: Instruction order also has to be same as "instr.vh" file

L1:     lb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
        fence
L6:     addi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L19:    auipc   x{randReg(x0=False)},  {randImmU()}
L15:    sb      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
        add     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
L18:    lui     x{randReg(x0=False)},  {randImmU()}
        beq     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
L0:     jalr    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L20:    jal     x{randReg(x0=False)}, L{random.randint(0,20)}
        ecall
L2:     lh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L12:    slli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
L16:    sh      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
        sll     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
        bne     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
L3:     lw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L7:     slti    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
L17:    sw      x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
        slt     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
L8:     sltiu   x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
        sltu    x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
L4:     lbu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L9:     xori    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
        xor     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
        blt     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
L5:     lhu     x{randReg(x0=False)},  {randImmI()}(x{randReg(x0=False)})
L13:    srli    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
        srl     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
        bge     x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
L10:    ori     x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
        or      x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
        bltu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
L11:    andi    x{randReg(x0=False)}, x{randReg(x0=False)}, {randImmI()}
        and     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
        bgeu    x{randReg(x0=False)}, x{randReg(x0=False)}, L{random.randint(0,20)}
        ebreak
        sub     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
L14:    srai    x{randReg(x0=False)}, x{randReg(x0=False)}, {randShamt()}
        sra     x{randReg(x0=False)}, x{randReg(x0=True)} , x{randReg(x0=True)}
'''

if __name__ == "__main__":
    # Input test vector
    outfile = f"{basenameNoExt('build', __file__)}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)
