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
