`include "types.vh"

module Execute (
    input   [6:0]   i_funct7,
    input   [2:0]   i_funct3,
    input   [3:0]   i_aluOp,
    input   [1:0]   i_fwdRs1, i_fwdRs2,
    input           i_aluSrcA, i_aluSrcB,
    input   [31:0]  i_EXEC_rs1, i_EXEC_rs2, i_MEM_rd, i_WB_rd, i_rdDataSave,
    input   [31:0]  i_PC, i_IMM,
    output  [31:0]  o_aluOut, o_addrGenOut, o_rs2FwdOut
);
    parameter XLEN = 32;

    // Datapath for register forwarding
    reg [31:0] rs1Out, rs2Out;
    always@(*) begin
        case (i_fwdRs1)
            `NO_FWD         : rs1Out = i_EXEC_rs1;
            `FWD_MEM        : rs1Out = i_MEM_rd;
            `FWD_WB         : rs1Out = i_WB_rd;
            `FWD_REG_RDW    : rs1Out = i_rdDataSave;
            default         : rs1Out = i_EXEC_rs1;
        endcase
        case (i_fwdRs2)
            `NO_FWD         : rs2Out = i_EXEC_rs2;
            `FWD_MEM        : rs2Out = i_MEM_rd;
            `FWD_WB         : rs2Out = i_WB_rd;
            `FWD_REG_RDW    : rs2Out = i_rdDataSave;
            default         : rs2Out = i_EXEC_rs2;
        endcase
    end

    // Datapath for ALU srcs
    wire [31:0] aluSrcAin = (i_aluSrcA == `PC ) ? i_PC  : rs1Out;
    wire [31:0] aluSrcBin = (i_aluSrcB == `IMM) ? i_IMM : rs2Out;

    // ALU/ALU_Control
    wire [4:0]  aluControl;
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

    assign o_addrGenOut = i_PC + i_IMM;
    assign o_rs2FwdOut  = rs2Out;

endmodule
