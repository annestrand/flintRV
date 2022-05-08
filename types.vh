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

// Control bubble
`define NO_CTRL_BUBBLE      1'b0
`define CTRL_BUBBLE         1'b1

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
`define OP_ADD              5'b0_0000
`define OP_PASSB            5'b0_0001
`define OP_ADD4A            5'b0_0010
`define OP_XOR              5'b0_0011
`define OP_SRL              5'b0_0100
`define OP_SRA              5'b0_0101
`define OP_OR               5'b0_0110
`define OP_AND              5'b0_0111
`define OP_SUB              5'b0_1000
`define OP_SLL              5'b0_1001
`define OP_EQ               5'b0_1010
`define OP_NEQ              5'b0_1011
`define OP_SLT              5'b0_1100
`define OP_SLTU             5'b0_1101
`define OP_SGTE             5'b0_1110
`define OP_SGTEU            5'b0_1111

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

// Utility and Debug macro(s)
`define ENDIAN_SWP_32(x)    {x[7:0],x[15:8],x[23:16],x[31:24]}
`define DBG_INSTR_TRACES                                        \
    `DBG_INSTR_TRACE("ADD",    7'h00,      3'h0,       7'h33   )\ // --- R-Type ---
    `DBG_INSTR_TRACE("SUB",    7'h20,      3'h0,       7'h33   )\
    `DBG_INSTR_TRACE("SLL",    7'h00,      3'h1,       7'h33   )\
    `DBG_INSTR_TRACE("SLT",    7'h00,      3'h2,       7'h33   )\
    `DBG_INSTR_TRACE("SLTU",   7'h00,      3'h3,       7'h33   )\
    `DBG_INSTR_TRACE("XOR",    7'h00,      3'h4,       7'h33   )\
    `DBG_INSTR_TRACE("SRL",    7'h00,      3'h5,       7'h33   )\
    `DBG_INSTR_TRACE("SRA",    7'h20,      3'h5,       7'h33   )\
    `DBG_INSTR_TRACE("OR",     7'h00,      3'h6,       7'h33   )\
    `DBG_INSTR_TRACE("AND",    7'h00,      3'h7,       7'h33   )\
    `DBG_INSTR_TRACE("JALR",   7'h00,      3'h0,       7'h67   )\ // --- I-Type ---
    `DBG_INSTR_TRACE("LB",     7'h00,      3'h0,       7'h03   )\
    `DBG_INSTR_TRACE("LH",     7'h00,      3'h1,       7'h03   )\
    `DBG_INSTR_TRACE("LW",     7'h00,      3'h2,       7'h03   )\
    `DBG_INSTR_TRACE("LBU",    7'h00,      3'h4,       7'h03   )\
    `DBG_INSTR_TRACE("LHU",    7'h00,      3'h5,       7'h03   )\
    `DBG_INSTR_TRACE("ADDI",   7'h00,      3'h0,       7'h13   )\
    `DBG_INSTR_TRACE("SLTI",   7'h00,      3'h2,       7'h13   )\
    `DBG_INSTR_TRACE("SLTIU",  7'h00,      3'h3,       7'h13   )\
    `DBG_INSTR_TRACE("XORI",   7'h00,      3'h4,       7'h13   )\
    `DBG_INSTR_TRACE("ORI",    7'h00,      3'h6,       7'h13   )\
    `DBG_INSTR_TRACE("ANDI",   7'h00,      3'h7,       7'h13   )\
    `DBG_INSTR_TRACE("FENCE",  7'h00,      3'h0,       7'h0f   )\
    `DBG_INSTR_TRACE("ECALL",  7'h00,      3'h0,       7'h73   )\
    `DBG_INSTR_TRACE("SLLI",   7'h00,      3'h1,       7'h13   )\
    `DBG_INSTR_TRACE("SRLI",   7'h00,      3'h5,       7'h13   )\
    `DBG_INSTR_TRACE("SRAI",   7'h20,      3'h5,       7'h13   )\
    `DBG_INSTR_TRACE("EBREAK", 7'h01,      3'h0,       7'h73   )\
    `DBG_INSTR_TRACE("SB",     7'h00,      3'h0,       7'h23   )\ // --- S-Type ---
    `DBG_INSTR_TRACE("SH",     7'h00,      3'h1,       7'h23   )\
    `DBG_INSTR_TRACE("SW",     7'h00,      3'h2,       7'h23   )\
    `DBG_INSTR_TRACE("BEQ",    7'h00,      3'h0,       7'h63   )\ // --- B-Type ---
    `DBG_INSTR_TRACE("BNE",    7'h00,      3'h1,       7'h63   )\
    `DBG_INSTR_TRACE("BLT",    7'h00,      3'h4,       7'h63   )\
    `DBG_INSTR_TRACE("BGE",    7'h00,      3'h5,       7'h63   )\
    `DBG_INSTR_TRACE("BLTU",   7'h00,      3'h6,       7'h63   )\
    `DBG_INSTR_TRACE("BGEU",   7'h00,      3'h7,       7'h63   )\
    `DBG_INSTR_TRACE("LUI",    7'h00,      3'h0,       7'h37   )\ // --- U-Type ---
    `DBG_INSTR_TRACE("AUIPC",  7'h00,      3'h0,       7'h17   )\
    `DBG_INSTR_TRACE("JAL",    7'h00,      3'h0,       7'h6f   )  // --- J-Type ---
`define DBG_INSTR_TRACE_OP_FMT(name, opcode, rs1, rs2, rd, imm)                                                 \
         if (opcode == `R)       $display("    INSTRUCTION: %s x%0d, x%0d, x%0d", name, rd, rs1, rs2);          \
    else if (opcode == `I_JUMP)  $display("    INSTRUCTION: %s x%0d, %0d", name, rd, imm);                      \
    else if (opcode == `I_LOAD)  $display("    INSTRUCTION: %s x%0d, %0d(x%0d)", name, rd, imm, rs1);           \
    else if (opcode == `I_ARITH) $display("    INSTRUCTION: %s x%0d, x%0d, %0d", name, rd, rs1, imm);           \
    else if (opcode == `I_SYS)   $display("    INSTRUCTION: %s", name);                                         \
    else if (opcode == `I_FENCE) $display("    INSTRUCTION: %s", name);                                         \
    else if (opcode == `S)       $display("    INSTRUCTION: %s x%0d, %0d(x%0d)", name, rs2, imm, rs1);          \
    else if (opcode == `B)       $display("    INSTRUCTION: %s x%0d, x%0d, %0d", name, rs1, rs2, imm);          \
    else if (opcode == `U_LUI)   $display("    INSTRUCTION: %s x%0d, %0d", name, rd, imm);                      \
    else if (opcode == `U_AUIPC) $display("    INSTRUCTION: %s x%0d, %0d", name, rd, imm);                      \
    else if (opcode == `J)       $display("    INSTRUCTION: %s x%0d, %0d", name, rd, imm);
`define DBG_INSTR_TRACE_PRINT(instrReg, IMM)                                                                     \
    case ({`FUNCT7(instrReg), `FUNCT3(instrReg), `OPCODE(instrReg)})                                             \
    `define DBG_INSTR_TRACE(instr, funct7, funct3, opcode) {funct7, funct3, opcode} : begin                     \\
        `DBG_INSTR_TRACE_OP_FMT(instr, opcode, `RS1(instrReg), `RS2(instrReg), `RD(instrReg), IMM)              \\
        end                                                                                                      \
    `DBG_INSTR_TRACES                                                                                            \
    `undef DBG_INSTR_TRACE                                                                                       \
    default : case ({`FUNCT3(instrReg), `OPCODE(instrReg)})                                                      \
        `define DBG_INSTR_TRACE(instr, funct7, funct3, opcode) {funct3, opcode} : begin                         \\
            `DBG_INSTR_TRACE_OP_FMT(instr, opcode, `RS1(instrReg), `RS2(instrReg), `RD(instrReg), IMM)          \\
            end                                                                                                  \
        `DBG_INSTR_TRACES                                                                                        \
        `undef DBG_INSTR_TRACE                                                                                   \
        default: case (`OPCODE(instrReg))                                                                        \
            `define DBG_INSTR_TRACE(instr, funct7, funct3, opcode) opcode : begin                               \\
                `DBG_INSTR_TRACE_OP_FMT(instr, opcode, `RS1(instrReg), `RS2(instrReg), `RD(instrReg), IMM)      \\
                end                                                                                              \
            `DBG_INSTR_TRACES                                                                                    \
            default : $display("    INSTRUCTION: Invalid instruction! ( 0x%08h )", instrReg);                    \
            endcase                                                                                              \
        endcase                                                                                                  \
    endcase                                                                                                      \

`endif // TYPES_VH