`include "types.v"

module IntegerAlu
#(parameter WIDTH = 32)
(
  input         [WIDTH-1:0] a, b,   // input operands
  input         [2:0]       op,     // ALU operation
  input                     opAlt,  // ALU alternate operation modifier bit: ( funct7[6] )
  output reg    [WIDTH-1:0] result, // ALU output
  output                    zflag   // Zero-flag
);
    always @(*) begin
        case (op)
            default : result = a + b;           // TODO: Replace w/ dedicated 2's comp adder/subtractor
            // Operations
            `ADD    : result = a + b;           // TODO: Replace w/ dedicated 2's comp adder/subtractor
            `SUB    : result = a + ((~b) + 1);  // TODO: Replace w/ dedicated 2's comp adder/subtractor
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
