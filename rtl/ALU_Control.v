// Copyright (c) 2022 Austin Annestrand
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

`include "types.vh"

module ALU_Control (
    input       [3:0] i_aluOp       /*verilator public*/,
    input       [6:0] i_funct7      /*verilator public*/,
    input       [2:0] i_funct3      /*verilator public*/,
    output reg  [4:0] o_aluControl  /*verilator public*/
);
    always @* begin
        case (i_aluOp)
            `ALU_OP_J           ,
            `ALU_OP_I_JUMP      : o_aluControl = `ALU_EXEC_ADD4A;
            `ALU_OP_U_LUI       : o_aluControl = `ALU_EXEC_PASSB;
            `ALU_OP_B           : case (i_funct3)
                3'b000          : o_aluControl = `ALU_EXEC_EQ;
                3'b001          : o_aluControl = `ALU_EXEC_NEQ;
                3'b100          : o_aluControl = `ALU_EXEC_SLT;
                3'b101          : o_aluControl = `ALU_EXEC_SGTE;
                3'b110          : o_aluControl = `ALU_EXEC_SLTU;
                3'b111          : o_aluControl = `ALU_EXEC_SGTEU;
                default         : o_aluControl = `ALU_EXEC_ADD;
            endcase
            `ALU_OP_I_ARITH     : casez ({i_funct7, i_funct3})
                10'b???????_010 : o_aluControl = `ALU_EXEC_SLT;
                10'b???????_011 : o_aluControl = `ALU_EXEC_SLTU;
                10'b???????_100 : o_aluControl = `ALU_EXEC_XOR;
                10'b???????_110 : o_aluControl = `ALU_EXEC_OR;
                10'b???????_111 : o_aluControl = `ALU_EXEC_AND;
                10'b0000000_001 : o_aluControl = `ALU_EXEC_SLL;
                10'b0000000_101 : o_aluControl = `ALU_EXEC_SRL;
                10'b0100000_101 : o_aluControl = `ALU_EXEC_SRA;
                default         : o_aluControl = `ALU_EXEC_ADD;
            endcase
            `ALU_OP_R           : case ({i_funct7, i_funct3})
                10'b0100000_000 : o_aluControl = `ALU_EXEC_SUB;
                10'b0000000_001 : o_aluControl = `ALU_EXEC_SLL;
                10'b0000000_010 : o_aluControl = `ALU_EXEC_SLT;
                10'b0000000_011 : o_aluControl = `ALU_EXEC_SLTU;
                10'b0000000_100 : o_aluControl = `ALU_EXEC_XOR;
                10'b0000000_101 : o_aluControl = `ALU_EXEC_SRL;
                10'b0100000_101 : o_aluControl = `ALU_EXEC_SRA;
                10'b0000000_110 : o_aluControl = `ALU_EXEC_OR;
                10'b0000000_111 : o_aluControl = `ALU_EXEC_AND;
                default         : o_aluControl = `ALU_EXEC_ADD;
            endcase
            // `ALU_OP_I_LOAD, `ALU_OP_S, `ALU_OP_U_AUIPC, `ALU_OP_I_SYS, `ALU_OP_I_FENCE, or (undefined)
            default             : o_aluControl = `ALU_EXEC_ADD;
        endcase
    end
endmodule
