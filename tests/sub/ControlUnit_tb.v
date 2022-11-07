module ControlUnit_tb;
    reg     [6:0]   i_opcode;
    wire    [3:0]   o_aluOp;
    wire            o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp;

    ControlUnit ControlUnit_dut(.*);

    // Test vectors
    reg [31:0]  test_vector         [0:39];
    reg [12:0]  test_gold_vector    [0:39];
    initial begin
        $readmemh("build/tests/sub/sub_ControlUnit.mem", test_vector);
    end
    reg [31:0]  instr;
    initial begin
        for (i=0; i<40; i=i+1) begin
            instr = test_vector[i];
            if      (`OPCODE(instr) == `R      ) test_gold_vector[i] = {`R_CTRL         };
            else if (`OPCODE(instr) == `I_JUMP ) test_gold_vector[i] = {`I_JUMP_CTRL    };
            else if (`OPCODE(instr) == `I_LOAD ) test_gold_vector[i] = {`I_LOAD_CTRL    };
            else if (`OPCODE(instr) == `I_ARITH) test_gold_vector[i] = {`I_ARITH_CTRL   };
            else if (`OPCODE(instr) == `I_SYS  ) test_gold_vector[i] = {`I_SYS_CTRL     };
            else if (`OPCODE(instr) == `I_FENCE) test_gold_vector[i] = {`I_FENCE_CTRL   };
            else if (`OPCODE(instr) == `S      ) test_gold_vector[i] = {`S_CTRL         };
            else if (`OPCODE(instr) == `B      ) test_gold_vector[i] = {`B_CTRL         };
            else if (`OPCODE(instr) == `U_LUI  ) test_gold_vector[i] = {`U_LUI_CTRL     };
            else if (`OPCODE(instr) == `U_AUIPC) test_gold_vector[i] = {`U_AUIPC_CTRL   };
            else if (`OPCODE(instr) == `J      ) test_gold_vector[i] = {`J_CTRL         };
        end
    end

    // Test loop
    reg     [39:0]  resultStr;
    reg     [12:0]  ctrlSignals;
    integer i = 0, errs = 0;
    initial begin
        i_opcode   = 'd0;
        #20;
        for (i=0; i<40; i=i+1) begin
            instr       = test_vector[i];
            i_opcode    = `OPCODE(instr);
            #20;
            ctrlSignals = {o_aluOp, o_exec_a, o_exec_b, o_mem_w, o_reg_w, o_mem2reg, o_bra, o_jmp};
            if (ctrlSignals != test_gold_vector[i]) resultStr = "ERROR";
            else                                    resultStr = "PASS ";
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("ControlUnit tests - FAILED: %0d", errs);
        else            $display("ControlUnit tests - PASSED");
    end

endmodule