`include "types.vh"

module IALU_Control (
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
