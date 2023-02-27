// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ImmGen (
    input       [31:0]      i_instr,
    output reg  [XLEN-1:0]  o_imm
);
    parameter   XLEN  = 32;
    localparam  U_EXT = XLEN-32;
    localparam  S_EXT = XLEN-12;
    localparam  B_EXT = XLEN-12;
    localparam  I_EXT = XLEN-12;
    localparam  J_EXT = XLEN-20;

    always @* begin
        case (`OPCODE(i_instr))
            `U_LUI, `U_AUIPC    : o_imm = {{U_EXT{i_instr[31]}}, i_instr[31:12], 12'd0};
            `S                  : o_imm = {{S_EXT{i_instr[31]}}, i_instr[31:25], i_instr[11:8], i_instr[7]};
            `B                  : o_imm = {{B_EXT{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
            `J                  : o_imm = {{J_EXT{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'd0};
            default             : o_imm = {{I_EXT{i_instr[31]}}, i_instr[31:20]}; // I-type
        endcase
    end
endmodule
