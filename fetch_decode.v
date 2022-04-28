`include "types.vh"

module ImmGen
(
    input       [31:0]  i_instr,
    output reg  [31:0]  o_imm
);
    wire [2:0] funct3   = `FUNCT3(i_instr);
    wire isShiftImm     = ~funct3[1] && funct3[0];
    always @* begin
        case (`OPCODE(i_instr))
            default  :  o_imm = 32'd0;
        // Immediate cases
            `I_JUMP  ,
            `I_LOAD  : o_imm = {{21{i_instr[31]}}, i_instr[30:20]};
            `I_ARITH : o_imm = isShiftImm ? {{27{i_instr[31]}}, i_instr[24:20]} : {{21{i_instr[31]}}, i_instr[30:20]};
            `S       : o_imm = {{21{i_instr[31]}}, i_instr[30:25], i_instr[11:8], i_instr[7]};
            `B       : o_imm = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'd0};
            `U_LUI   ,
            `U_AUIPC : o_imm = {i_instr[31], i_instr[30:20], i_instr[19:12], 12'd0};
            `J       : o_imm = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'd0};
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
    input       [31:0]  i_instr,
    output  reg [15:0]  o_ctrlSignals
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
    wire    [16:0]                  F7_F3_OP_wire   = {`FUNCT7(i_instr), `FUNCT3(i_instr), `OPCODE(i_instr)};
    wire    [16:0]                  F3_OP_wire      = {7'd0          , `FUNCT3(i_instr), `OPCODE(i_instr)};
    wire    [16:0]                  OP_wire         = {7'd0          , 3'd0          , `OPCODE(i_instr)};
    wire    [2:0]                   funct3          = `FUNCT3(i_instr);
    wire                            isShiftImm      = ~funct3[1] && funct3[0];
    always @* begin
        case (`OPCODE(i_instr))   // 1. Get instruction type
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
            default : o_ctrlSignals = 'd0;
            `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
                ENC : o_ctrlSignals = {EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP};
            `include "instr.vh"
            `undef INSTR
        endcase
    end
endmodule

// ====================================================================================================================
// Main fetch-decode stage wrapper module
module FetchDecode
(
    input   [31:0] i_instr,
    output  [31:0] o_imm,
    output  [15:0] o_ctrlSignals
);

    ImmGen IMMGEN_unit(
        .i_instr(i_instr),
        .o_imm(o_imm)
    );
    Controller CTRL_unit(
        .i_instr(i_instr),
        .o_ctrlSignals(o_ctrlSignals)
    );

endmodule