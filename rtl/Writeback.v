// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module Writeback (
    input       [2:0]       i_funct3    /*verilator public*/,
    input       [XLEN-1:0]  i_dataIn    /*verilator public*/,
    output reg  [XLEN-1:0]  o_dataOut   /*verilator public*/
);
    parameter XLEN      /*verilator public*/ = 32;
    localparam L_B_OP   /*verilator public*/ = 3'b000;
    localparam L_H_OP   /*verilator public*/ = 3'b001;
    localparam L_W_OP   /*verilator public*/ = 3'b010;
    localparam L_BU_OP  /*verilator public*/ = 3'b100;
    localparam L_HU_OP  /*verilator public*/ = 3'b101;

    // Just output load-type (w/ - w/o sign-ext) for now
    always @(*) begin
        case (i_funct3)
            L_B_OP  : o_dataOut = {{24{i_dataIn[7]}},   i_dataIn[7:0]};
            L_H_OP  : o_dataOut = {{16{i_dataIn[15]}},  i_dataIn[15:0]};
            L_W_OP  : o_dataOut = i_dataIn;
            L_BU_OP : o_dataOut = {24'd0, i_dataIn[7:0]};
            L_HU_OP : o_dataOut = {16'd0, i_dataIn[15:0]};
            default : o_dataOut = i_dataIn;
        endcase
    end
endmodule
