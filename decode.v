`include "types.v"

module ImmGen
(
    input   [21:0]signExt,
    input   [4:0]opcode,
    input   [31:0]instr,
    output  reg [31:0]imm
);
    always @(*) begin
        case (opcode)
        // Non-immediate cases
            default: imm = 32'd0;
        // Immediate cases
            `I_JUMP, `I_LOAD, `I_ARITH, `I_SYS, `I_SYNC: begin
                imm = {signExt, instr[30:25], instr[24:21], instr[20]};
            end
            `S: imm = {signExt, instr[30:25], instr[11:8], instr[7]};
            `B: imm = {signExt[21:1], instr[7], instr[30:25], instr[11:8], 1'd0};
            `U_LUI, `U_AUIPC: begin
                imm = {signExt[21], instr[30:20], instr[19:12], 12'd0};
            end
            `J: imm = {signExt[21:10], instr[19:12], instr[20], instr[30:25], instr[24:21], 1'd0};
        endcase
    end

initial begin $dumpfile("../sim_build/ImmGen.vcd"); $dumpvars(0,ImmGen); end
endmodule

// ====================================================================================================================

