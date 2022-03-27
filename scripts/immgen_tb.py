#! /usr/bin/env python3

import os
import random
from common import Imm32Ranges

randImmI = random.randint(Imm32Ranges.I_MIN.value//2, Imm32Ranges.I_MAX.value//2)
randImmU = random.randint(Imm32Ranges.UJ_MIN.value//2, Imm32Ranges.UJ_MAX.value//2)

# Try each immediate-based RV32I instruction with random operands
test_assembly = f'''
    jalr    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
    lb      x{random.randint(1,31)}, {randImmI}({random.randint(1,31)})
    addi    x{random.randint(1,31)}, x{random.randint(1,31)}, {randImmI}
'''

if __name__ == "__main__":
    outfile = f"{os.path.join('build', os.path.basename(__file__))}.s"
    with open(outfile, 'w') as fp:
        print(test_assembly, file=fp)
