// Copyright (c) 2023 Austin Annestrand
// Licensed under the MIT License (see LICENSE file).

// Simple testbench to simulate SoC example
module drop32soc_tb;
reg i_clk = 0, i_rst = 0;
wire o_led;

drop32soc DUT(.*);

initial begin
    $dumpfile("drop32soc.vcd");
    $dumpvars;
end

integer i;
initial begin
    for (i=0; i<1000000; i = i + 1) begin
        i_clk <= ~i_clk; #20;
    end
end

endmodule