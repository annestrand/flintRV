// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`ifndef TYPES_VH
`define TYPES_VH

/*
    Major opcode map (RV32I):
    Taken from:
        “The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Document Version 20191213”,
        Editors Andrew Waterman and Krste Asanovi´c, RISC-V Foundation, December 2019.
        (Table 24.1: RISC-V base opcode map, inst[1:0]=11)
*/
// _____________________________________________________________________________________________________________
// inst[4:2]    | 000    | 001      | 010      | 011      | 100    | 101      | 110            | 111   | (> 32b)
// inst[6:5] 00 | LOAD   | LOAD-FP  | custom-0 | MISC-MEM | OP-IMM | AUIPC    | OP-IMM-32      | 48b   |
//           01 | STORE  | STORE-FP | custom-1 | AMO      | OP     | LUI      | OP-32          | 64b   |
//           10 | MADD   | MSUB     | NMSUB    | NMADD    | OP-FP  | reserved | custom-2/rv128 | 48b   |
//           11 | BRANCH | JALR     | reserved | JAL      | SYSTEM | reserved | custom-3/rv128 | ≥ 80b |
// _____________________________________________________________________________________________________________
// NOTE: Lower 2 bits of RV32 instruction is unused - reserved for compressed (RV32C) instruction encoding
// ----------------------------------
`define LOAD                5'b00000
`define LOAD_FP             5'b00001
`define CUSTOM_0            5'b00010 // Free space
`define MISC_MEM            5'b00011
`define OP_IMM              5'b00100
`define AUIPC               5'b00101
`define OP_IMM_32           5'b00110
// ----------------------------------
`define STORE               5'b01000
`define STORE_FP            5'b01001
`define CUSTOM_1            5'b01010 // Free space
`define AMO                 5'b01011
`define OP                  5'b01100
`define LUI                 5'b01101
`define OP_32               5'b01110
// ----------------------------------
`define MADD                5'b10000
`define MSUB                5'b10001
`define NMSUB               5'b10010
`define NMADD               5'b10011
`define OP_FP               5'b10100
`define RESERVED_1          5'b10101
`define CUSTOM_2            5'b10110 // Free space (NOTE: This space is only available if NOT using RV128)
// ----------------------------------
`define BRANCH              5'b11000
`define JALR                5'b11001
`define RESERVED_2          5'b11010
`define JAL                 5'b11011
`define SYSTEM              5'b11100
`define RESERVED_3          5'b11101
`define CUSTOM_3            5'b11110 // Free space (NOTE: This space is only available if NOT using RV128)
// ----------------------------------

// Instruction fields       x[a:b]
`define OPCODE(x)           x[6:0]
`define OPCODE_RV32(x)      x[6:2]
`define RD(x)               x[11:7]
`define FUNCT3(x)           x[14:12]
`define RS1(x)              x[19:15]
`define RS2(x)              x[24:20]
`define FUNCT7(x)           x[31:25]
`define IMM_11_0(x)         x[31:20]

// Control signal fields    x[a:b]
`define CTRL_JMP(x)         x[0:0]
`define CTRL_BRA(x)         x[1:1]
`define CTRL_MEM2REG(x)     x[2:2]
`define CTRL_REG_W(x)       x[3:3]
`define CTRL_MEM_W(x)       x[4:4]
`define CTRL_EXEC_B(x)      x[5:5]
`define CTRL_EXEC_A(x)      x[6:6]
`define CTRL_ALU_OP(x)      x[11:7]
`define CTRL_ECALL(x)       x[12:12]
`define CTRL_EBREAK(x)      x[13:13]

// RV32I Opcode types
`define R                   7'b0110011
`define I_JUMP              7'b1100111
`define I_LOAD              7'b0000011
`define I_ARITH             7'b0010011
`define I_SYS               7'b1110011
`define I_FENCE             7'b0001111
`define S                   7'b0100011
`define B                   7'b1100011
`define U_LUI               7'b0110111
`define U_AUIPC             7'b0010111
`define J                   7'b1101111

// EXEC operand select
`define REG                 1'b0
`define PC                  1'b1
`define IMM                 1'b1

// Bool bit macros
`define TRUE                1'b1
`define FALSE               1'b0

// ALU EXEC Types
`define ALU_OP_ADD          5'b00000
`define ALU_OP_PASSB        5'b00001
`define ALU_OP_ADD4A        5'b00010
`define ALU_OP_XOR          5'b00011
`define ALU_OP_SRL          5'b00100
`define ALU_OP_SRA          5'b00101
`define ALU_OP_OR           5'b00110
`define ALU_OP_AND          5'b00111
`define ALU_OP_SUB          5'b01000
`define ALU_OP_SLL          5'b01001
`define ALU_OP_EQ           5'b01010
`define ALU_OP_NEQ          5'b01011
`define ALU_OP_SLT          5'b01100
`define ALU_OP_SLTU         5'b01101
`define ALU_OP_SGTE         5'b01110
`define ALU_OP_SGTEU        5'b01111

`define VP /*verilator public*/

`endif /* TYPES_VH */
