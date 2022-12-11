`include "types.vh"

module ControlUnit (
    input       [XLEN-1:0]  i_instr     /*verilator public*/,
    output  reg [XLEN-1:0]  o_ctrlSigs  /*verilator public*/
);
    parameter XLEN      = 32;
    localparam NOP      = 32'd0;
    localparam I_SYS    = 3;

    reg [10:0] ctrlType /*verilator public*/;

    always @* begin
        // Core control signal defaults
        case (`OPCODE(i_instr))
            `I_JUMP     : begin ctrlType = 11'b00000000001; o_ctrlSigs = `I_JUMP_CTRL;    end
            `I_LOAD     : begin ctrlType = 11'b00000000010; o_ctrlSigs = `I_LOAD_CTRL;    end
            `I_ARITH    : begin ctrlType = 11'b00000000100; o_ctrlSigs = `I_ARITH_CTRL;   end
            `I_SYS      : begin ctrlType = 11'b00000001000; o_ctrlSigs = `I_SYS_CTRL;     end
            `I_FENCE    : begin ctrlType = 11'b00000010000; o_ctrlSigs = `I_FENCE_CTRL;   end
            `U_LUI      : begin ctrlType = 11'b00000100000; o_ctrlSigs = `U_LUI_CTRL;     end
            `U_AUIPC    : begin ctrlType = 11'b00001000000; o_ctrlSigs = `U_AUIPC_CTRL;   end
            `S          : begin ctrlType = 11'b00010000000; o_ctrlSigs = `S_CTRL;         end
            `B          : begin ctrlType = 11'b00100000000; o_ctrlSigs = `B_CTRL;         end
            `J          : begin ctrlType = 11'b01000000000; o_ctrlSigs = `J_CTRL;         end
            `R          : begin ctrlType = 11'b10000000000; o_ctrlSigs = `R_CTRL;         end
            default     : begin ctrlType = 11'b00000000000; o_ctrlSigs = NOP;             end
        endcase
        // Other control signal settings/overrides
        `CTRL_ECALL(o_ctrlSigs)     = ctrlType[I_SYS] && (`IMM_11_0(i_instr) == 12'b000000000000);
        `CTRL_EBREAK(o_ctrlSigs)    = ctrlType[I_SYS] && (`IMM_11_0(i_instr) == 12'b000000000001);
    end
endmodule
