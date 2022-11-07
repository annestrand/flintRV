`include "types.vh"

module Execute (
    input   [6:0]   i_funct7        /*verilator public*/,
    input   [2:0]   i_funct3        /*verilator public*/,
    input   [3:0]   i_aluOp         /*verilator public*/,
    input   [1:0]   i_fwdRs1        /*verilator public*/,
                    i_fwdRs2        /*verilator public*/,
    input           i_aluSrcA       /*verilator public*/,
                    i_aluSrcB       /*verilator public*/,
    input   [31:0]  i_EXEC_rs1      /*verilator public*/,
                    i_EXEC_rs2      /*verilator public*/,
                    i_MEM_rd        /*verilator public*/,
                    i_WB_rd         /*verilator public*/,
    input   [31:0]  i_PC            /*verilator public*/,
                    i_IMM           /*verilator public*/,
    output  [31:0]  o_aluOut        /*verilator public*/,
                    o_addrGenOut    /*verilator public*/,
                    o_rs2FwdOut     /*verilator public*/
);
    parameter XLEN /*verilator public*/ = 32;

    // Datapath for register forwarding
    reg [31:0]  rs1Out /*verilator public*/,
                rs2Out /*verilator public*/;
    always@(*) begin
        case (i_fwdRs1)
            `NO_FWD         : rs1Out = i_EXEC_rs1;
            `FWD_MEM        : rs1Out = i_MEM_rd;
            `FWD_WB         : rs1Out = i_WB_rd;
            default         : rs1Out = i_EXEC_rs1;
        endcase
        case (i_fwdRs2)
            `NO_FWD         : rs2Out = i_EXEC_rs2;
            `FWD_MEM        : rs2Out = i_MEM_rd;
            `FWD_WB         : rs2Out = i_WB_rd;
            default         : rs2Out = i_EXEC_rs2;
        endcase
    end

    // Datapath for ALU srcs
    wire [31:0] aluSrcAin /*verilator public*/;
    wire [31:0] aluSrcBin /*verilator public*/;
    assign aluSrcAin = (i_aluSrcA == `PC ) ? i_PC  : rs1Out;
    assign aluSrcBin = (i_aluSrcB == `IMM) ? i_IMM : rs2Out;

    // ALU/ALU_Control
    wire [4:0]  aluControl /*verilator public*/;
    ALU_Control ALU_CTRL_unit (
        .i_aluOp        (i_aluOp),
        .i_funct7       (i_funct7),
        .i_funct3       (i_funct3),
        .o_aluControl   (aluControl)
    );
    ALU #(.XLEN(XLEN)) alu_unit (
        .i_a      (aluSrcAin),
        .i_b      (aluSrcBin),
        .i_op     (aluControl),
        .o_result (o_aluOut)
    );

    wire indirJump                  /*verilator public*/;
    wire [XLEN-1:0] ctrlTransSrcA   /*verilator public*/;
    wire [XLEN-1:0] jmpResult       /*verilator public*/;
    assign indirJump = `ALU_OP_I_JUMP == i_aluOp; // (i.e. JALR)
    assign ctrlTransSrcA    = indirJump ? rs1Out : i_PC;
    assign jmpResult        = ctrlTransSrcA + i_IMM;

    assign o_addrGenOut = indirJump ? {jmpResult[XLEN-1:1],1'b0} : jmpResult;
    assign o_rs2FwdOut  = rs2Out;

endmodule
