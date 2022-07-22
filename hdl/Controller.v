`include "types.vh"

module Controller (
    input       [6:0]   i_opcode,
    output  reg [3:0]   o_aluOp,
    output  reg         o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp
);
    // Main ctrl. signals
    always @* begin
        case (i_opcode)
            // Invalid opcode - set all lines to 0
            default     : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = 11'd0;
            // Instruction formats
            `R          : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `R_CTRL;
            `I_JUMP     : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `I_JUMP_CTRL;
            `I_LOAD     : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `I_LOAD_CTRL;
            `I_ARITH    : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `I_ARITH_CTRL;
            `I_SYS      : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `I_SYS_CTRL;
            `I_FENCE    : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `I_FENCE_CTRL;
            `S          : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `S_CTRL;
            `B          : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `B_CTRL;
            `U_LUI      : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `U_LUI_CTRL;
            `U_AUIPC    : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `U_AUIPC_CTRL;
            `J          : {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp} = `J_CTRL;
        endcase
    end
endmodule
