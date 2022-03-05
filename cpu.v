
module alu
#(parameter WIDTH = 8)
(
  input [WIDTH-1:0]a,b,
  input [3:0]sel,
  output reg [WIDTH-1:0]f,
  output zflag
);
    localparam [3:0]
        ADD         = 4'd0,
        SUB         = 4'd1,
        AND         = 4'd2,
        OR          = 4'd3,
        XOR         = 4'd4,
        SLL         = 4'd5,
        SRL         = 4'd6,
        SRA         = 4'd7;

    always@* begin
        case (sel)
            ADD : f = a + b;
            SUB : f = a + ((~b) + 1);
            AND : f = a & b;
            OR  : f = a | b;
            XOR : f = a ^ b;
            SLL : f = a << b;
            SRL : f = a >> b;
            SRA : f = a >>> b;
        endcase
    end
    assign zflag = (f == 'd0) ? (1) : (0);
endmodule

// --------------------------------------------------------------------------------------------------------------------
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
localparam [1:0] IF_ID = 2'd0, ID_EX = 2'd1, EX_WB = 2'd2;
reg [31:0]PC[IF_ID:EX_WB];
reg [16:0]ucodeCtrlAddr[IF_ID];

always@(posedge clk) begin
    // fetch
    ucodeCtrlAddr <= {funct7, funct3, opcode};

    // decode

    // execute

    // mem/wb
end

endmodule