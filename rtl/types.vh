// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`ifndef TYPES_VH
`define TYPES_VH

// Instruction fields
`define OPCODE(x)           x[6:0]
`define RD(x)               x[11:7]
`define FUNCT3(x)           x[14:12]
`define RS1(x)              x[19:15]
`define RS2(x)              x[24:20]
`define FUNCT7(x)           x[31:25]
`define IMM_11_0(x)         x[31:20]

// Control signal fields
`define CTRL_JMP(x)         x[0:0]
`define CTRL_BRA(x)         x[1:1]
`define CTRL_MEM2REG(x)     x[2:2]
`define CTRL_REG_W(x)       x[3:3]
`define CTRL_MEM_W(x)       x[4:4]
`define CTRL_EXEC_B(x)      x[5:5]
`define CTRL_EXEC_A(x)      x[6:6]
`define CTRL_ALU_OP(x)      x[10:7]
`define CTRL_ECALL(x)       x[11:11]
`define CTRL_EBREAK(x)      x[12:12]

`define VERILATOR_SIGNAL_FN(x, width)           \
   function [width-1:0] get_``x;                \
      /*verilator public*/                      \
      get_``x = x;                              \
   endfunction

`define VERILATOR_TYPE_FN(name, value)          \
    function integer get_``name;                \
      /*verilator public*/                      \
      /* verilator lint_off WIDTH */            \
      integer get_``name = value;               \
      /* verilator lint_on WIDTH */             \
      return get_``name;                        \
      endfunction

`define VERILATOR_DEF_WRAP(x)                   \
    `define VERILATOR_DEF                       \
    x                                           \
    `undef VERILATOR_DEF

`define TYPE_DEFINE(name, value)                \
    `ifdef VERILATOR_DEF                        \
        `VERILATOR_TYPE_FN(name, value)         \
    `else                                       \
        `define name value                      \
    `endif

// RV32I Opcode types
`define OPCODE_TYPES                            \
    `TYPE_DEFINE(R,         7'b0110011)         \
    `TYPE_DEFINE(I_JUMP,    7'b1100111)         \
    `TYPE_DEFINE(I_LOAD,    7'b0000011)         \
    `TYPE_DEFINE(I_ARITH,   7'b0010011)         \
    `TYPE_DEFINE(I_SYS,     7'b1110011)         \
    `TYPE_DEFINE(I_FENCE,   7'b0001111)         \
    `TYPE_DEFINE(S,         7'b0100011)         \
    `TYPE_DEFINE(B,         7'b1100011)         \
    `TYPE_DEFINE(U_LUI,     7'b0110111)         \
    `TYPE_DEFINE(U_AUIPC,   7'b0010111)         \
    `TYPE_DEFINE(J,         7'b1101111)

// EXEC operand select
`define EXEC_OPERAND_SEL                        \
    `TYPE_DEFINE(REG,   1'b0)                   \
    `TYPE_DEFINE(PC,    1'b1)                   \
    `TYPE_DEFINE(IMM,   1'b1)

// Bool bit macros
`define BOOL_BITS                               \
    `TYPE_DEFINE(TRUE,  1'b1)                   \
    `TYPE_DEFINE(FALSE, 1'b0)

// ALU CTRL OPS
`define ALU_CTRL_OPS                            \
    `TYPE_DEFINE(ALU_OP_R,          4'b0000)    \
    `TYPE_DEFINE(ALU_OP_I_JUMP,     4'b0001)    \
    `TYPE_DEFINE(ALU_OP_I_LOAD,     4'b0010)    \
    `TYPE_DEFINE(ALU_OP_I_ARITH,    4'b0011)    \
    `TYPE_DEFINE(ALU_OP_I_SYS,      4'b0100)    \
    `TYPE_DEFINE(ALU_OP_I_FENCE,    4'b0101)    \
    `TYPE_DEFINE(ALU_OP_S,          4'b0110)    \
    `TYPE_DEFINE(ALU_OP_B,          4'b0111)    \
    `TYPE_DEFINE(ALU_OP_U_LUI,      4'b1000)    \
    `TYPE_DEFINE(ALU_OP_U_AUIPC,    4'b1001)    \
    `TYPE_DEFINE(ALU_OP_J,          4'b1010)

// ALU EXEC OPS
`define ALU_EXEC_OPS                            \
    `TYPE_DEFINE(ALU_EXEC_ADD,      5'b00000)   \
    `TYPE_DEFINE(ALU_EXEC_PASSB,    5'b00001)   \
    `TYPE_DEFINE(ALU_EXEC_ADD4A,    5'b00010)   \
    `TYPE_DEFINE(ALU_EXEC_XOR,      5'b00011)   \
    `TYPE_DEFINE(ALU_EXEC_SRL,      5'b00100)   \
    `TYPE_DEFINE(ALU_EXEC_SRA,      5'b00101)   \
    `TYPE_DEFINE(ALU_EXEC_OR,       5'b00110)   \
    `TYPE_DEFINE(ALU_EXEC_AND,      5'b00111)   \
    `TYPE_DEFINE(ALU_EXEC_SUB,      5'b01000)   \
    `TYPE_DEFINE(ALU_EXEC_SLL,      5'b01001)   \
    `TYPE_DEFINE(ALU_EXEC_EQ,       5'b01010)   \
    `TYPE_DEFINE(ALU_EXEC_NEQ,      5'b01011)   \
    `TYPE_DEFINE(ALU_EXEC_SLT,      5'b01100)   \
    `TYPE_DEFINE(ALU_EXEC_SLTU,     5'b01101)   \
    `TYPE_DEFINE(ALU_EXEC_SGTE,     5'b01110)   \
    `TYPE_DEFINE(ALU_EXEC_SGTEU,    5'b01111)

// Define all above TYPE_DEFINE's
`BOOL_BITS
`OPCODE_TYPES
`ALU_CTRL_OPS
`ALU_EXEC_OPS
`EXEC_OPERAND_SEL

// Core control unit signal defaults
// _________________________________________________________________________________________________________________
//                             | ALU_OP          | EXEC_A | EXEC_B | MEM_W  | REG_W  | MEM2REG | BRA     | JMP      |
`define R_CTRL          { 21'd0, `ALU_OP_R       , `REG   , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE   }
`define I_JUMP_CTRL     { 21'd0, `ALU_OP_I_JUMP  , `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE    }
`define I_LOAD_CTRL     { 21'd0, `ALU_OP_I_LOAD  , `REG   , `IMM   , `FALSE , `TRUE  , `TRUE   , `FALSE  , `FALSE   }
`define I_ARITH_CTRL    { 21'd0, `ALU_OP_I_ARITH , `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE   }
`define I_SYS_CTRL      { 21'd0, `ALU_OP_I_SYS   , `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE   }
`define I_FENCE_CTRL    { 21'd0, `ALU_OP_I_FENCE , `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE   }
`define S_CTRL          { 21'd0, `ALU_OP_S       , `REG   , `IMM   , `TRUE  , `FALSE , `FALSE  , `FALSE  , `FALSE   }
`define B_CTRL          { 21'd0, `ALU_OP_B       , `REG   , `REG   , `FALSE , `FALSE , `FALSE  , `TRUE   , `FALSE   }
`define U_LUI_CTRL      { 21'd0, `ALU_OP_U_LUI   , `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE   }
`define U_AUIPC_CTRL    { 21'd0, `ALU_OP_U_AUIPC , `PC    , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE   }
`define J_CTRL          { 21'd0, `ALU_OP_J       , `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE    }

`endif // TYPES_VH
