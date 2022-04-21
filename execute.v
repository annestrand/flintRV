`include "types.vh"

module FullAdder
(
    input   a, b, cin,
    output  sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// ====================================================================================================================
module RCA // Ripple-Carry Adder (slow but more resource efficient)
(
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
        for (i = 0; i < WIDTH; i = i + 1) begin
            FullAdder FA(a[i], finalB[i], c[i], result[i], c[i+1]);
        end
    endgenerate
endmodule

// ====================================================================================================================
module CLA  // Carry Lookahead Adder (fast but more resource expensive)
(
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
        for (i = 0; i < WIDTH; i = i + 1) begin
            FullAdder FA(.a(a[i]), .b(finalB[i]), .cin(c[i]), .sum(result[i]), .cout(/* No Cout */));
        end
    endgenerate
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign p[i]   = a[i] || finalB[i];
            assign g[i]   = a[i] && finalB[i];
            assign c[i+1] = g[i] || (p[i] && c[i]);
        end
    endgenerate
endmodule

// ====================================================================================================================
module Alu
(
  input         [WIDTH-1:0]         a, b,   // input operands
  input         [ALU_OP_WIDTH-1:0]  op,     // ALU operation
  output reg    [WIDTH-1:0]         result, // ALU output
  output                            zflag   // Zero-flag
);
    parameter                       WIDTH               = 32;
    parameter                       ALU_OP_COUNT        = 16;
    localparam                      ALU_OP_WIDTH        = $clog2(ALU_OP_COUNT);

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
            default     : begin B_in = b; SUB = 0; end
            `OP_SUB     : begin B_in = b; SUB = 1; end
            `OP_SLT,
            `OP_SLTU,
            `OP_SGTE,
            `OP_SGTEU   : begin B_in = b; SUB = 1; end
            `OP_ADD4A   : begin B_in = CONST_4; SUB = 0; end
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
