// Copyright (c) 2023 - present, Austin Annestrand
// Licensed under the MIT License (see LICENSE file).

// Simple testbench to simulate SoC example
module flintRVsoc_tb;
reg i_clk = 0, i_rst = 0;
wire o_led;

flintRVsoc DUT(.*);

initial begin
    $dumpfile("flintRVsoc.vcd");
    $dumpvars;
end

integer i;
initial begin
    for (i=0; i<1000000; i = i + 1) begin
        i_clk <= ~i_clk; #20;
    end
end

endmodule