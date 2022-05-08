#! /usr/bin/env python3

from common import *

test_vector_a       = [randImmI() for x in range(2**4)]
test_vector_b       = [
    randShamt() if x    in [AluTypes.SLL.value,AluTypes.SRL.value,AluTypes.SRA.value]
    else 4 if x         in [AluTypes.ADD4A.value]
    else randImmI()     for x in range(2**4)
]
test_vector_op      = [x for x in range(2**4)]

if __name__ == "__main__":
    outfile = f"{basenameNoExt('build', __file__)}.mem"
    with open(outfile, 'w') as fp:
        for i in range(2**4):
            test_vector  = f"{test_vector_a[i]  & 0xffffffff:032b}"
            test_vector += f"{test_vector_b[i]  & 0xffffffff:032b}"
            test_vector += f"{test_vector_op[i] & 0xf:05b}"
            print(test_vector, file=fp)

    outfileGold = f"{basenameNoExt('build', __file__)}_gold.mem"
    with open(outfileGold, 'w') as fp:
        for i in range(2**4):
            val = 0
            if test_vector_op[i] == AluTypes.ADD.value:
                val = (test_vector_a[i] + test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.SUB.value:
                val = (test_vector_a[i] - test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.SLL.value:
                val = (test_vector_a[i] << test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.XOR.value:
                val = (test_vector_a[i] ^ test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.SRL.value:
                val = ((test_vector_a[i] & 0xffffffff) >> (test_vector_b[i] & 0xffffffff))
            elif test_vector_op[i] == AluTypes.SRA.value:
                val = (test_vector_a[i] >> test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.OR.value:
                val = (test_vector_a[i] | test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.AND.value:
                val = (test_vector_a[i] & test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.PASSB.value:
                val = (test_vector_b[i]) & 0xffffffff
            elif test_vector_op[i] == AluTypes.ADD4A.value:
                val = (test_vector_a[i] + 4) & 0xffffffff
            elif test_vector_op[i] == AluTypes.EQ.value:
                val = (test_vector_a[i] == test_vector_b[i])
            elif test_vector_op[i] == AluTypes.NEQ.value:
                val = (test_vector_a[i] != test_vector_b[i])
            elif test_vector_op[i] == AluTypes.SLT.value:
                val = (test_vector_a[i] < test_vector_b[i])
            elif test_vector_op[i] == AluTypes.SLTU.value:
                val = (test_vector_a[i] & 0xffffffff) < (test_vector_b[i] & 0xffffffff)
            elif test_vector_op[i] == AluTypes.SGTE.value:
                val = (test_vector_a[i] >= test_vector_b[i])
            elif test_vector_op[i] == AluTypes.SGTEU.value:
                val = (test_vector_a[i] & 0xffffffff) >= (test_vector_b[i] & 0xffffffff)
            # Write gold vector
            test_vector  = f"{val:032b}"
            test_vector += f"{1 if val == 0 else 0:01b}"
            print(test_vector, file=fp)