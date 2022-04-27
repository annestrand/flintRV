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
            default          :   imm = 32'd0;
        // Immediate cases
            `I_JUMP, `I_LOAD :   imm = {{21{instr[31]}}, instr[30:20]};
            `I_ARITH         :   imm = isShiftImm ? {{27{instr[31]}}, instr[24:20]} : {{21{instr[31]}}, instr[30:20]};
            `S               :   imm = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
            `B               :   imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'd0};
            `U_LUI, `U_AUIPC :   imm = {instr[31], instr[30:20], instr[19:12], 12'd0};
            `J               :   imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'd0};
        endcase
    end
endmodule

// ====================================================================================================================
`define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
    `define NAME ISA_ENC
`include "instr.vh"
`undef INSTR
module Controller
(
    input       [31:0]  instr,
    output  reg [15:0]  ctrlSignals
);
    parameter           INSTR_COUNT         = 40; // Default RV32I count
    localparam          INSTR_ADDR_WIDTH    = $clog2(INSTR_COUNT);
    localparam  [1:0]   OP                  = 2'd0,
                        F3_OP               = 2'd1,
                        F7_F3_OP            = 2'd2;

    // instr encoder
    reg     [1:0]                   instrOpEnc;
    reg     [16:0]                  instrOpEncAddr;
    reg     [INSTR_ADDR_WIDTH-1:0]  instrAddr;
    wire    [16:0]                  F7_F3_OP_wire   = {`FUNCT7(instr), `FUNCT3(instr), `OPCODE(instr)};
    wire    [16:0]                  F3_OP_wire      = {7'd0          , `FUNCT3(instr), `OPCODE(instr)};
    wire    [16:0]                  OP_wire         = {7'd0          , 3'd0          , `OPCODE(instr)};
    wire    [2:0]                   funct3          = `FUNCT3(instr);
    wire                            isShiftImm      = ~funct3[1] && funct3[0];
    always @* begin
        case (`OPCODE(instr))   // 1. Get instruction type
            default                                      : instrOpEnc = F7_F3_OP;
            `R                                           : instrOpEnc = F7_F3_OP;
            `I_JUMP, `I_LOAD, `I_FENCE, `I_SYS           : instrOpEnc = F3_OP;
            `I_ARITH                                     : instrOpEnc = isShiftImm ? F7_F3_OP : F3_OP;
            `S                                           : instrOpEnc = F3_OP;
            `B                                           : instrOpEnc = F3_OP;
            `U_LUI, `U_AUIPC                             : instrOpEnc = OP;
            `J                                           : instrOpEnc = OP;
        endcase
        case (instrOpEnc)       // 2. Select instr addr. line by instruction type
            default     : instrOpEncAddr = F7_F3_OP_wire;
            F7_F3_OP    : instrOpEncAddr = F7_F3_OP_wire;
            F3_OP       : instrOpEncAddr = F3_OP_wire;
            OP          : instrOpEncAddr = OP_wire;
        endcase
        case (instrOpEncAddr)   // 3. Create instr encoder
            default : instrAddr = 'd0;
            `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
                `NAME : instrAddr = ENC;
            `include "instr.vh"
            `undef INSTR
        endcase
    end
    // instr output assignment
    always @* begin
        case (instrAddr)
            default : ctrlSignals = 'd0;
            `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
                ENC : ctrlSignals = {EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP};
            `include "instr.vh"
            `undef INSTR
        endcase
    end
endmodule

// ====================================================================================================================
// Main fetch-decode stage wrapper module
module FetchDecode
(
    input   [31:0] instr,
    output  [31:0] imm,
    output  [15:0] ctrlSignals
);

ImmGen      IMMGEN_unit(.instr(instr), .imm(imm));
Controller  CTRL_unit(.instr(instr), .ctrlSignals(ctrlSignals));

endmodule