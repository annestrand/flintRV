#! /usr/bin/env python3

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
