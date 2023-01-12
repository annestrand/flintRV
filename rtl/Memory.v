// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module Memory (
    input       [2:0]       i_funct3    /*verilator public*/,
    input       [XLEN-1:0]  i_dataIn    /*verilator public*/,
    output reg  [XLEN-1:0]  o_dataOut   /*verilator public*/
);
    parameter XLEN      /*verilator public*/ = 32;
    localparam S_B_OP   /*verilator public*/ = 3'b000;
    localparam S_H_OP   /*verilator public*/ = 3'b001;
    localparam S_W_OP   /*verilator public*/ = 3'b010;
    localparam S_BU_OP  /*verilator public*/ = 3'b100;
    localparam S_HU_OP  /*verilator public*/ = 3'b101;

    // Just output store-type (w/ - w/o sign-ext) for now
    always @(*) begin
        case (i_funct3)
            S_B_OP  : o_dataOut = {24'd0, i_dataIn[7:0]};
            S_H_OP  : o_dataOut = {16'd0, i_dataIn[15:0]};
            S_W_OP  : o_dataOut = i_dataIn;
            S_BU_OP : o_dataOut = {24'd0, i_dataIn[7:0]};
            S_HU_OP : o_dataOut = {16'd0, i_dataIn[15:0]};
            default : o_dataOut = i_dataIn;
        endcase
    end
endmodule
