// RV32I Opcode types (lower 2 bits are always '11' - ignoring)
`define R       5'b01100 // _11
`define I_JUMP  5'b11001 // _11
`define I_LOAD  5'b00000 // _11
`define I_ARITH 5'b00100 // _11
`define I_SYS   5'b11100 // _11
`define I_SYNC  5'b00011 // _11
`define S       5'b01000 // _11
`define B       5'b11000 // _11
`define U_LUI   5'b01101 // _11
`define U_AUIPC 5'b00101 // _11
`define J       5'b11011 // _11
