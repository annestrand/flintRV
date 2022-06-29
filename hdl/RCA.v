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
