// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ControlUnit_tb;
    reg     [31:0]  i_instr;
    wire    [31:0]  o_ctrlSigs;

    ControlUnit ControlUnit_dut(.*);

    // Test vectors
    parameter TEST_COUNT = 2**7;
    reg [31:0] tmp;
    reg [31:0] test_vector      [0:TEST_COUNT-1];
    reg [31:0] test_gold_vector [0:TEST_COUNT-1];
    initial begin
        for (i=0; i<TEST_COUNT; i=i+1) begin
            test_vector[i] = i;
            case (i)
                `R       : test_gold_vector[i] = `R_CTRL;
                `I_JUMP  : test_gold_vector[i] = `I_JUMP_CTRL;
                `I_LOAD  : test_gold_vector[i] = `I_LOAD_CTRL;
                `I_ARITH : test_gold_vector[i] = `I_ARITH_CTRL;
                `I_SYS   : begin
                    tmp                 = `I_SYS_CTRL;
                    `CTRL_EBREAK(tmp)   = `IMM_11_0(i) == 12'b000000000001;
                    `CTRL_ECALL(tmp)    = `TRUE;
                    test_gold_vector[i] = tmp;
                end
                `I_FENCE : test_gold_vector[i] = `I_FENCE_CTRL;
                `S       : test_gold_vector[i] = `S_CTRL;
                `B       : test_gold_vector[i] = `B_CTRL;
                `U_LUI   : test_gold_vector[i] = `U_LUI_CTRL;
                `U_AUIPC : test_gold_vector[i] = `U_AUIPC_CTRL;
                `J       : test_gold_vector[i] = `J_CTRL;
                default  : test_gold_vector[i] = 'd0;
            endcase
        end
    end

    // Test loop
    reg     [31:0] ctrlSignals;
    integer i = 0, errs = 0;
    initial begin
        i_instr   = 'd0; #20;
        for (i=0; i<TEST_COUNT; i=i+1) begin
            i_instr = test_vector[i]; #20;
            if (o_ctrlSigs != test_gold_vector[i]) begin
                errs = errs + 1;
            end
        end
        // Also test EBREAK case
        tmp                 = `I_SYS_CTRL;
        `CTRL_EBREAK(tmp)   = `TRUE;
        i_instr = {12'b000000000001, 13'd0, `I_SYS}; #20;
        if (o_ctrlSigs != tmp) begin
            errs = errs + 1;
        end
        if (errs > 0)   $display("ControlUnit tests - FAILED: %0d", errs);
        else            $display("ControlUnit tests - PASSED");
    end

endmodule