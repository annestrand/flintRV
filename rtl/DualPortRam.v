// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

module DualPortRam (
    input                           i_clk,
                                    i_we,
    input       [(XLEN-1):0]        i_dataIn,
    input       [(ADDR_WIDTH-1):0]  i_rAddr,
                                    i_wAddr,
    output reg  [(XLEN-1):0]        o_q
);
    parameter XLEN                          /*verilator public*/ = 32;
    parameter ADDR_WIDTH                    /*verilator public*/ = 5;
    reg [XLEN-1:0] ram [2**ADDR_WIDTH-1:0]  /*verilator public*/;

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
