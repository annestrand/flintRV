
module cpu
(
    input       [31:0]  instruction, dataIn,
    input               ifValid, memValid,
    output  reg [31:0]  pcOut, dataAddr, dataOut,
    output  reg         dataWe
);
    localparam  [1:0]   IF_ID = 2'd0, ID_EX = 2'd1, EX_WB = 2'd2;
    // Pipeline regs
    reg         [31:0]  regfile [0:31];
    reg         [31:0]  PC      [IF_ID:EX_WB];

    always @(posedge clk) begin
        // fetch

        // decode

        // execute

        // mem/wb
    end

endmodule