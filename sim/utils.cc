// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <cstdint>

#include "types.hh"
#include "utils.hh"


bool loadMem(std::string filePath, char *mem, ssize_t memLen) {
  FILE *fp = fopen(filePath.c_str(), "rb+");
  if (fp == NULL) {
    LOG_E("Could not open [ %s ]!\n", filePath.c_str());
    return false;
  }
  for (ssize_t i = 0; feof(fp) == 0; ++i) {
    if (i >= memLen) {
      LOG_E("Cannot fit hexfile [ %s ] in mem!\n", filePath.c_str());
      fclose(fp);
      return false;
    }
    fread(mem + i, 1, 1, fp);
  }
  return true;
}

std::string disassembleRv32i(unsigned int instr) {
  const char *regName[] = {"zero", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2",
                           "s0",   "s1", "a0",  "a1",  "a2", "a3", "a4", "a5",
                           "a6",   "a7", "s2",  "s3",  "s4", "s5", "s6", "s7",
                           "s8",   "s9", "s10", "s11", "t3", "t4", "t5", "t6"};
  uint32_t OPCODE = OPCODE(instr);
  uint32_t RD = RD(instr);
  uint32_t RS1 = RS1(instr);
  uint32_t RS2 = RS2(instr);
  uint32_t FUNCT3 = FUNCT3(instr);
  uint32_t FUNCT7 = FUNCT7(instr);
  uint32_t SUCC = SUCC(instr);
  uint32_t PRED = PRED(instr);
  uint32_t FM = FM(instr);
  std::stringstream ss;
  switch (OPCODE) {
  case R: {
    switch (FUNCT7 << 10 | FUNCT3 << 7 | OPCODE) {
    case ADD:
      ss << "add " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SUB:
      ss << "sub " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SLL:
      ss << "sll " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SLT:
      ss << "slt " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SLTU:
      ss << "sltu " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case XOR:
      ss << "xor " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SRL:
      ss << "srl " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case SRA:
      ss << "sra " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case OR:
      ss << "or " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    case AND:
      ss << "and " << regName[RD] << ", " << regName[RS1] << ", "
         << regName[RS2];
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case I_LOAD: {
    auto immFinal = I_IMM(instr);
    switch (FUNCT3 << 7 | OPCODE) {
    case LB:
      ss << "lb " << regName[RD] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case LH:
      ss << "lh " << regName[RD] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case LW:
      ss << "lw " << regName[RD] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case LBU:
      ss << "lbu " << regName[RD] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case LHU:
      ss << "lhu " << regName[RD] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case I_JUMP:
  case I_ARITH: {
    auto immFinal = I_IMM(instr);
    switch (FUNCT3 << 7 | OPCODE) {
    case SLLI:
      ss << "slli " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case SRLI:
      ss << "srli " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case SRAI:
      ss << "srai " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case JALR:
      ss << "jalr " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case ADDI:
      ss << "addi " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case SLTI:
      ss << "slti " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case SLTIU:
      ss << "sltiu " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case XORI:
      ss << "xori " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case ORI:
      ss << "ori " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    case ANDI:
      ss << "andi " << regName[RD] << ", " << regName[RS1] << ", " << immFinal;
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case I_SYS: {
    switch (IMM_11_0(instr) << 20 | FUNCT3 << 7 | OPCODE) {
    case ECALL:
      ss << "ecall";
      break;
    case EBREAK:
      ss << "ebreak";
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case I_FENCE:
    ss << "fence fm:" << FM << ", pred:" << PRED << ", succ:" << SUCC;
    break;
  case S: {
    auto immFinal = S_IMM(instr);
    switch (FUNCT3 << 7 | OPCODE) {
    case SB:
      ss << "sb " << regName[RS2] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case SH:
      ss << "sh " << regName[RS2] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    case SW:
      ss << "sw " << regName[RS2] << ", " << immFinal << "(" << regName[RS1]
         << ")";
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case B: {
    auto targetAddr = B_IMM(instr);
    switch (FUNCT3 << 7 | OPCODE) {
    case BEQ:
      ss << "beq " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    case BNE:
      ss << "bne " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    case BLT:
      ss << "blt " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    case BGE:
      ss << "bge " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    case BLTU:
      ss << "bltu " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    case BGEU:
      ss << "bgeu " << regName[RS1] << ", " << regName[RS2] << ", "
         << targetAddr;
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case U_LUI:
  case U_AUIPC: {
    auto immFinal = IMM_31_12(instr);
    switch (OPCODE) {
    case LUI:
      ss << "lui " << regName[RD] << ", " << immFinal;
      break;
    case AUIPC:
      ss << "auipc " << regName[RD] << ", " << immFinal;
      break;
    default:
      ss << "Unknown instruction!";
      break;
    }
    break;
  }
  case J: {
    auto targetAddr = J_IMM(instr);
    ss << "jal " << regName[RD] << ", " << targetAddr;
    break;
  }
  default:
    ss << "Unknown instruction!";
    break;
  }
  return ss.str();
}
