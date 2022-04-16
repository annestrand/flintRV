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
module IntegerAlu // IALU
(
  input         [WIDTH-1:0]         a, b,   // input operands
  input         [IALU_OP_WIDTH-1:0] op,     // ALU operation
  output reg    [WIDTH-1:0]         result  // ALU output
);
    parameter   WIDTH           = 32;
    parameter   IALU_OP_COUNT   = 8;
    localparam  IALU_OP_WIDTH   = $clog2(IALU_OP_COUNT);
    localparam  CLA_ALT         = 0;

    // Lets use fast adder (CLA) for IALU
    wire [WIDTH-1:0]    IALU_ADDER_result;
    wire                IALU_ADDER_cout;    // Don't currently use this "cout" value (maybe later..?)
    CLA                 IALU_ADDER(a, b, op[CLA_ALT], IALU_ADDER_result, IALU_ADDER_cout);

    always @(*) begin
        case (op)
            default : result = IALU_ADDER_result;
            // Operations
            `OP_ADD    : result = IALU_ADDER_result;
            `OP_SUB    : result = IALU_ADDER_result;
            `OP_AND    : result = a & b;
            `OP_OR     : result = a | b;
            `OP_XOR    : result = a ^ b;
            `OP_SLL    : result = a << b;
            `OP_SRL    : result = a >> b;
            `OP_SRA    : result = a >>> b;
        endcase
    end
endmodule
