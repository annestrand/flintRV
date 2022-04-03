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

// Integer ALU Types (encoded from funct3)
`define ADD         3'b000 // funct7[6] == 0
`define SUB         3'b000 // funct7[6] == 1
`define SLL         3'b001
`define XOR         3'b100
`define SRL         3'b101 // funct7[6] == 0
`define SRA         3'b101 // funct7[6] == 1
`define OR          3'b110
`define AND         3'b111

// Forward select
`define NO_FWD      2'b00
`define FWD_MEM     2'b01
`define FWD_WB      2'b10

// ALU operand select
`define FROM_REG    1'b0
`define FROM_PC     1'b1 // ~~~ Operand A ~~~
`define FROM_IMM    1'b1 // ~~~ Operand B ~~~