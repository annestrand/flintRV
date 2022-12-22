// Copyright (c) 2022 Austin Annestrand
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
