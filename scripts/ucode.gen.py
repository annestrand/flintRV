#! /usr/bin/env python3

import sys
import argparse
from enum import IntEnum

class AluOp(IntEnum):
    ADD      = 0b0000
    SUB      = 0b0001
    AND      = 0b0010
    OR       = 0b0011
    XOR      = 0b0100
    SLL      = 0b0101 # Shift Left Logically
    SRL      = 0b0110 # Shift Right Logically
    SRA      = 0b0111 # Shift Right Arithmetically
    EQUAL    = 0b1000
    NEQUAL   = 0b1001
    SLT      = 0b1010 # Set if Less Than
    SLTU     = 0b1011 # Set if Less Than (Unsigned)
    SGTE     = 0b1100 # Set if Greater Than or Equal
    SGTEU    = 0b1101 # Set if Greater Than or Equal (Unsigned)
    PASS_B   = 0b1110 # Pass the B input to output
    ADD4_A   = 0b1111 # Add 4 to A input

class AluA(IntEnum):
    FROM_RS1    = 0b0
    FROM_PC     = 0b1

class AluB(IntEnum):
    FROM_RS2    = 0b0
    FROM_IMM    = 0b1

# =====================================================================================================================

class UCode(object):
    def __init__(self, instrName, encoding, opType, uCode):
        self.instrName  = instrName
        self.opType     = opType
        self.encoding   = encoding
        self.uCode      = uCode

class UCodeCtrl(object):
    def __init__(self):
        self.r_type_op_space    = [True]*(2**17)
        #self.op_space           = [True]*(2**10)
        # Pre-init RV32I uCodes
        self.UCodes = [
            UCode('ADD',    '0b_0000000_000_0110011', 'r', None),
            UCode('SUB',    '0b_0100000_000_0110011', 'r', None),
            UCode('SLL',    '0b_0000000_001_0110011', 'r', None),
            UCode('SLT',    '0b_0000000_010_0110011', 'r', None),
            UCode('SLTU',   '0b_0000000_011_0110011', 'r', None),
            UCode('XOR',    '0b_0000000_100_0110011', 'r', None),
            UCode('SRL',    '0b_0000000_101_0110011', 'r', None),
            UCode('SRA',    '0b_0100000_101_0110011', 'r', None),
            UCode('OR',     '0b_0000000_110_0110011', 'r', None),
            UCode('AND',    '0b_0000000_111_0110011', 'r', None),
            UCode('JALR',   '0b_0000000_000_1100111', 'i', None),
            UCode('LB',     '0b_0000000_000_0000011', 'i', None),
            UCode('LH',     '0b_0000000_001_0000011', 'i', None),
            UCode('LW',     '0b_0000000_010_0000011', 'i', None),
            UCode('LBU',    '0b_0000000_100_0000011', 'i', None),
            UCode('LHU',    '0b_0000000_101_0000011', 'i', None),
            UCode('ADDI',   '0b_0000000_000_0010011', 'i', None),
            UCode('SLTI',   '0b_0000000_010_0010011', 'i', None),
            UCode('SLTIU',  '0b_0000000_011_0010011', 'i', None),
            UCode('XORI',   '0b_0000000_100_0010011', 'i', None),
            UCode('ORI',    '0b_0000000_110_0010011', 'i', None),
            UCode('ANDI',   '0b_0000000_111_0010011', 'i', None),
            UCode('FENCE',  '0b_0000000_000_0001111', 'i', None),
            UCode('ECALL',  '0b_0000000_000_1110011', 'i', None),
            UCode('SLLI',   '0b_0000000_001_0010011', 'i', None),
            UCode('SRLI',   '0b_0000000_101_0010011', 'i', None),
            UCode('SRAI',   '0b_0100000_101_0010011', 'i', None),
            UCode('EBREAK', '0b_0000001_000_1110011', 'i', None),
            UCode('SB',     '0b_0000000_000_0100011', 's', None),
            UCode('SH',     '0b_0000000_001_0100011', 's', None),
            UCode('SW',     '0b_0000000_010_0100011', 's', None),
            UCode('BEQ',    '0b_0000000_000_1100011', 'b', None),
            UCode('BNE',    '0b_0000000_001_1100011', 'b', None),
            UCode('BLT',    '0b_0000000_100_1100011', 'b', None),
            UCode('BGE',    '0b_0000000_101_1100011', 'b', None),
            UCode('BLTU',   '0b_0000000_110_1100011', 'b', None),
            UCode('BGEU',   '0b_0000000_111_1100011', 'b', None),
            UCode('LUI',    '0b_0000000_000_0110111', 'u', None),
            UCode('AUIPC',  '0b_0000000_000_0010111', 'u', None),
            UCode('JAL',    '0b_0000000_000_1101111', 'j', None),
        ]
        self.UCodes.sort(key=lambda x: x.encoding)

    def listInstructions(self):
        for ucode in self.UCodes:
            instr_name  = f"{ucode.instrName:<12}"
            instr_enc   = f"{ucode.encoding}"
            print(f"{instr_name}: {instr_enc}")

# =====================================================================================================================
if __name__ == "__main__":
    # Define args/opts
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--dump", "-d", action="store_true", help="Emit the microcode to [ ucode_gen.dat ].")
    args, unknown = parser.parse_known_args()
    if len(unknown) != 0:
        print(f"{__file__}- Error]: Unknown argument(s)/option(s):\n{unknown}\n")
        parser.print_help()
        exit(0)

    # Begin
    ucode = UCodeCtrl()
    ucode.listInstructions()
    print("\n[Done].")