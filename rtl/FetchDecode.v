`include "types.vh"

module FetchDecode (
    input                               i_clk           /*verilator public*/,
                                        i_regWrEn       /*verilator public*/,
    input   [REGFILE_ADDR_WIDTH-1:0]    i_regRs1Addr    /*verilator public*/,
                                        i_regRs2Addr    /*verilator public*/,
                                        i_regRdAddr     /*verilator public*/,
    input   [XLEN-1:0]                  i_regRdData     /*verilator public*/,
                                        i_instr         /*verilator public*/,
    output  [XLEN-1:0]                  o_regRs1Data    /*verilator public*/,
                                        o_regRs2Data    /*verilator public*/,
    output  [XLEN-1:0]                  o_imm           /*verilator public*/,
    output  [3:0]                       o_aluOp         /*verilator public*/,
    output                              o_exec_a        /*verilator public*/,
                                        o_exec_b        /*verilator public*/,
                                        o_mem_w         /*verilator public*/,
                                        o_reg_w         /*verilator public*/,
                                        o_mem2reg       /*verilator public*/,
                                        o_bra           /*verilator public*/,
                                        o_jmp           /*verilator public*/
);
    parameter XLEN                  /*verilator public*/ = 32;
    parameter REGFILE_ADDR_WIDTH    /*verilator public*/ = 5;

    ImmGen #(.XLEN(XLEN)) IMMGEN_unit (
        .i_instr    (i_instr),
        .o_imm      (o_imm)
    );
    ControlUnit CTRL_unit (
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
    Regfile #(
        .XLEN       (XLEN),
        .ADDR_WIDTH (REGFILE_ADDR_WIDTH)
    ) REGFILE_unit (
        .i_clk      (i_clk),
        .i_wrEn     (i_regWrEn),
        .i_rs1Addr  (i_regRs1Addr),
        .i_rs2Addr  (i_regRs2Addr),
        .i_rdAddr   (i_regRdAddr),
        .i_rdData   (i_regRdData),
        .o_rs1Data  (o_regRs1Data),
        .o_rs2Data  (o_regRs2Data)
    );

endmodule
