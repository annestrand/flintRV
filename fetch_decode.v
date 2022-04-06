`include "types.vh"

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
// uCode defines
`define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
    `define NAME ISA_ENC
`include "ucode.vh"
`undef INSTR
module Controller
(
    input       [31:0] instr,
    output  reg [15:0] ctrlSignals
);
    parameter   UCODE_COUNT         = 40; // Default RV32I count
    localparam  UCODE_ADDR_WIDTH    = $clog2(UCODE_COUNT);

    // uCode encoder
    reg     [UCODE_ADDR_WIDTH-1:0] uCodeAddr;
    always @* begin
        case ({`FUNCT7(instr), `FUNCT3(instr), `OPCODE(instr)})
        `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
            `NAME : uCodeAddr = ENC;
        `include "ucode.vh"
        `undef INSTR
        default : uCodeAddr = 'd0;
        endcase
    end

    // uCode contents
    always @* begin
        case (uCodeAddr)
        `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
            ENC : ctrlSignals = {EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP};
        `include "ucode.vh"
        `undef INSTR
        default : ctrlSignals = 'd0;
        endcase
    end
endmodule