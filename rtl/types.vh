`ifndef TYPES_VH
`define TYPES_VH

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

// Instruction fields
`define OPCODE(x)           x[6:0]
`define RD(x)               x[11:7]
`define FUNCT3(x)           x[14:12]
`define RS1(x)              x[19:15]
`define RS2(x)              x[24:20]
`define FUNCT7(x)           x[31:25]

// Forward select
`define NO_FWD              2'b00
`define FWD_MEM             2'b01
`define FWD_WB              2'b10

// EXEC operand select
`define REG                 1'b0
`define PC                  1'b1    // Operand A
`define IMM                 1'b1    // Operand B

// Yes/No bit macros
`define Y                   1'b1
`define N                   1'b0

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
`define ALU_EXEC_ADD        5'b0_0000
`define ALU_EXEC_PASSB      5'b0_0001
`define ALU_EXEC_ADD4A      5'b0_0010
`define ALU_EXEC_XOR        5'b0_0011
`define ALU_EXEC_SRL        5'b0_0100
`define ALU_EXEC_SRA        5'b0_0101
`define ALU_EXEC_OR         5'b0_0110
`define ALU_EXEC_AND        5'b0_0111
`define ALU_EXEC_SUB        5'b0_1000
`define ALU_EXEC_SLL        5'b0_1001
`define ALU_EXEC_EQ         5'b0_1010
`define ALU_EXEC_NEQ        5'b0_1011
`define ALU_EXEC_SLT        5'b0_1100
`define ALU_EXEC_SLTU       5'b0_1101
`define ALU_EXEC_SGTE       5'b0_1110
`define ALU_EXEC_SGTEU      5'b0_1111

// Load/Store op type
`define LS_B_OP             3'b000
`define LS_H_OP             3'b001
`define LS_W_OP             3'b010
`define LS_BU_OP            3'b100
`define LS_HU_OP            3'b101

// Opcode-type controls
//                          | ALU_OP          | EXEC_A | EXEC_B | MEM_W | REG_W | MEM2REG | BRA | JMP |
`define R_CTRL              { `ALU_OP_R,        `REG,    `REG,    `N,     `Y,     `N,       `N,   `N  }
`define I_JUMP_CTRL         { `ALU_OP_I_JUMP,   `PC,     `REG,    `N,     `Y,     `N,       `N,   `Y  }
`define I_LOAD_CTRL         { `ALU_OP_I_LOAD,   `REG,    `IMM,    `N,     `Y,     `Y,       `N,   `N  }
`define I_ARITH_CTRL        { `ALU_OP_I_ARITH,  `REG,    `IMM,    `N,     `Y,     `N,       `N,   `N  }
`define I_SYS_CTRL          { `ALU_OP_I_SYS,    `REG,    `IMM,    `N,     `N,     `N,       `N,   `N  }
`define I_FENCE_CTRL        { `ALU_OP_I_FENCE,  `REG,    `IMM,    `N,     `N,     `N,       `N,   `N  }
`define S_CTRL              { `ALU_OP_S,        `REG,    `IMM,    `Y,     `N,     `N,       `N,   `N  }
`define B_CTRL              { `ALU_OP_B,        `REG,    `REG,    `N,     `N,     `N,       `Y,   `N  }
`define U_LUI_CTRL          { `ALU_OP_U_LUI,    `REG,    `IMM,    `N,     `Y,     `N,       `N,   `N  }
`define U_AUIPC_CTRL        { `ALU_OP_U_AUIPC,  `PC,     `IMM,    `N,     `Y,     `N,       `N,   `N  }
`define J_CTRL              { `ALU_OP_J,        `PC,     `REG,    `N,     `Y,     `N,       `N,   `Y  }

`define ENDIAN_SWP_32(x)    {x[7:0],x[15:8],x[23:16],x[31:24]}
`define IS_SHIFT_IMM(x)     (~x[13] && x[12])

`endif // TYPES_VH
