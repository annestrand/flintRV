
module alu
#(parameter WIDTH = 32)
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

    always @(*) begin
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
