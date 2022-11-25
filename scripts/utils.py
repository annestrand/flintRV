#! /usr/bin/env python3

import os
import argparse
from enum import Enum
from typing import *

class Imm32Ranges(Enum):
    I_MIN    = -((2**12)//2)
    I_MAX    = ((2**12)//2)-1
    # Unsigned max
    I_MAX_U  = 2**12

    UJ_MIN   = -((2**20)//2)
    UJ_MAX   = ((2**20)//2)-1
    # Unsigned max
    UJ_MAX_U = 2**20

def parseArgv(argv):
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("-out", dest="outDir", default="obj_dir/sub", help="Output directory.")
    args, unknown = parser.parse_known_args(args=argv)
    return args

def basenameNoExt(outputBaseDir, file):
    '''My testgen scripts use double extensions for naming - helper function for just getting name with no extension'''
    return os.path.join(outputBaseDir, os.path.splitext(os.path.splitext(os.path.basename(file))[0])[0])
