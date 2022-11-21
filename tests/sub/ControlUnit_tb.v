`include "types.vh"

module ControlUnit_tb;
    reg     [6:0]   i_opcode;
    wire    [3:0]   o_aluOp;
    wire            o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp;

    ControlUnit ControlUnit_dut(.*);

    // Test vectors
    parameter TEST_COUNT = 2**7;
    reg  [6:0] test_vector      [0:TEST_COUNT-1];
    reg [10:0] test_gold_vector [0:TEST_COUNT-1];
    initial begin
        for (i=0; i<TEST_COUNT; i=i+1) begin
            test_vector[i] = i;
            case (i)
                `R       : test_gold_vector[i] = `R_CTRL;
                `I_JUMP  : test_gold_vector[i] = `I_JUMP_CTRL;
                `I_LOAD  : test_gold_vector[i] = `I_LOAD_CTRL;
                `I_ARITH : test_gold_vector[i] = `I_ARITH_CTRL;
                `I_SYS   : test_gold_vector[i] = `I_SYS_CTRL;
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
    reg     [39:0]  resultStr;
    reg     [12:0]  ctrlSignals;
    integer i = 0, errs = 0;
    initial begin
        i_opcode   = 'd0; #20;
        for (i=0; i<TEST_COUNT; i=i+1) begin
            i_opcode    = test_vector[i]; #20;
            ctrlSignals = {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp};
            if (ctrlSignals != test_gold_vector[i]) resultStr = "ERROR";
            else                                    resultStr = "PASS ";
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("ControlUnit tests - FAILED: %0d", errs);
        else            $display("ControlUnit tests - PASSED");
    end

endmodule