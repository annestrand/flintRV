// RV32I Opcode types
`define R           7'b0110011
`define I_JUMP      7'b1100111
`define I_LOAD      7'b0000011
`define I_ARITH     7'b0010011
`define I_SYS       7'b1110011
`define I_FENCE     7'b0001111
`define S           7'b0100011
`define B           7'b1100011
`define U_LUI       7'b0110111
`define U_AUIPC     7'b0010111
`define J           7'b1101111

// Instruction fields
`define OPCODE(x)   x[6:0]
`define RD(x)       x[11:7]
`define FUNCT3(x)   x[14:12]
`define RS1(x)      x[19:15]
`define RS2(x)      x[24:20]
`define FUNCT7(x)   x[31:25]

// IALU Types
`define ADD         5'd0
`define SUB         5'd1
`define SLL         5'd2
`define XOR         5'd3
`define SRL         5'd4
`define SRA         5'd5
`define OR          5'd6
`define AND         5'd7
// Other execute types
`define PASSB       5'd8
`define ADD4A       5'd9
`define EQ          5'd10
`define NEQ         5'd11
`define SLT         5'd12
`define SLTU        5'd13
`define SGTE        5'd14
`define SGTEU       5'd15

// Forward select
`define NO_FWD      2'b00
`define FWD_MEM     2'b01
`define FWD_WB      2'b10

// EXEC operand select
`define REG         1'b0
`define PC          1'b1 // Operand A
`define IMM         1'b1 // Operand B

// Load/store sign-extend select
`define NOEXT       3'd0   // No sign extension (word)
`define EXTB        3'd1   // Sign extend (byte)
`define EXTH        3'd2   // Sign extend (half)
`define EXTUB       3'd3   // No-sign extend (byte)
`define EXTUH       3'd4   // No-sign extend (half)

// Yes/No bit macros
`define Y           1'b0
`define N           1'b1

// Instruction list:
/*   INSTR(NAME,   ISA_ENC,  ENC, EX_OP, EXEA, EXEB, LDEXT,  MEMR, MEMW, REGW, M2R, BRA, JMP)*/
/*                                [5]    [1]   [1]   [3]     [1]   [1]   [1]   [1]  [1] [1] )*/
`define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
    `define NAME ISA_ENC
`define INSTRUCTIONS \
    `INSTR(LB,     17'd3,     'd0,  `ADD,   `REG, `IMM, `EXTB,  `Y, `N, `Y, `Y, `N, `N) \
    `INSTR(FENCE,  17'd15,    'd1,  `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N) \
    `INSTR(ADDI,   17'd19,    'd2,  `ADD,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(AUIPC,  17'd23,    'd3,  `ADD,   `PC , `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SB,     17'd35,    'd4,  `ADD,   `REG, `IMM, `EXTUB, `N, `Y, `N, `N, `N, `N) \
    `INSTR(ADD,    17'd51,    'd5,  `ADD,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(LUI,    17'd55,    'd6,  `PASSB, `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BEQ,    17'd99,    'd7,  `EQ,    `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(JALR,   17'd103,   'd8,  `ADD4A, `PC,  `REG, `NOEXT, `N, `N, `N, `N, `N, `Y) \
    `INSTR(JAL,    17'd111,   'd9,  `ADD4A, `PC,  `REG, `NOEXT, `N, `N, `N, `N, `N, `Y) \
    `INSTR(ECALL,  17'd115,   'd10, `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N) \
    `INSTR(LH,     17'd131,   'd11, `ADD,   `REG, `IMM, `EXTH,  `Y, `N, `Y, `Y, `N, `N) \
    `INSTR(SLLI,   17'd147,   'd12, `SLL,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SH,     17'd163,   'd13, `ADD,   `REG, `IMM, `EXTUH, `N, `Y, `N, `N, `N, `N) \
    `INSTR(SLL,    17'd179,   'd14, `SLL,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BNE,    17'd227,   'd15, `NEQ,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(LW,     17'd259,   'd16, `ADD,   `REG, `IMM, `NOEXT, `Y, `N, `Y, `Y, `N, `N) \
    `INSTR(SLTI,   17'd275,   'd17, `SLT,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SW,     17'd291,   'd18, `ADD,   `REG, `IMM, `NOEXT, `N, `Y, `N, `N, `N, `N) \
    `INSTR(SLT,    17'd307,   'd19, `SLT,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SLTIU,  17'd403,   'd20, `SLTU,  `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SLTU,   17'd435,   'd21, `SLTU,  `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(LBU,    17'd515,   'd22, `ADD,   `REG, `IMM, `EXTUB, `Y, `N, `Y, `Y, `N, `N) \
    `INSTR(XORI,   17'd531,   'd23, `XOR,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(XOR,    17'd563,   'd24, `XOR,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BLT,    17'd611,   'd25, `SLT,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(LHU,    17'd643,   'd26, `ADD,   `REG, `IMM, `EXTUH, `Y, `N, `Y, `Y, `N, `N) \
    `INSTR(SRLI,   17'd659,   'd27, `SRL,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SRL,    17'd691,   'd28, `SRL,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BGE,    17'd739,   'd29, `SGTE,  `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(ORI,    17'd787,   'd30, `OR,    `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(OR,     17'd819,   'd31, `OR,    `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BLTU,   17'd867,   'd32, `SLTU,  `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(ANDI,   17'd915,   'd33, `AND,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(AND,    17'd947,   'd34, `AND,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(BGEU,   17'd995,   'd35, `SGTEU, `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N) \
    `INSTR(EBREAK, 17'd1139,  'd36, `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N) \
    `INSTR(SUB,    17'd32819, 'd37, `SUB,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SRAI,   17'd33427, 'd38, `SRA,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N) \
    `INSTR(SRA,    17'd33459, 'd39, `SRA,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)

`INSTRUCTIONS
`undef INSTR
