`include "types.v"

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
    input signed    [WIDTH-1:0] a, b,   // Operand inputs
    input                       subEn,  // Use as subtractor
    output signed   [WIDTH-1:0] result, // Output
    output                      cout    // Carry bit
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
    input signed    [WIDTH-1:0] a, b,   // Operand inputs
    input                       subEn,  // Use as subtractor
    output signed   [WIDTH-1:0] result, // Output
    output                      cout    // Carry bit
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
            FullAdder FA(a[i], finalB[i], c[i], result[i], c[i+1]);
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
  input signed      [WIDTH-1:0] a, b,   // input operands
  input             [2:0]       op,     // ALU operation
  input                         opAlt,  // ALU alternate operation modifier bit: ( funct7[6] )
  output reg signed [WIDTH-1:0] result, // ALU output
  output                        zflag   // Zero-flag
);
    parameter WIDTH = 32;

    // Lets use fast adder (CLA) for IALU
    wire [WIDTH-1:0]    IALU_ADDER_result;
    wire                IALU_ADDER_cout;    // Don't currently use this "cout" value (maybe later..?)
    CLA                 IALU_ADDER(a, b, opAlt, IALU_ADDER_result, IALU_ADDER_cout);

    always @(*) begin
        case (op)
            default : result = IALU_ADDER_result;
            // Operations
            `ADD    : result = IALU_ADDER_result;
            `SUB    : result = IALU_ADDER_result;
            `AND    : result = a & b;
            `OR     : result = a | b;
            `XOR    : result = a ^ b;
            `SLL    : result = a << b;
            `SRL    : result = a >> b;          // TODO: Replace with dedicated right shifter
            `SRA    : result = a >>> b;         // TODO: Replace with dedicated right shifter
        endcase
    end
    assign zflag = (result == 'd0) ? 1 : 0;
endmodule
