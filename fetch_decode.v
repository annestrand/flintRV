`include "types.vh"

module ImmGen
(
    input       [31:0]  instr,
    output reg  [31:0]  imm
);
    wire [2:0] funct3   = `FUNCT3(instr);
    wire isShiftImm     = ~funct3[1] && funct3[0];
    always @* begin
        case (`OPCODE(instr))
            default          :   imm = 32'd0;
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

// ====================================================================================================================
module Controller
(
    input       [6:0]   opcode,
    output  reg [3:0]   aluOp,
    output  reg         exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp
);
    // Main ctrl. signals
    always @* begin
        case (opcode)
            default     : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = 13'd0; // Invalid opcode
        // Instruction formats
            `R          : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `R_CTRL;
            `I_JUMP     : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_JUMP_CTRL;
            `I_LOAD     : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_LOAD_CTRL;
            `I_ARITH    : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_ARITH_CTRL;
            `I_SYS      : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_SYS_CTRL;
            `I_FENCE    : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `I_FENCE_CTRL;
            `S          : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `S_CTRL;
            `B          : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `B_CTRL;
            `U_LUI      : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `U_LUI_CTRL;
            `U_AUIPC    : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `U_AUIPC_CTRL;
            `J          : {exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp} = `J_CTRL;
        endcase
    end
    // ALU Op signal
    always @* begin
        case (opcode)
            default     : aluOp = 4'd0; // Invalid opcode
        // Instruction formats
            `R          : aluOp = `ALU_OP_R;
            `I_JUMP     : aluOp = `ALU_OP_I_JUMP;
            `I_LOAD     : aluOp = `ALU_OP_I_LOAD;
            `I_ARITH    : aluOp = `ALU_OP_I_ARITH;
            `I_SYS      : aluOp = `ALU_OP_I_SYS;
            `I_FENCE    : aluOp = `ALU_OP_I_FENCE;
            `S          : aluOp = `ALU_OP_S;
            `B          : aluOp = `ALU_OP_B;
            `U_LUI      : aluOp = `ALU_OP_U_LUI;
            `U_AUIPC    : aluOp = `ALU_OP_U_AUIPC;
            `J          : aluOp = `ALU_OP_J;
        endcase
    end
endmodule

// ====================================================================================================================
// Main fetch-decode stage wrapper module
module FetchDecode
(
    input   [31:0]  instr,
    output  [31:0]  imm,
    output  [3:0]   aluOp,
    output          exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp
);
    ImmGen      IMMGEN_unit(.instr(instr), .imm(imm));
    Controller  CTRL_unit(
        .opcode(`OPCODE(instr)),
        .exec_a(exec_a),
        .exec_b(exec_b),
        .mem_w(mem_w),
        .reg_w(reg_w),
        .mem2reg(mem2reg),
        .bra(bra),
        .jmp(jmp),
        .aluOp(aluOp)
    );

endmodule