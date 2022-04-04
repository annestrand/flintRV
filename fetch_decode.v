`include "types.v"

module ImmGen
(
    input       [31:0]  instr,
    output reg  [31:0]  imm
);
    wire [2:0] funct3   = `FUNCT3(instr);
    wire isShiftImm     = ~funct3[1] && funct3[0];
    always @* begin
        case (`OPCODE(instr))
            default          :   imm = 32'd5;
        // Immediate cases
            `I_JUMP, `I_LOAD :   imm = {{22{instr[31]}}, instr[30:20]};
            `I_ARITH         :   imm = isShiftImm ? {{27{instr[31]}}, instr[24:20]} : {{22{instr[31]}}, instr[30:20]};
            `S               :   imm = {{22{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
            `B               :   imm = {{21{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'd0};
            `U_LUI, `U_AUIPC :   imm = {instr[31], instr[30:20], instr[19:12], 12'd0};
            `J               :   imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'd0};
        endcase
    end

endmodule

// ====================================================================================================================
module Controller // WIP - Macro handling define/undef still wonky here... need to fix
(
    input       [31:0] instr,
    output  reg [15:0] ctrlSignals
);
    parameter   UCODE_COUNT         = 40; // Default RV32I count
    localparam  UCODE_ADDR_WIDTH    = $clog2(UCODE_COUNT);

    // Controller encoder and uCode ROM
    reg     [UCODE_ADDR_WIDTH-1:0] uCodeAddr;
    reg     [15:0] uCtrlCode [0:UCODE_COUNT-1];

    // uCode encoder
    `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
        `NAME : uCodeAddr = ENC;
    always @* begin
        case ({`FUNCT7(instr), `FUNCT3(instr), `OPCODE(instr)})
        `INSTRUCTIONS
        default : uCodeAddr = 'd0;
        endcase
    end
    `undef INSTR

    // uCode ROM contents
    `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
        ENC : ctrlSignals = {EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP};
    always @* begin
        case (uCodeAddr)
        `INSTRUCTIONS
        default : ctrlSignals = 'd0;
        endcase
    end
    `undef INSTR

endmodule