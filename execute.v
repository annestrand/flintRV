`include "types.vh"

module FullAdder (
    input   a, b, cin,
    output  sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// ====================================================================================================================
module RCA ( // Ripple-Carry Adder (slow but more resource efficient)
    input   [WIDTH-1:0] a, b,   // Operand inputs
    input               subEn,  // Use as subtractor
    output  [WIDTH-1:0] result, // Output
    output              cout    // Carry bit
);
    parameter WIDTH = 32;

    genvar  i;
    wire    [WIDTH:0] c;

    // If subtracting, we need to invert "b"
    wire    [WIDTH-1:0] finalB;
    assign  finalB = subEn ? ~b : b;
    // Cin and Cout
    assign  c[0] = subEn;
    assign  cout = c[WIDTH];

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_FA
            FullAdder FA(a[i], finalB[i], c[i], result[i], c[i+1]);
        end
    endgenerate
endmodule

// ====================================================================================================================
module CLA (  // Carry Lookahead Adder (fast but more resource expensive)
    input   [WIDTH-1:0] a, b,   // Operand inputs
    input               subEn,  // Use as subtractor
    output  [WIDTH-1:0] result, // Output
    output              cout    // Carry bit
);
    parameter WIDTH = 32;

    genvar  i;
    wire    [WIDTH-1:0] p, g;
    wire    [WIDTH:0]   c;

    // If subtracting, we need to invert "b"
    wire    [WIDTH-1:0] finalB;
    assign  finalB = subEn ? ~b : b;
    // Cin and Cout
    assign  c[0] = subEn;
    assign  cout = c[WIDTH];

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_FA
            FullAdder FA(.a(a[i]), .b(finalB[i]), .cin(c[i]), .sum(result[i]), .cout(/* No Cout */));
        end
    endgenerate
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_PG
            assign p[i]   = a[i] || finalB[i];
            assign g[i]   = a[i] && finalB[i];
            assign c[i+1] = g[i] || (p[i] && c[i]);
        end
    endgenerate
endmodule

// ====================================================================================================================
module AluControl (
    input       [3:0] aluOp,
    input       [6:0] funct7,
    input       [2:0] funct3,
    output reg  [4:0] aluControl
);
    localparam SRAI = 5;
    always @* begin
        case (aluOp)
            // ~~~ U/J-Type formats ~~~
            `ALU_OP_J           : aluControl = `OP_ADD4A;
            `ALU_OP_U_LUI       : aluControl = `OP_PASSB;
            `ALU_OP_U_AUIPC     : aluControl = `OP_ADD;
            // ~~~ I/S/B-Type formats ~~~
            `ALU_OP_S           : aluControl = `OP_ADD;
            `ALU_OP_I_SYS       : aluControl = `OP_ADD;
            `ALU_OP_I_LOAD      : aluControl = `OP_ADD;
            `ALU_OP_I_JUMP      : aluControl = `OP_ADD4A;
            `ALU_OP_I_FENCE     : aluControl = `OP_ADD;
            `ALU_OP_B           : case (funct3)
                3'b000          : aluControl = `OP_EQ;
                3'b001          : aluControl = `OP_NEQ;
                3'b100          : aluControl = `OP_SLT;
                3'b101          : aluControl = `OP_SGTE;
                3'b110          : aluControl = `OP_SLTU;
                3'b111          : aluControl = `OP_SGTEU;
                default         : aluControl = 5'b00000;
            endcase
            `ALU_OP_I_ARITH     : case (funct3)
                3'b000          : aluControl = `OP_ADD;
                3'b010          : aluControl = `OP_SLT;
                3'b011          : aluControl = `OP_SLTU;
                3'b100          : aluControl = `OP_XOR;
                3'b110          : aluControl = `OP_OR;
                3'b111          : aluControl = `OP_AND;
                3'b001          : aluControl = `OP_SLL;
                3'b101          : aluControl =  funct7[SRAI] ? `OP_SRA : `OP_SRL;
                default         : aluControl = 5'b00000;
            endcase
            // ~~~ R-Type format ~~~
            default             : case ({funct7, funct3})
                10'b0000000_000 : aluControl = `OP_ADD;
                10'b0100000_000 : aluControl = `OP_SUB;
                10'b0000000_001 : aluControl = `OP_SLL;
                10'b0000000_010 : aluControl = `OP_SLT;
                10'b0000000_011 : aluControl = `OP_SLTU;
                10'b0000000_100 : aluControl = `OP_XOR;
                10'b0000000_101 : aluControl = `OP_SRL;
                10'b0100000_101 : aluControl = `OP_SRA;
                10'b0000000_110 : aluControl = `OP_OR;
                10'b0000000_111 : aluControl = `OP_AND;
                default         : aluControl = 5'b00000;
            endcase
        endcase
    end
endmodule

// ====================================================================================================================
module Alu (
  input         [WIDTH-1:0]         a, b,   // input operands
  input         [ALU_OP_WIDTH-1:0]  op,     // ALU operation
  output reg    [WIDTH-1:0]         result, // ALU output
  output                            zflag   // Zero-flag
);
    parameter                       WIDTH               = 32;
    localparam                      ALU_OP_WIDTH        = 5;

    wire                            cflag; // Catch unsigned overflow for SLTU/SGTEU cases
    wire        [WIDTH-1:0]         ALU_ADDER_result;
    wire        [WIDTH-1:0]         ALU_XOR_result      = a ^ b;
    wire        [WIDTH-1:0]         CONST_4             = {{(WIDTH-3){1'b0}}, 3'd4};
    reg                             ALU_SLT;
    reg                             SUB;
    reg         [WIDTH-1:0]         B_in;
    // Using fast adder (CLA) for ALU
    CLA                             ALU_ADDER(a, B_in, SUB, ALU_ADDER_result, cflag);

    always @(*) begin
        // --- ALU internal op setup ---
        case (op)
            default     : begin B_in = b; SUB = 0;          end
            `OP_SUB     : begin B_in = b; SUB = 1;          end
            `OP_SLT,
            `OP_SLTU,
            `OP_SGTE,
            `OP_SGTEU   : begin B_in = b; SUB = 1;          end
            `OP_ADD4A   : begin B_in = CONST_4; SUB = 0;    end
        endcase
        // --- SLT setup ---
        case ({a[WIDTH-1], b[WIDTH-1]})
            2'b00       : ALU_SLT = ALU_ADDER_result[31];
            2'b01       : ALU_SLT = 1'b0; // a > b since a is pos.
            2'b10       : ALU_SLT = 1'b1; // a < b since a is neg.
            2'b11       : ALU_SLT = ALU_ADDER_result[31];
        endcase
        // --- Main operations ---
        case (op)
            default     : result = ALU_ADDER_result;
            `OP_ADD     : result = ALU_ADDER_result;
            `OP_SUB     : result = ALU_ADDER_result;
            `OP_AND     : result = a & b;
            `OP_OR      : result = a | b;
            `OP_XOR     : result = ALU_XOR_result;
            `OP_SLL     : result = a << b;
            `OP_SRL     : result = a >> b;
            `OP_SRA     : result = $signed(a) >>> b;
            `OP_PASSB   : result = b;
            `OP_ADD4A   : result = ALU_ADDER_result;
            `OP_EQ      : result = {31'd0, ~|ALU_XOR_result};
            `OP_NEQ     : result = {31'd0, ~(~|ALU_XOR_result)};
            `OP_SLT     : result = {31'd0,  ALU_SLT};
            `OP_SGTE    : result = {31'd0, ~ALU_SLT};
            `OP_SLTU    : result = {31'd0, ~cflag};
            `OP_SGTEU   : result = {31'd0,  cflag};
        endcase
    end
    // Zero-flag out
    assign zflag = ~|result;
endmodule

// ====================================================================================================================
module Execute (
    input   [6:0]   funct7,
    input   [2:0]   funct3,
    input   [3:0]   aluOp,
    input   [1:0]   fwdRs1, fwdRs2,
    input           aluSrcA, aluSrcB,
    input   [31:0]  EXEC_rs1, EXEC_rs2, MEM_rd, WB_rd,
    input   [31:0]  PC, IMM,
    output  [31:0]  aluOut, addrGenOut
);

    // Datapath for register forwarding
    reg [31:0] rs1Out, rs2Out;
    always@(*) begin
        case (fwdRs1)
            `NO_FWD     : rs1Out = EXEC_rs1;
            `FWD_MEM    : rs1Out = MEM_rd;
            `FWD_WB     : rs1Out = WB_rd;
            default     : rs1Out = EXEC_rs1;
        endcase
        case (fwdRs2)
            `NO_FWD     : rs2Out = EXEC_rs2;
            `FWD_MEM    : rs2Out = MEM_rd;
            `FWD_WB     : rs2Out = WB_rd;
            default     : rs2Out = EXEC_rs2;
        endcase
    end

    // Datapath for ALU srcs
    wire [31:0] aluSrcAin = (aluSrcA == `PC ) ? PC  : rs1Out;
    wire [31:0] aluSrcBin = (aluSrcB == `IMM) ? IMM : rs2Out;

    // ALU/ALU_Control
    wire [4:0]  aluControl;
    AluControl ALU_CTRL_unit(
        .aluOp      (aluOp),
        .funct7     (funct7),
        .funct3     (funct3),
        .aluControl (aluControl)
    );
    Alu ALU_unit(
        .a      (aluSrcAin),
        .b      (aluSrcBin),
        .op     (aluControl),
        .result (aluOut),
        .zflag  (/* No use for now... */)
    );
    defparam ALU_unit.WIDTH = 32;

    // Address generator
    CLA ADDR_GEN_unit(
        .a      (PC),
        .b      (IMM),
        .subEn  (1'b0),
        .result (addrGenOut),
        .cout   (/* No use for now... */)
    );
endmodule
