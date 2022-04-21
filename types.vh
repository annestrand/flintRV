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

// Utility macros
`define ENDIAN_SWP_32(x)    {x[7:0],x[15:8],x[23:16],x[31:24]}

// ALU Types
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

// Load/store sign-extend select
`define NOEXT               3'd0    // No sign extension (word)
`define EXTB                3'd1    // Sign extend (byte)
`define EXTH                3'd2    // Sign extend (half)
`define EXTUB               3'd3    // No-sign extend (byte)
`define EXTUH               3'd4    // No-sign extend (half)

// Yes/No bit macros
`define Y                   1'b1
`define N                   1'b0

`endif // TYPES_VH