#! /usr/bin/env python3

import os
import random
from common import Imm32Ranges

randImmI    = random.randint(Imm32Ranges.I_MIN.value//2, Imm32Ranges.I_MAX.value//2)
randImmU    = random.randint(0, Imm32Ranges.UJ_MAX_U.value//2)
randShamt   = random.randint(0,31)
randBranch  = random.randint(-20, 0) * 4

# Try each immediate-based RV32I instruction with random operands as the test vector
test_assembly = f'''
    jalr    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    lb      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    lh      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    lw      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    lbu     x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    lhu     x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    addi    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    slti    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    sltiu   x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    xori    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    ori     x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    andi    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    slli    x{random.randint(1,31)}, x{random.randint(1,31)}, {randShamt}
    srli    x{random.randint(1,31)}, x{random.randint(1,31)}, {randShamt}
    srai    x{random.randint(1,31)}, x{random.randint(1,31)}, {randShamt}
    sb      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    sh      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    sw      x{random.randint(1,31)}, {randImmI}(x{random.randint(1,31)})
    beq     x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    bne     x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    blt     x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    bge     x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    bltu    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    bgeu    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    lui     x{random.randint(1,31)}, {randImmU}
    auipc   x{random.randint(1,31)}, {randImmU}
'''

if __name__ == "__main__":
    outfile = f"{os.path.join('build', os.path.splitext(os.path.basename(__file__))[0])}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)
