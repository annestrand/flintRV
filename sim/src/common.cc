#include <iostream>
#include <string>
#include <fstream>
#include <sstream>

#include "common.hh"

// ====================================================================================================================
bool loadMem(std::string filePath, char* mem, ssize_t memLen) {
    FILE* fp = fopen(filePath.c_str(), "rb+");
    if (fp == NULL) {
        LOG_E("Could not open [ %s ]!\n", filePath.c_str());
        return false;
    }
    for (ssize_t i=0; feof(fp) == 0; ++i) {
        if (i >= memLen) {
            LOG_E("Cannot fit hexfile [ %s ] in mem!\n", filePath.c_str());
            fclose(fp);
            return false;
        }
        size_t ret = fread(mem+i, 1, 1, fp);
    }
    return true;
}
// ====================================================================================================================
std::string disassembleRv32i(unsigned int instr) {
    constexpr unsigned int R       = 0b0110011;
    constexpr unsigned int I_JUMP  = 0b1100111;
    constexpr unsigned int I_LOAD  = 0b0000011;
    constexpr unsigned int I_ARITH = 0b0010011;
    constexpr unsigned int I_SYS   = 0b1110011;
    constexpr unsigned int I_FENCE = 0b0001111;
    constexpr unsigned int S       = 0b0100011;
    constexpr unsigned int B       = 0b1100011;
    constexpr unsigned int U_LUI   = 0b0110111;
    constexpr unsigned int U_AUIPC = 0b0010111;
    constexpr unsigned int J       = 0b1101111;
    const char *regName[] = {
        "zero",
        "ra",
        "sp",
        "gp", "tp",
        "t0", "t1", "t2",
        "s0",
        "s1",
        "a0", "a1",
        "a2", "a3", "a4", "a5", "a6", "a7",
        "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11",
        "t3", "t4", "t5", "t6"
    };
    typedef enum {
        ADD     = (0x0  << 10) | (0x0 << 7) | (0x33),
        SUB     = (0x20 << 10) | (0x0 << 7) | (0x33),
        SLL     = (0x0  << 10) | (0x1 << 7) | (0x33),
        SLT     = (0x0  << 10) | (0x2 << 7) | (0x33),
        SLTU    = (0x0  << 10) | (0x3 << 7) | (0x33),
        XOR     = (0x0  << 10) | (0x4 << 7) | (0x33),
        SRL     = (0x0  << 10) | (0x5 << 7) | (0x33),
        SRA     = (0x20 << 10) | (0x5 << 7) | (0x33),
        OR      = (0x0  << 10) | (0x6 << 7) | (0x33),
        AND     = (0x0  << 10) | (0x7 << 7) | (0x33)
    } RtypeInstructions;
    typedef enum {
        JALR    =                 (0x0 << 7) | (0x67),
        LB      =                 (0x0 << 7) | (0x3),
        LH      =                 (0x1 << 7) | (0x3),
        LW      =                 (0x2 << 7) | (0x3),
        LBU     =                 (0x4 << 7) | (0x3),
        LHU     =                 (0x5 << 7) | (0x3),
        ADDI    =                 (0x0 << 7) | (0x13),
        SLTI    =                 (0x2 << 7) | (0x13),
        SLTIU   =                 (0x3 << 7) | (0x13),
        XORI    =                 (0x4 << 7) | (0x13),
        ORI     =                 (0x6 << 7) | (0x13),
        ANDI    =                 (0x7 << 7) | (0x13),
        FENCE   =                 (0x0 << 7) | (0xf),
        ECALL   =                 (0x0 << 7) | (0x73),
        SLLI    = (0x0  << 10)  | (0x1 << 7) | (0x13),
        SRLI    = (0x0  << 10)  | (0x5 << 7) | (0x13),
        SRAI    = (0x20 << 10)  | (0x5 << 7) | (0x13),
        EBREAK  = (0x1 << 20)   | (0x0 << 7) | (0x73)
    } ItypeInstructions;
    typedef enum {
        SB      = (0x0 << 7) | (0x23),
        SH      = (0x1 << 7) | (0x23),
        SW      = (0x2 << 7) | (0x23)
    } StypeInstructions;
    typedef enum {
        BEQ     = (0x0 << 7) | (0x63),
        BNE     = (0x1 << 7) | (0x63),
        BLT     = (0x4 << 7) | (0x63),
        BGE     = (0x5 << 7) | (0x63),
        BLTU    = (0x6 << 7) | (0x63),
        BGEU    = (0x7 << 7) | (0x63)
    } BtypeInstructions;
    typedef enum { LUI     = (0x37), AUIPC   = (0x17)   } UtypeInstructions;
    typedef enum { JAL     = (0x6f)                     } JtypeInstructions;
    auto getBits = [](unsigned int instr, int pos, int width) {
        return ((instr & ((((1 << width) - 1) << pos))) >> pos);
    };
    auto OPCODE     = getBits(instr, 0, 7);
    auto RD         = getBits(instr, 7, 5);
    auto RS1        = getBits(instr, 15, 5);
    auto RS2        = getBits(instr, 20, 5);
    auto FUNCT3     = getBits(instr, 12, 3);
    auto FUNCT7     = getBits(instr, 25, 7);
    auto IMM_10_5   = getBits(instr, 25, 6);
    auto IMM_11_B   = getBits(instr, 7, 1);
    auto IMM_4_1    = getBits(instr, 8, 4);
    auto IMM_4_0    = getBits(instr, 7, 5);
    auto IMM_11_5   = getBits(instr, 25, 7);
    auto IMM_12     = getBits(instr, 31, 1);
    auto IMM_20     = getBits(instr, 31, 1);
    auto IMM_11_0   = getBits(instr, 20, 12);
    auto IMM_11_J   = getBits(instr, 20, 1);
    auto IMM_19_12  = getBits(instr, 12, 8);
    auto IMM_10_1   = getBits(instr, 21, 10);
    auto IMM_31_12  = getBits(instr, 12, 20);
    auto SUCC       = getBits(instr, 20, 4);
    auto PRED       = getBits(instr, 24, 4);
    auto FM         = getBits(instr, 28, 4);
    std::stringstream ss;
    switch (OPCODE) {
        case R       : {
            switch (FUNCT7 << 10 | FUNCT3 << 7 | OPCODE) {
                case ADD : ss << "add "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SUB : ss << "sub "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SLL : ss << "sll "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SLT : ss << "slt "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SLTU: ss << "sltu " << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case XOR : ss << "xor "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SRL : ss << "srl "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case SRA : ss << "sra "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case OR  : ss << "or "   << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                case AND : ss << "and "  << regName[RD] << ", " << regName[RS1] << ", " << regName[RS2]; break;
                default  : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case I_LOAD  : {
            auto immFinal   = (((int)IMM_11_0 << 20) >> 20);
            switch (FUNCT3 << 7 | OPCODE) {
                case LB  : ss << "lb "  << regName[RD] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case LH  : ss << "lh "  << regName[RD] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case LW  : ss << "lw "  << regName[RD] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case LBU : ss << "lbu " << regName[RD] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case LHU : ss << "lhu " << regName[RD] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                default  : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case I_JUMP  :
        case I_ARITH : {
            auto immFinal   = (((int)IMM_11_0 << 20) >> 20);
            switch (FUNCT3 << 7 | OPCODE) {
                case SLLI  : ss << "slli "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case SRLI  : ss << "srli "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case SRAI  : ss << "srai "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case JALR  : ss << "jalr "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case ADDI  : ss << "addi "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case SLTI  : ss << "slti "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case SLTIU : ss << "sltiu " << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case XORI  : ss << "xori "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case ORI   : ss << "ori "   << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                case ANDI  : ss << "andi "  << regName[RD] << ", " << regName[RS1] << ", " << immFinal; break;
                default    : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case I_SYS   : {
            switch (IMM_11_0 << 20 | FUNCT3 << 7 | OPCODE) {
                case ECALL  : ss << "ecall"; break;
                case EBREAK : ss << "ebreak"; break;
                default     : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case I_FENCE : ss << "fence fm:" << FM << ", pred:" << PRED << ", succ:" << SUCC; break;
        case S       : {
            auto immFinal = (((int)(IMM_4_0 | IMM_11_5 << 5) << 20) >> 20);
            switch (FUNCT3 << 7 | OPCODE) {
                case SB : ss << "sb " << regName[RS2] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case SH : ss << "sh " << regName[RS2] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                case SW : ss << "sw " << regName[RS2] << ", " << immFinal << "(" << regName[RS1] << ")"; break;
                default : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case B       : {
            auto targetAddr = (int)((IMM_4_1 | IMM_10_5 << 4 | IMM_11_B << 10 | IMM_12 << 11) << 20) >> 19;
            switch (FUNCT3 << 7 | OPCODE) {
                case BEQ  : ss << "beq "  << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                case BNE  : ss << "bne "  << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                case BLT  : ss << "blt "  << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                case BGE  : ss << "bge "  << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                case BLTU : ss << "bltu " << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                case BGEU : ss << "bgeu " << regName[RS1] << ", " << regName[RS2] << ", " << targetAddr; break;
                default   : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case U_LUI   :
        case U_AUIPC : {
            auto immFinal = IMM_31_12;
            switch (OPCODE) {
                case LUI   : ss << "lui "   << regName[RD] << ", " << immFinal; break;
                case AUIPC : ss << "auipc " << regName[RD] << ", " << immFinal; break;
                default    : ss << "Unknown instruction!"; break;
            }
            break;
        }
        case J       : {
            auto targetAddr = (int)((IMM_10_1 | IMM_11_J << 10 | IMM_19_12 << 11 | IMM_20 << 19) << 12) >> 11;
            ss << "jal " << regName[RD] << ", " << targetAddr; break;
        }
        default : ss << "Unknown instruction!"; break;
    }
    return ss.str();
}
