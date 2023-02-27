// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ALU (
  input         [XLEN-1:0]          i_a,
                                    i_b,
  input         [ALU_OP_WIDTH-1:0]  i_op,
  output reg    [XLEN-1:0]          o_result
);
`ifdef verilator
    `VERILATOR_ALU_EXEC_DEF
`endif
    parameter   XLEN = 32;
    localparam  ALU_OP_WIDTH = 5;

    /* verilator lint_off UNUSEDSIGNAL */
    wire [XLEN:0] ALU_ADDER_result  = i_a + B_in + {{(XLEN){1'b0}}, SUB}; // TODO: Fixme
    /* verilator lint_on UNUSEDSIGNAL  */
    wire [XLEN-1:0] B_in            = i_op == `ALU_EXEC_ADD4A ? CONST_4 : SUB ? ~i_b : i_b;
    wire [XLEN-1:0] ALU_XOR_result  = i_a ^ i_b;
    wire [XLEN-1:0] CONST_4         = {{(XLEN-3){1'b0}}, 3'd4};
    wire SUB                        = ~i_op[4] && i_op[3]; // Encoding 01000-01111 of ALU exec/op to SUB on adder unit
    wire SLT                        = $signed(i_a) < $signed(i_b);
    wire SLTU                       = i_a < i_b;

    always @(*) begin
        case (i_op)
            default         : o_result = ALU_ADDER_result[31:0];
            `ALU_EXEC_AND   : o_result = i_a & i_b;
            `ALU_EXEC_OR    : o_result = i_a | i_b;
            `ALU_EXEC_XOR   : o_result = ALU_XOR_result;
            `ALU_EXEC_SLL   : o_result = i_a << i_b[4:0];
            `ALU_EXEC_SRL   : o_result = i_a >> i_b[4:0];
            `ALU_EXEC_SRA   : o_result = $signed(i_a) >>> i_b[4:0];
            `ALU_EXEC_PASSB : o_result = i_b;
            `ALU_EXEC_EQ    : o_result = {31'd0, ~|ALU_XOR_result};
            `ALU_EXEC_NEQ   : o_result = {31'd0, ~(~|ALU_XOR_result)};
            `ALU_EXEC_SLT   : o_result = {31'd0,  SLT};
            `ALU_EXEC_SGTE  : o_result = {31'd0, ~SLT};
            `ALU_EXEC_SLTU  : o_result = {31'd0,  SLTU};
            `ALU_EXEC_SGTEU : o_result = {31'd0, ~SLTU};
        endcase
    end
endmodule
