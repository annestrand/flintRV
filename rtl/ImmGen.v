`include "types.vh"

module ImmGen (
    input       [31:0]      i_instr /*verilator public*/,
    output reg  [XLEN-1:0]  o_imm   /*verilator public*/
);
    parameter XLEN /*verilator public*/ = 32;

    always @* begin
        case (`OPCODE(i_instr))
            `U_LUI, `U_AUIPC    : o_imm = {i_instr[31:12], 12'd0};
            `S                  : o_imm = {{21{i_instr[31]}}, i_instr[30:25], i_instr[11:8], i_instr[7]};
            `B                  : o_imm = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
            `J                  : o_imm = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'd0};
            default             : o_imm = {{21{i_instr[31]}}, i_instr[30:20]}; // I-type
        endcase
    end
endmodule
