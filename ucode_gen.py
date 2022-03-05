import sys
from enum import IntEnum

# RISC-V RV32I base instructions
class Rv32iInstructions(IntEnum):
    # [R-type]: (funt7)             | (funct3)      | (opcode)
    ADD     =   (0b0000000 << 10)   | (0b000 << 7)  | (0b0110011)
    SUB     =   (0b0100000 << 10)   | (0b000 << 7)  | (0b0110011)
    SLL     =   (0b0000000 << 10)   | (0b001 << 7)  | (0b0110011)
    SLT     =   (0b0000000 << 10)   | (0b010 << 7)  | (0b0110011)
    SLTU    =   (0b0000000 << 10)   | (0b011 << 7)  | (0b0110011)
    XOR     =   (0b0000000 << 10)   | (0b100 << 7)  | (0b0110011)
    SRL     =   (0b0000000 << 10)   | (0b101 << 7)  | (0b0110011)
    SRA     =   (0b0100000 << 10)   | (0b101 << 7)  | (0b0110011)
    OR      =   (0b0000000 << 10)   | (0b110 << 7)  | (0b0110011)
    AND     =   (0b0000000 << 10)   | (0b111 << 7)  | (0b0110011)

    # [I-type]: (funct3)        | (opcode)
    JALR    =   (0b000 << 7)    | (0b1100111)
    LB      =   (0b000 << 7)    | (0b0000011)
    LH      =   (0b001 << 7)    | (0b0000011)
    LW      =   (0b010 << 7)    | (0b0000011)
    LBU     =   (0b100 << 7)    | (0b0000011)
    LHU     =   (0b101 << 7)    | (0b0000011)
    ADDI    =   (0b000 << 7)    | (0b0010011)
    SLTI    =   (0b010 << 7)    | (0b0010011)
    SLTIU   =   (0b011 << 7)    | (0b0010011)
    XORI    =   (0b100 << 7)    | (0b0010011)
    ORI     =   (0b110 << 7)    | (0b0010011)
    ANDI    =   (0b111 << 7)    | (0b0010011)
    FENCE   =   (0b000 << 7)    | (0b0001111)
    ECALL   =   (0b000 << 7)    | (0b1110011)
    #           (funct7)           | (funct3)      | (opcode)
    SLLI    =   (0b0000000 << 10)  | (0b001 << 7)  | (0b0010011)
    SRLI    =   (0b0000000 << 10)  | (0b101 << 7)  | (0b0010011)
    SRAI    =   (0b0100000 << 10)  | (0b101 << 7)  | (0b0010011)
    EBREAK  =   (0b0000001 << 10)  | (0b000 << 7)  | (0b1110011)

    # [S-type]: (funct3)        | (opcode)
    SB      =   (0b000 << 7)    | (0b0100011)
    SH      =   (0b001 << 7)    | (0b0100011)
    SW      =   (0b010 << 7)    | (0b0100011)

    # [B-type]: (funct3)        | (opcode)
    BEQ     =   (0b000 << 7)    | (0b1100011)
    BNE     =   (0b001 << 7)    | (0b1100011)
    BLT     =   (0b100 << 7)    | (0b1100011)
    BGE     =   (0b101 << 7)    | (0b1100011)
    BLTU    =   (0b110 << 7)    | (0b1100011)
    BGEU    =   (0b111 << 7)    | (0b1100011)

    # [U-type]: (opcode)
    LUI     =   (0b0110111)
    AUIPC   =   (0b0010111)

    # [J-type]: (opcode)
    JAL     =   (0b1101111)

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

# ---------------------------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    instructions    = sorted([x for x in Rv32iInstructions])
    uCode           = {'aluOp':0, 'aluSrcA':0, 'aluSrcB':0} #TODO: Complete this later...

    # Begin
    print(f"Instruction count: {len(instructions)} - (funct7_funct3_opcode)\n")
    for instr in instructions:
        print(f"{instr.name:<12}: 0b{(instr.value>>10):07b}_{(instr.value>>7)&0x3:03b}_{(instr.value&0x7f):07b}")
    # Eliminate dead addr bits (help optimize decoder)
    # ...


