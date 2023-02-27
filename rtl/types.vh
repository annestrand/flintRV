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
   function static [width-1:0] get_``x;         \
      /*verilator public*/                      \
      get_``x = x;                              \
   endfunction

`define VERILATOR_TYPE_FN(name)                 \
    function static integer get_``name;         \
      /*verilator public*/                      \
      /* verilator lint_off WIDTH */            \
      integer get_``name = `name;               \
      /* verilator lint_on WIDTH */             \
      return get_``name;                        \
      endfunction

`define VERILATOR_PARAM_FN(name)                \
    function static integer get_``name;         \
      /*verilator public*/                      \
      /* verilator lint_off WIDTH */            \
      integer get_``name = name;                \
      /* verilator lint_on WIDTH */             \
      return get_``name;                        \
      endfunction

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
`define PC                  1'b1    // Operand A
`define IMM                 1'b1    // Operand B

// Bool bit macros
`define TRUE                1'b1
`define FALSE               1'b0

// ALU OP
`define ALU_OP_R            4'b0000
`define ALU_OP_I_JUMP       4'b0001
`define ALU_OP_I_LOAD       4'b0010
`define ALU_OP_I_ARITH      4'b0011
`define ALU_OP_I_SYS        4'b0100
`define ALU_OP_I_FENCE      4'b0101
`define ALU_OP_S            4'b0110
`define ALU_OP_B            4'b0111
`define ALU_OP_U_LUI        4'b1000
`define ALU_OP_U_AUIPC      4'b1001
`define ALU_OP_J            4'b1010

// ALU EXEC Types
`define ALU_EXEC_ADD        5'b00000
`define ALU_EXEC_PASSB      5'b00001
`define ALU_EXEC_ADD4A      5'b00010
`define ALU_EXEC_XOR        5'b00011
`define ALU_EXEC_SRL        5'b00100
`define ALU_EXEC_SRA        5'b00101
`define ALU_EXEC_OR         5'b00110
`define ALU_EXEC_AND        5'b00111
`define ALU_EXEC_SUB        5'b01000
`define ALU_EXEC_SLL        5'b01001
`define ALU_EXEC_EQ         5'b01010
`define ALU_EXEC_NEQ        5'b01011
`define ALU_EXEC_SLT        5'b01100
`define ALU_EXEC_SLTU       5'b01101
`define ALU_EXEC_SGTE       5'b01110
`define ALU_EXEC_SGTEU      5'b01111

// TODO: Fixme
`define VERILATOR_OPCODE_DEF    \
    `VERILATOR_TYPE_FN(R      ) \
    `VERILATOR_TYPE_FN(I_JUMP ) \
    `VERILATOR_TYPE_FN(I_LOAD ) \
    `VERILATOR_TYPE_FN(I_ARITH) \
    `VERILATOR_TYPE_FN(I_SYS  ) \
    `VERILATOR_TYPE_FN(I_FENCE) \
    `VERILATOR_TYPE_FN(S      ) \
    `VERILATOR_TYPE_FN(B      ) \
    `VERILATOR_TYPE_FN(U_LUI  ) \
    `VERILATOR_TYPE_FN(U_AUIPC) \
    `VERILATOR_TYPE_FN(J      )
`define VERILATOR_ALU_EXEC_DEF        \
    `VERILATOR_TYPE_FN(ALU_EXEC_ADD  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_PASSB)\
    `VERILATOR_TYPE_FN(ALU_EXEC_ADD4A)\
    `VERILATOR_TYPE_FN(ALU_EXEC_XOR  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SRL  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SRA  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_OR   )\
    `VERILATOR_TYPE_FN(ALU_EXEC_AND  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SUB  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SLL  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_EQ   )\
    `VERILATOR_TYPE_FN(ALU_EXEC_NEQ  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SLT  )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SLTU )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SGTE )\
    `VERILATOR_TYPE_FN(ALU_EXEC_SGTEU)

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
