`include "types.vh"

module Execute (
    input   [6:0]   funct7,
    input   [2:0]   funct3,
    input   [3:0]   aluOp,
    input   [1:0]   fwdRs1, fwdRs2,
    input           aluSrcA, aluSrcB,
    input   [31:0]  EXEC_rs1, EXEC_rs2, MEM_rd, WB_rd,
    input   [31:0]  PC, IMM,
    output  [31:0]  aluOut, addrGenOut
);
    // Datapath for register forwarding
    reg [31:0] rs1Out, rs2Out;
    always@(*) begin
        case (fwdRs1)
            `NO_FWD     : rs1Out = EXEC_rs1;
            `FWD_MEM    : rs1Out = MEM_rd;
            `FWD_WB     : rs1Out = WB_rd;
            default     : rs1Out = EXEC_rs1;
        endcase
        case (fwdRs2)
            `NO_FWD     : rs2Out = EXEC_rs2;
            `FWD_MEM    : rs2Out = MEM_rd;
            `FWD_WB     : rs2Out = WB_rd;
            default     : rs2Out = EXEC_rs2;
        endcase
    end

    // Datapath for ALU srcs
    wire [31:0] aluSrcAin = (aluSrcA == `PC ) ? PC  : rs1Out;
    wire [31:0] aluSrcBin = (aluSrcB == `IMM) ? IMM : rs2Out;

    // ALU/ALU_Control
    wire [4:0]  aluControl;
    IALU_Control ALU_CTRL_unit(
        .aluOp      (aluOp),
        .funct7     (funct7),
        .funct3     (funct3),
        .aluControl (aluControl)
    );
    IALU ialu_unit(
        .a      (aluSrcAin),
        .b      (aluSrcBin),
        .op     (aluControl),
        .result (aluOut),
        .zflag  (/* No use for now... */)
    );
    defparam ialu_unit.WIDTH = 32;

    // Address generator
    CLA addr_gen_unit(
        .a      (PC),
        .b      (IMM),
        .subEn  (1'b0),
        .result (addrGenOut),
        .cout   (/* No use for now... */)
    );
endmodule
