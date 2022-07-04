`include "types.vh"

module ImmGen (
    input       [31:0]  instr,
    output reg  [31:0]  imm
);
    wire isShiftImm = `IS_SHIFT_IMM(instr);
    always @* begin
        case (`OPCODE(instr))
            default          :   imm = 32'hffffffff;
        // Immediate cases
            `I_JUMP, `I_LOAD :   imm = {{21{instr[31]}}, instr[30:20]};
            `I_ARITH         :   imm = isShiftImm ? {{27{instr[31]}}, instr[24:20]} : {{21{instr[31]}}, instr[30:20]};
            `S               :   imm = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
            `B               :   imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'd0};
            `U_LUI, `U_AUIPC :   imm = {instr[31], instr[30:20], instr[19:12], 12'd0};
            `J               :   imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'd0};
        endcase
    end
endmodule
