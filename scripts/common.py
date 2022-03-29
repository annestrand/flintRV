#! /usr/bin/env python3

import os
import random
from enum import Enum

class Imm32Ranges(Enum):
    I_MIN    = -((2**12)//2)
    I_MAX    = ((2**12)//2)-1
    # Unsigned max
    I_MAX_U  = 2**12

    UJ_MIN   = -((2**20)//2)
    UJ_MAX   = ((2**20)//2)-1
    # Unsigned max
    UJ_MAX_U = 2**20

class Int16Range(Enum):
    MIN16 = -((2**16))
    MAX16 = ((2**16))-1

def basenameNoExt(outputBaseDir, file):
    '''My testgen scripts use double extensions for naming - helper function for just getting name with no extension'''
    return os.path.join(outputBaseDir, os.path.splitext(os.path.splitext(os.path.basename(file))[0])[0])

def randImmI():
    return random.randint(Imm32Ranges.I_MIN.value//2, Imm32Ranges.I_MAX.value//2)
def randShamt():
    return random.randint(0,31)
def randImmU():
    return random.randint(0, Imm32Ranges.UJ_MAX_U.value//2)
def randReg(x0=False):
    return random.randint(0,31) if x0 else random.randint(1,31)
