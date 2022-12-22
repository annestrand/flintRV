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

module DualPortRam (
    input                           i_clk       /*verilator public*/,
                                    i_we        /*verilator public*/,
    input       [(XLEN-1):0]        i_dataIn    /*verilator public*/,
    input       [(ADDR_WIDTH-1):0]  i_rAddr     /*verilator public*/,
                                    i_wAddr     /*verilator public*/,
    output reg  [(XLEN-1):0]        o_q         /*verilator public*/
);
    parameter XLEN          /*verilator public*/ = 32;
    parameter ADDR_WIDTH    /*verilator public*/ = 5;
    reg [XLEN-1:0] ram [2**ADDR_WIDTH-1:0] /*verilator public*/;

    integer i;
    initial begin
        for (i=0; i<(2**ADDR_WIDTH-1); i=i+1) begin
            ram[i] = {XLEN{1'b0}};
        end
    end

    always @ (posedge i_clk) begin
        if (i_we) begin
            ram[i_wAddr] <= i_dataIn;
        end
        o_q <= ram[i_rAddr];
    end
endmodule
