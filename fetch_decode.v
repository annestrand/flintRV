`include "types.v"

module ImmGen
(
    input       [31:0]  instr,
    output reg  [31:0]  imm
);
    always @(*) begin
        case (instr[6:2])
            default: imm = 32'd0;
        // Immediate cases
            `I_JUMP, `I_LOAD, `I_ARITH, `I_SYS, `I_SYNC: begin
                imm = {22{instr[31]}, instr[30:25], instr[24:21], instr[20]};
            end
            `S: imm = {22{instr[31]}, instr[30:25], instr[11:8], instr[7]};
            `B: imm = {21{instr[31]}, instr[7], instr[30:25], instr[11:8], 1'd0};
            `U_LUI, `U_AUIPC: begin
                imm = {instr[31], instr[30:20], instr[19:12], 12'd0};
            end
            `J: imm = {12{instr[31]}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'd0};
        endcase
    end

endmodule