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
                                        o_imm           /*verilator public*/,
                                        o_ctrlSigs      /*verilator public*/
);
    parameter XLEN                  /*verilator public*/ = 32;
    parameter REGFILE_ADDR_WIDTH    /*verilator public*/ = 5;

    ImmGen #(.XLEN(XLEN)) IMMGEN_unit (
        .i_instr    (i_instr),
        .o_imm      (o_imm)
    );
    ControlUnit #(.XLEN(XLEN)) CTRL_unit (
        .i_instr    (i_instr),
        .o_ctrlSigs (o_ctrlSigs)
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
