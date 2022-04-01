#! /usr/bin/env python3

import os
import random
from enum import Enum
from typing import List

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

def asmStr2AsmList(asmStr:str):
    '''Converts multi-line assembly string to a list of assembly lists'''
    asmStr =    asmStr.split('\n')
    asmStr =    [x.strip(' ') for x in asmStr]
    asmStr =    [x for x in asmStr if x]
    asmStr =    [x.replace(':', ': ') for x in asmStr if x]
    asmStr =    [x.replace('#', ' # ') for x in asmStr if x]
    asmStr =    [x for x in asmStr if x]
    asmStr =    [x.split(' ') for x in asmStr]
    asmStr =    [[y for y in x if y] for x in asmStr]
    asmStr =    [x for x in asmStr if x[0][0] != '#']
    asmStr =    [x[0:x.index('#')] if '#' in x else x for x in asmStr]
    asmStr =    [x[1:] if ':' in x[0] else x for x in asmStr]
    asmStr =    [x for x in asmStr if x]
    return      [[y.replace(',', '') for y in x] for x in asmStr]

def getOperandVals(asmList:List[List[str]]):
    '''Takes "asmList" from asmStr2AsmList() and returns only operand values from asmList'''
    operandList = [x[1:] for x in asmList]
    return operandList

def randImmI():
    return random.randint(Imm32Ranges.I_MIN.value//2, Imm32Ranges.I_MAX.value//2)
def randShamt():
    return random.randint(0,31)
def randImmU():
    return random.randint(0, Imm32Ranges.UJ_MAX_U.value//2)
def randReg(x0=False):
    return random.randint(0,31) if x0 else random.randint(1,31)
