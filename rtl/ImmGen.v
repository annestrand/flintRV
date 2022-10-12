`include "types.vh"

module ImmGen (
    input       [31:0]      i_instr,
    output reg  [XLEN-1:0]  o_imm
);
    parameter XLEN = 32;

    always @* begin
        case (`OPCODE(i_instr))
            default  : o_imm = 32'hffffffff;
        // Immediate cases
            `I_JUMP  ,
            `I_LOAD  : o_imm = {{21{i_instr[31]}}, i_instr[30:20]};
            `I_ARITH : o_imm = `IS_SHIFT_IMM(i_instr) ?
                        {{27{i_instr[31]}}, i_instr[24:20]} : {{21{i_instr[31]}}, i_instr[30:20]};
            `S       : o_imm = {{21{i_instr[31]}}, i_instr[30:25], i_instr[11:8], i_instr[7]};
            `B       : o_imm = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
            `U_LUI   ,
            `U_AUIPC : o_imm = {i_instr[31], i_instr[30:20], i_instr[19:12], 12'd0};
            `J       : o_imm = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'd0};
        endcase
    end
endmodule
