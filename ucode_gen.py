import sys
import argparse
from enum import IntEnum

# RISC-V RV32I base ctrl
class Rv32icontroller(IntEnum):
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

class AluSrcA(IntEnum):
    FROM_RS1    = 0b0
    FROM_PC     = 0b1

class AluSrcB(IntEnum):
    FROM_RS2    = 0b0
    FROM_IMM    = 0b1

# ---------------------------------------------------------------------------------------------------------------------

class Controller(object):
    uCodeLen = 0
    def __init__(self, instName, instAddr, uCode):
        self.instrName = instName
        self.instrAddr = instAddr
        self.uCode     = uCode

def uCodeAssign(controller, name, uCode):
    for instr in controller:
        if instr.instrName == name:
            controller[controller.index(instr)].uCode = uCode
            if len(uCode) > instr.uCodeLen:
                instr.uCodeLen = len(uCode)
            return

def uCodeFmt(aluOp, aluSrcA, aluSrcB):
    return f"{aluOp.value:04b}{aluSrcA.value:02b}{aluSrcB.value:02b}"

if __name__ == "__main__":
    # Define args/opts
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--dump", "-d", action="store_true", help="Emit the microcode to [ ucode_gen.dat ].")
    args, unknown = parser.parse_known_args()
    if len(unknown) != 0:
        print(f"[ucode_gen.py - Error]: Unknown argument(s)/option(s):\n{unknown}\n")
        parser.print_help()
        exit(0)

    # Begin
    ctrlAddrLen     = 17    # (i.e. funct7 + funct3 + op)
    deadBits        = [True]*ctrlAddrLen
    ctrl            = [Controller(x.name, x.value, '') for x in (sorted([x for x in Rv32icontroller]))]
    print(f"Instruction count: {len(ctrl)}\n-----------------------------------")
    for instr in ctrl:
        print(
            f"{instr.instrName:<12}: 0b{(instr.instrAddr>>10):07b}" +
            f"_{(instr.instrAddr>>7)&0x7:03b}_{(instr.instrAddr&0x7f):07b}"
        )
        # Find dead bits
        for bitpos in range(ctrlAddrLen):
            if ((1 << bitpos) & instr.instrAddr) > 0:
                deadBits[bitpos] = False

    # TODO: double check these...
    uCodeAssign(ctrl, "LB", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "FENCE", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "ADDI", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "AUIPC", uCodeFmt(AluOp.ADD,AluSrcA.FROM_PC,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SB", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "ADD", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "LUI", uCodeFmt(AluOp.PASS_B,AluSrcA.FROM_PC,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "BEQ", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "JALR", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "JAL", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "ECALL", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "LH", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLLI", uCodeFmt(AluOp.SLL,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SH", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLL", uCodeFmt(AluOp.SLL,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "BNE", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "LW", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLTI", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SW", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLT", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLTIU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SLTU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "LBU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "XORI", uCodeFmt(AluOp.XOR,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "XOR", uCodeFmt(AluOp.XOR,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "BLT", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "LHU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SRLI", uCodeFmt(AluOp.SRL,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SRL", uCodeFmt(AluOp.SRL,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "BGE", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "ORI", uCodeFmt(AluOp.OR,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "OR", uCodeFmt(AluOp.OR,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "BLTU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "ANDI", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "AND", uCodeFmt(AluOp.AND,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "BGEU", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "EBREAK", uCodeFmt(AluOp.ADD,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SUB", uCodeFmt(AluOp.SUB,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))
    uCodeAssign(ctrl, "SRAI", uCodeFmt(AluOp.SRA,AluSrcA.FROM_RS1,AluSrcB.FROM_IMM))
    uCodeAssign(ctrl, "SRA", uCodeFmt(AluOp.SRA,AluSrcA.FROM_RS1,AluSrcB.FROM_RS2))

    # Eliminate dead addr. bits (help optimize decoder in HDL)
    print(f"\nDeadbits removed:\n-----------------")
    for i in range(ctrlAddrLen):
        print(f"Bit[{i:>4}]:  {'[REMOVED]' if deadBits[i] else ''}")
        if deadBits[i]:
            for instr in ctrl:
                if instr.instrAddr >= (1 << i):
                    for j in range(i, ctrlAddrLen):
                        if not deadBits[j]:
                            lowerTmp = ((1 << i) - 1) & instr.instrAddr
                            ctrl[ctrl.index(instr)].instrAddr = (
                                ((instr.instrAddr >> j-i) & (1 << i)) | lowerTmp
                            )
                            break

    # Dump and generate stuff
    finalAddrWidth      = len([x for x in deadBits if x != True])
    defaultCase         = next((x for x in ctrl if x.instrName == 'ECALL'), None)
    if args.dump:
        ucodeDataFile   = open('g_ucode.dat', 'w')
        ucodeFile       = open('g_ucode.v', 'w')
        print(f"\nDumping microcode to file(s): [ {ucodeDataFile.name} ] & [ {ucodeFile.name} ]\n")
    else:
        ucodeDataFile   = sys.stdout
        ucodeFile       = sys.stdout
        print("\nFinal values:\n--------------------------------------------------------")

    print(f"module decoder(\n    input clk, input [{ctrlAddrLen-1}:0]inAddr, ", file=ucodeFile)
    print(f"    output reg [{ctrl[0].uCodeLen-1}:0]decoderOut\n)", file=ucodeFile)
    print(f"    reg [{ctrl[0].uCodeLen-1}:0]ucode[0:{len(ctrl)-1}];", file=ucodeFile)
    print(f"    wire[{finalAddrWidth-1}:0]ucodeAddr;", file=ucodeFile)
    print(f"    always@* begin", file=ucodeFile)
    print(f"        case(inAddr)", file=ucodeFile)
    for instr in ctrl:
        i = ctrl.index(instr)
        uCodeFmtStr = f"{instr.uCode}"
        uCodeDecoderFmtStr = (
            f"        /* {instr.instrName:<8} */ " +
            f"{finalAddrWidth}\'b{instr.instrAddr:0{finalAddrWidth}b}" +
            f" : ucodeAddr = \'d{str(i)+';':<4}   // ucode[{i:>4}]: {instr.uCode:>8}"
        )
        uCodeDecoderDefaultFmtStr = (
            f"        /* {defaultCase.instrName:<8} */ " +
            f"default{'         ':>}" +
            f" : ucodeAddr = \'d{str(ctrl.index(defaultCase))+';':<4}"
        )
        print(uCodeFmtStr, file=ucodeDataFile)
        print(uCodeDecoderFmtStr, file=ucodeFile)
    print(uCodeDecoderDefaultFmtStr, file=ucodeFile)
    print(f"        endcase", file=ucodeFile)
    print(f"    end", file=ucodeFile)
    print(f"    initial begin", file=ucodeFile)
    print(f"        $readmemb(\"g_ucode.dat\", ucode)", file=ucodeFile)
    print(f"    end", file=ucodeFile)
    print(f"    always@(posedge clk) begin", file=ucodeFile)
    print(f"        decoderOut <= ucode[ucodeAddr]", file=ucodeFile)
    print(f"    end", file=ucodeFile)
    print(f"endmodule", file=ucodeFile)
    if args.dump:
        ucodeDataFile.close()
        ucodeFile.close()
