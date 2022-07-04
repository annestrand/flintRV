`include "types.vh"

module Controller (
    input       [6:0]   opcode,
    output  reg [3:0]   aluOp,
    output  reg         exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp
);
    // Main ctrl. signals
    always @* begin
        case (opcode)
        // Instruction formats
            `R          : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `R_CTRL;
            `I_JUMP     : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_JUMP_CTRL;
            `I_LOAD     : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_LOAD_CTRL;
            `I_ARITH    : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_ARITH_CTRL;
            `I_SYS      : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_SYS_CTRL;
            `I_FENCE    : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_FENCE_CTRL;
            `S          : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `S_CTRL;
            `B          : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `B_CTRL;
            `U_LUI      : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `U_LUI_CTRL;
            `U_AUIPC    : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `U_AUIPC_CTRL;
            `J          : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `J_CTRL;
            // Invalid opcode - set all lines to 0
            default     : {aluOp, exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = 11'd0;
        endcase
    end
endmodule
