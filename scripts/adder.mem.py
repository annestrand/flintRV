#! /usr/bin/env python3

from common import *

n_vectors           = 32
test_vector_a       = [randImmI() for x in range(n_vectors)]
test_vector_b       = [randImmI() for x in range(n_vectors)]
test_vector_subEn   = [random.randint(0,1) for x in range(n_vectors)]

if __name__ == "__main__":
    outfile = f"{basenameNoExt('build', __file__)}.mem"
    with open(outfile, 'w') as fp:
        for i in range(n_vectors):
            test_vector  = f"{test_vector_a[i]       & 0xffffffff:032b}"
            test_vector += f"{test_vector_b[i]       & 0xffffffff:032b}"
            test_vector += f"{test_vector_subEn[i]   & 0x1:01b}"
            print(test_vector, file=fp)

    outfileGold = f"{basenameNoExt('build', __file__)}_gold.mem"
    with open(outfileGold, 'w') as fp:
        for i in range(n_vectors):
            if test_vector_subEn[i] == 0:
                test_vector = f"{(test_vector_a[i] + test_vector_b[i]) & 0xffffffff:032b}"
                print(test_vector, file=fp)
            else:
                test_vector = f"{(test_vector_a[i] - test_vector_b[i]) & 0xffffffff:032b}"
                print(test_vector, file=fp)
