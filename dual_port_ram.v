// ====================================================================================================================
module DualPortRam
(
    input                           clk, we,
    input       [(DATA_WIDTH-1):0]  dataIn,
    input       [(ADDR_WIDTH-1):0]  rAddr, wAddr,
    output reg  [(DATA_WIDTH-1):0]  q
);
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;

    reg [DATA_WIDTH-1:0] bram [2**ADDR_WIDTH-1:0];

    integer i;
    initial begin
        for (i=0; i<32; i=i+1) begin
            bram[i] = 32'd0;
        end
        q = 32'd0;
    end

    always @ (posedge clk) begin
        if (we) begin
            bram[wAddr] <= dataIn;
        end
        q <= bram[rAddr];
    end
endmodule