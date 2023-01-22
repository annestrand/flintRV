// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ALU (
  input         [XLEN-1:0]          i_a         /*verilator public*/,
                                    i_b         /*verilator public*/,
  input         [ALU_OP_WIDTH-1:0]  i_op        /*verilator public*/,
  output reg    [XLEN-1:0]          o_result    /*verilator public*/,
  output                            o_eflag     /*verilator public*/,
  output                            o_cflag     /*verilator public*/,
  output                            o_lflag     /*verilator public*/
);
    parameter   XLEN            /*verilator public*/ = 32;
    localparam  ALU_OP_WIDTH    /*verilator public*/ = 5;

    wire [XLEN-1:0] A_in                /*verilator public*/;
    wire [XLEN-1:0] B_in                /*verilator public*/;
    wire [XLEN-1:0] ALU_ADDER_result    /*verilator public*/;
    wire [XLEN-1:0] ALU_XOR_result      /*verilator public*/;
    wire [XLEN-1:0] CONST_4             /*verilator public*/;
    wire            cflag               /*verilator public*/; // Catch unsigned overflow for SLTU/SGTEU cases
    wire            SUB                 /*verilator public*/;
    wire            SLT                 /*verilator public*/;
    wire            lt_bit              /*verilator public*/;

    assign CONST_4          = {{(XLEN-3){1'b0}}, 3'd4};
    assign SLT              = ~(i_a[XLEN-1] ^ i_b[XLEN-1]) ? ALU_ADDER_result[XLEN-1] : i_a[XLEN-1];
    assign SUB              = ~i_op[4] && i_op[3]; // Encoding 01000 - 01111 of ALU exec/op to SUB on adder unit
    assign lt_bit           = i_op == `ALU_EXEC_SLT ? SLT : ~cflag;

    // Adder unit input logic
    assign A_in = i_op == `ALU_EXEC_PASSB ? {XLEN{1'b0}} : i_a;
    assign B_in = i_op == `ALU_EXEC_ADD4A ? CONST_4 : SUB ? ~i_b : i_b;

    // ADD/SUB and XOR logic
    assign {cflag, ALU_ADDER_result[XLEN-1:0]}  = A_in + B_in + {{(XLEN){1'b0}}, SUB};
    assign ALU_XOR_result                       = i_a ^ i_b;

    always @(*) begin
        case (i_op)
            default                         : o_result = ALU_ADDER_result;
            `ALU_EXEC_XOR                   : o_result = ALU_XOR_result;
            `ALU_EXEC_AND                   : o_result = i_a & i_b;
            `ALU_EXEC_OR                    : o_result = i_a | i_b;
            `ALU_EXEC_SLL                   : o_result = i_a << i_b[4:0];
            `ALU_EXEC_SRL                   : o_result = i_a >> i_b[4:0];
            `ALU_EXEC_SRA                   : o_result = $signed(i_a) >>> i_b[4:0];
            `ALU_EXEC_SLT, `ALU_EXEC_SLTU   : o_result = {31'd0, lt_bit};
        endcase
    end

    // Flag outputs - eflag:[A == B], cflag:[Carry Bit Set], lflag:[A < B]
    assign o_eflag = ~|ALU_XOR_result;
    assign o_cflag = cflag;
    assign o_lflag = SLT;

endmodule
