// ====================================================================================================================
module DualPortRam (
    input                           clk, we,
    input       [(DATA_WIDTH-1):0]  dataIn,
    input       [(ADDR_WIDTH-1):0]  rAddr, wAddr,
    output reg  [(DATA_WIDTH-1):0]  q
);
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;
    reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

`ifdef SIM
    integer i;
    initial begin
        for (i=0; i<(2**ADDR_WIDTH-1); i=i+1) begin
            ram[i] = {DATA_WIDTH{1'b0}};
        end
        q = {DATA_WIDTH{1'b0}};
    end
`endif // SIM

    always @ (posedge clk) begin
        if (we) begin
            ram[wAddr] <= dataIn;
        end
        q <= ram[rAddr];
    end
endmodule