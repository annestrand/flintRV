`include "types.vh"

module FetchDecode (
    input   [31:0]      i_instr     /*verilator public*/,
    output  [XLEN-1:0]  o_imm       /*verilator public*/,
    output  [3:0]       o_aluOp     /*verilator public*/,
    output              o_exec_a    /*verilator public*/,
                        o_exec_b    /*verilator public*/,
                        o_mem_w     /*verilator public*/,
                        o_reg_w     /*verilator public*/,
                        o_mem2reg   /*verilator public*/,
                        o_bra       /*verilator public*/,
                        o_jmp       /*verilator public*/
);
    parameter XLEN /*verilator public*/ = 32;

    ImmGen #(.XLEN(XLEN)) IMMGEN_unit(
        .i_instr    (i_instr),
        .o_imm      (o_imm)
    );
    ControlUnit CTRL_unit(
        .i_opcode   (`OPCODE(i_instr)),
        .o_aluOp    (o_aluOp),
        .o_exec_a   (o_exec_a),
        .o_exec_b   (o_exec_b),
        .o_mem_w    (o_mem_w),
        .o_reg_w    (o_reg_w),
        .o_mem2reg  (o_mem2reg),
        .o_bra      (o_bra),
        .o_jmp      (o_jmp)
    );
endmodule
