`include "types.vh"

module FetchDecode (
    input   [31:0]  instr,
    output  [31:0]  imm,
    output  [3:0]   aluOp,
    output          exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp
);
    ImmGen IMMGEN_unit(
        .instr (instr),
        .imm   (imm)
    );
    Controller CTRL_unit(
        .opcode  (`OPCODE(instr)),
        .exec_a  (exec_a),
        .exec_b  (exec_b),
        .mem_w   (mem_w),
        .reg_w   (reg_w),
        .mem2reg (mem2reg),
        .bra     (bra),
        .jmp     (jmp),
        .aluOp   (aluOp)
    );
endmodule
