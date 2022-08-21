module bootrom (
    input                           i_clk, i_en,
    input       [ADDR_WIDTH-1:0]    i_addr,
    output reg  [DATA_WIDTH-1:0]    o_data
);
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;
    parameter MEMFILE = "init.mem";
    reg [DATA_WIDTH-1:0] rom [2**ADDR_WIDTH-1:0];

    // Load mem file values into "synchronous ROM" - then read if enabled
    initial $readmemh(MEMFILE, rom);
    always @(posedge i_clk) begin if(i_en) data <= rom[i_addr]; end

endmodule