// uCode instruction list
// [ Usage ]:
//
//      `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
//          < define_expr >
//      `include ucode.vh
//      `undef INSTR
//
// ====================================================================================================================
// Instruction list:
//     NAME    ISA        UC      EXEC    EXEC  EXEC  LD/SD   MEM MEM REG M2R BRA JMP
//             ENCODE     ENCODE  OP      A     B     EXT     R   W   W
`INSTR(LB,     17'd3,     'd0,    `ADD,   `REG, `IMM, `EXTB,  `Y, `N, `Y, `Y, `N, `N)
`INSTR(FENCE,  17'd15,    'd1,    `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N)
`INSTR(ADDI,   17'd19,    'd2,    `ADD,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(AUIPC,  17'd23,    'd3,    `ADD,   `PC , `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SB,     17'd35,    'd4,    `ADD,   `REG, `IMM, `EXTUB, `N, `Y, `N, `N, `N, `N)
`INSTR(ADD,    17'd51,    'd5,    `ADD,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(LUI,    17'd55,    'd6,    `PASSB, `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BEQ,    17'd99,    'd7,    `EQ,    `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(JALR,   17'd103,   'd8,    `ADD4A, `PC,  `REG, `NOEXT, `N, `N, `N, `N, `N, `Y)
`INSTR(JAL,    17'd111,   'd9,    `ADD4A, `PC,  `REG, `NOEXT, `N, `N, `N, `N, `N, `Y)
`INSTR(ECALL,  17'd115,   'd10,   `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N)
`INSTR(LH,     17'd131,   'd11,   `ADD,   `REG, `IMM, `EXTH,  `Y, `N, `Y, `Y, `N, `N)
`INSTR(SLLI,   17'd147,   'd12,   `SLL,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SH,     17'd163,   'd13,   `ADD,   `REG, `IMM, `EXTUH, `N, `Y, `N, `N, `N, `N)
`INSTR(SLL,    17'd179,   'd14,   `SLL,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BNE,    17'd227,   'd15,   `NEQ,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(LW,     17'd259,   'd16,   `ADD,   `REG, `IMM, `NOEXT, `Y, `N, `Y, `Y, `N, `N)
`INSTR(SLTI,   17'd275,   'd17,   `SLT,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SW,     17'd291,   'd18,   `ADD,   `REG, `IMM, `NOEXT, `N, `Y, `N, `N, `N, `N)
`INSTR(SLT,    17'd307,   'd19,   `SLT,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SLTIU,  17'd403,   'd20,   `SLTU,  `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SLTU,   17'd435,   'd21,   `SLTU,  `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(LBU,    17'd515,   'd22,   `ADD,   `REG, `IMM, `EXTUB, `Y, `N, `Y, `Y, `N, `N)
`INSTR(XORI,   17'd531,   'd23,   `XOR,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(XOR,    17'd563,   'd24,   `XOR,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BLT,    17'd611,   'd25,   `SLT,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(LHU,    17'd643,   'd26,   `ADD,   `REG, `IMM, `EXTUH, `Y, `N, `Y, `Y, `N, `N)
`INSTR(SRLI,   17'd659,   'd27,   `SRL,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SRL,    17'd691,   'd28,   `SRL,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BGE,    17'd739,   'd29,   `SGTE,  `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(ORI,    17'd787,   'd30,   `OR,    `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(OR,     17'd819,   'd31,   `OR,    `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BLTU,   17'd867,   'd32,   `SLTU,  `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(ANDI,   17'd915,   'd33,   `AND,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(AND,    17'd947,   'd34,   `AND,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(BGEU,   17'd995,   'd35,   `SGTEU, `REG, `REG, `NOEXT, `N, `N, `N, `N, `Y, `N)
`INSTR(EBREAK, 17'd1139,  'd36,   `ADD,   `REG, `REG, `NOEXT, `N, `N, `N, `N, `N, `N)
`INSTR(SUB,    17'd32819, 'd37,   `SUB,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SRAI,   17'd33427, 'd38,   `SRA,   `REG, `IMM, `NOEXT, `N, `N, `Y, `N, `N, `N)
`INSTR(SRA,    17'd33459, 'd39,   `SRA,   `REG, `REG, `NOEXT, `N, `N, `Y, `N, `N, `N)