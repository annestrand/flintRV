// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module Execute (
    input   [6:0]       i_funct7        /*verilator public*/,
    input   [2:0]       i_funct3        /*verilator public*/,
    input   [3:0]       i_aluOp         /*verilator public*/,
    input               i_aluSelA       /*verilator public*/,
                        i_aluSelB       /*verilator public*/,
    input   [XLEN-1:0]  i_rs1Exec       /*verilator public*/,
                        i_rs2Exec       /*verilator public*/,
                        i_PC            /*verilator public*/,
                        i_IMM           /*verilator public*/,
    output  [XLEN-1:0]  o_aluOut        /*verilator public*/,
                        o_addrGenOut    /*verilator public*/
);
    parameter XLEN /*verilator public*/ = 32;

    // ALU input selects
    wire [XLEN-1:0] aluSrcA /*verilator public*/;
    wire [XLEN-1:0] aluSrcB /*verilator public*/;
    assign aluSrcA  = (i_aluSelA == `PC)    ? i_PC  : i_rs1Exec;
    assign aluSrcB  = (i_aluSelB == `IMM)   ? i_IMM : i_rs2Exec;

    // ALU/ALU_Control
    wire [4:0]  aluControl /*verilator public*/;
    ALU_Control ALU_CTRL_unit (
        .i_aluOp        (i_aluOp),
        .i_funct7       (i_funct7),
        .i_funct3       (i_funct3),
        .o_aluControl   (aluControl)
    );
    ALU #(.XLEN(XLEN)) alu_unit (
        .i_a      (aluSrcA),
        .i_b      (aluSrcB),
        .i_op     (aluControl),
        .o_result (o_aluOut)
    );

    // Generate jump address
    wire indirJump                  /*verilator public*/;
    wire [XLEN-1:0] ctrlTransSrcA   /*verilator public*/;
    wire [XLEN-1:0] jmpResult       /*verilator public*/;
    assign indirJump        = `ALU_OP_I_JUMP == i_aluOp; // (i.e. JALR)
    assign ctrlTransSrcA    = indirJump ? i_rs1Exec : i_PC;
    assign jmpResult        = ctrlTransSrcA + i_IMM;
    assign o_addrGenOut     = indirJump ? {jmpResult[XLEN-1:1],1'b0} : jmpResult;

endmodule
