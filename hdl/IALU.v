`include "types.vh"

module IALU (
  input         [WIDTH-1:0]         a, b,   // input operands
  input         [ALU_OP_WIDTH-1:0]  op,     // ALU operation
  output reg    [WIDTH-1:0]         result  // ALU output
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

    // Add/Sub logic
    assign {cflag, ALU_ADDER_result[WIDTH-1:0]} = a + B_in + {{(WIDTH){1'b0}}, SUB};

    always @(*) begin
        // --- ALU internal op setup ---
        case (op)
            `OP_SUB,
            `OP_SLT,
            `OP_SLTU,
            `OP_SGTE,
            `OP_SGTEU   : begin B_in = ~b; SUB = 1;         end
            `OP_ADD4A   : begin B_in = CONST_4; SUB = 0;    end
            default     : begin B_in = b; SUB = 0;          end
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
endmodule
