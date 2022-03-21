
module cpu
(
    input   [31:0]instruction, dataIn,
    input   ifValid, memValid,
    output  reg [31:0]pcOut, dataAddr, dataOut,
    output  reg dataWe
);

    wire [6:0]opcode    = instruction[6:0];
    wire [6:0]funct7    = instruction[31:25];
    wire [2:0]funct3    = instruction[14:12];
    wire [4:0]rd        = instruction[11:7];
    wire [4:0]rs1       = instruction[19:15];
    wire [4:0]rs2       = instruction[24:20];

    reg [31:0]regfile[0:31];

    // Pipeline regs
    localparam [1:0]IF_ID = 2'd0, ID_EX = 2'd1, EX_WB = 2'd2;
    reg [31:0]PC[IF_ID:EX_WB];

    always @(posedge clk) begin
        // fetch

        // decode

        // execute

        // mem/wb
    end

endmodule