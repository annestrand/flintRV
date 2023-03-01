// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ControlUnit (
    /* verilator lint_off UNUSED */
    input       [XLEN-1:0]  i_instr, // TODO: %Warning-UNUSED: Bits of signal are not used: 'i_instr'[19:7]
    /* verilator lint_on UNUSED  */
    output  reg [XLEN-1:0]  o_ctrlSigs
);
    parameter XLEN      = 32;
    localparam NOP      = 32'd0;
    localparam I_SYS    = 3;

    localparam R_CTRL       /*verilator public*/= `R_CTRL;
    localparam I_JUMP_CTRL  /*verilator public*/= `I_JUMP_CTRL;
    localparam I_LOAD_CTRL  /*verilator public*/= `I_LOAD_CTRL;
    localparam I_ARITH_CTRL /*verilator public*/= `I_ARITH_CTRL;
    localparam I_SYS_CTRL   /*verilator public*/= `I_SYS_CTRL;
    localparam I_FENCE_CTRL /*verilator public*/= `I_FENCE_CTRL;
    localparam S_CTRL       /*verilator public*/= `S_CTRL;
    localparam B_CTRL       /*verilator public*/= `B_CTRL;
    localparam U_LUI_CTRL   /*verilator public*/= `U_LUI_CTRL;
    localparam U_AUIPC_CTRL /*verilator public*/= `U_AUIPC_CTRL;
    localparam J_CTRL       /*verilator public*/= `J_CTRL;

    reg [10:0] ctrlType;
    always @* begin
        // Core control signal defaults
        case (`OPCODE(i_instr))
            `I_JUMP     : begin ctrlType = 11'b00000000001; o_ctrlSigs = I_JUMP_CTRL;     end
            `I_LOAD     : begin ctrlType = 11'b00000000010; o_ctrlSigs = I_LOAD_CTRL;     end
            `I_ARITH    : begin ctrlType = 11'b00000000100; o_ctrlSigs = I_ARITH_CTRL;    end
            `I_SYS      : begin ctrlType = 11'b00000001000; o_ctrlSigs = I_SYS_CTRL;      end
            `I_FENCE    : begin ctrlType = 11'b00000010000; o_ctrlSigs = I_FENCE_CTRL;    end
            `U_LUI      : begin ctrlType = 11'b00000100000; o_ctrlSigs = U_LUI_CTRL;      end
            `U_AUIPC    : begin ctrlType = 11'b00001000000; o_ctrlSigs = U_AUIPC_CTRL;    end
            `S          : begin ctrlType = 11'b00010000000; o_ctrlSigs = S_CTRL;          end
            `B          : begin ctrlType = 11'b00100000000; o_ctrlSigs = B_CTRL;          end
            `J          : begin ctrlType = 11'b01000000000; o_ctrlSigs = J_CTRL;          end
            `R          : begin ctrlType = 11'b10000000000; o_ctrlSigs = R_CTRL;          end
            default     : begin ctrlType = 11'b00000000000; o_ctrlSigs = NOP;             end
        endcase
        // Other control signal settings/overrides
        `CTRL_ECALL(o_ctrlSigs)     = ctrlType[I_SYS] && (`IMM_11_0(i_instr) == 12'b000000000000);
        `CTRL_EBREAK(o_ctrlSigs)    = ctrlType[I_SYS] && (`IMM_11_0(i_instr) == 12'b000000000001);
    end
endmodule
