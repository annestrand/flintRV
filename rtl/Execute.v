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
                        o_addrGenOut    /*verilator public*/,
    output              o_braOutcome    /*verilator public*/
);
    parameter XLEN /*verilator public*/ = 32;

    // ALU input selects
    wire [XLEN-1:0] aluSrcA /*verilator public*/;
    wire [XLEN-1:0] aluSrcB /*verilator public*/;
    assign aluSrcA  = (i_aluSelA == `PC)    ? i_PC  : i_rs1Exec;
    assign aluSrcB  = (i_aluSelB == `IMM)   ? i_IMM : i_rs2Exec;

    // ALU output flags
    wire    zflag /*verilator public*/,
            cflag /*verilator public*/,
            lflag /*verilator public*/;

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
        .o_result (o_aluOut),
        .o_zflag  (zflag),
        .o_cflag  (cflag),
        .o_lflag  (lflag)
    );

    // Generate jump address
    wire indirJump                  /*verilator public*/;
    wire [XLEN-1:0] ctrlTransSrcA   /*verilator public*/;
    wire [XLEN-1:0] jmpResult       /*verilator public*/;
    assign indirJump        = `ALU_OP_I_JUMP == i_aluOp; // (i.e. JALR)
    assign ctrlTransSrcA    = indirJump ? i_rs1Exec : i_PC;
    assign jmpResult        = ctrlTransSrcA + i_IMM;
    assign o_addrGenOut     = indirJump ? {jmpResult[XLEN-1:1],1'b0} : jmpResult;

    // Comparison expressions for branch instructions
    wire beq     /*verilator public*/,
         bne     /*verilator public*/,
         blt     /*verilator public*/,
         bge     /*verilator public*/,
         bltu    /*verilator public*/,
         bgeu    /*verilator public*/;
    assign beq  = aluControl == `ALU_EXEC_EQ    &&  zflag;
    assign bne  = aluControl == `ALU_EXEC_NEQ   && ~zflag;
    assign blt  = aluControl == `ALU_EXEC_SLT   &&  lflag;
    assign bge  = aluControl == `ALU_EXEC_SGTE  && ~lflag;
    assign bltu = aluControl == `ALU_EXEC_SLTU  && ~cflag;
    assign bgeu = aluControl == `ALU_EXEC_SGTEU &&  cflag;
    // Static branch prediction - assume not taken
    assign o_braOutcome = i_aluOp == `ALU_OP_B && (beq | bne | blt | bge | bltu | bgeu);

endmodule
