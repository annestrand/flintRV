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
module Controller // WIP
(
    input       [31:0] instr,
    output  reg [13:0] ctrlSignals
);
    parameter   UCODE_COUNT         = 37;
    localparam  UCODE_ADDR_WIDTH    = $clog2(UCODE_COUNT);

    // Controller encoder and uCode ROM
    wire    [UCODE_ADDR_WIDTH-1:0] uCodeAddr;
    reg     [13:0] uCtrlCode [0:INSTR_COUNT-1];
    // Output signals
    assign ctrlSignals = uCtrlCode[uCodeAddr];
endmodule