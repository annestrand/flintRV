`include "fetch_decode.v"
`include "types.vh"

module Controller_tb;
    reg     [6:0]   opcode;
    wire    [3:0]   aluOp;
    wire            exec_a, exec_b, ld_sd, mem_w, reg_w, mem2reg, bra, jmp;

    Controller Controller_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/controller_tb.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:39];
    reg [12:0]  test_gold_vector    [0:39];
    initial begin
        $readmemh("build/controller.mem", test_vector);
    end
    reg [31:0]  instr;
    initial begin
        for (i=0; i<40; i=i+1) begin
            instr = `ENDIAN_SWP_32(test_vector[i]);
            if      (`OPCODE(instr) == `R      ) test_gold_vector[i] = {`ALU_OP_R, `R_CTRL};
            else if (`OPCODE(instr) == `I_JUMP ) test_gold_vector[i] = {`ALU_OP_I_JUMP, `I_JUMP_CTRL};
            else if (`OPCODE(instr) == `I_LOAD ) test_gold_vector[i] = {`ALU_OP_I_LOAD, `I_LOAD_CTRL};
            else if (`OPCODE(instr) == `I_ARITH) test_gold_vector[i] = {`ALU_OP_I_ARITH, `I_ARITH_CTRL};
            else if (`OPCODE(instr) == `I_SYS  ) test_gold_vector[i] = {`ALU_OP_I_SYS, `I_SYS_CTRL};
            else if (`OPCODE(instr) == `I_FENCE) test_gold_vector[i] = {`ALU_OP_I_FENCE, `I_FENCE_CTRL};
            else if (`OPCODE(instr) == `S      ) test_gold_vector[i] = {`ALU_OP_S, `S_CTRL};
            else if (`OPCODE(instr) == `B      ) test_gold_vector[i] = {`ALU_OP_B, `B_CTRL};
            else if (`OPCODE(instr) == `U_LUI  ) test_gold_vector[i] = {`ALU_OP_U_LUI, `U_LUI_CTRL};
            else if (`OPCODE(instr) == `U_AUIPC) test_gold_vector[i] = {`ALU_OP_U_AUIPC, `U_AUIPC_CTRL};
            else if (`OPCODE(instr) == `J      ) test_gold_vector[i] = {`ALU_OP_J, `J_CTRL};
        end
    end

    // Test loop
    reg     [39:0]  resultStr;
    reg     [12:0]  ctrlSignals;
    integer i = 0, errs = 0;
    initial begin
        $display("Running Controller tests...\n");
        opcode   = 'd0;
        #20;
        for (i=0; i<40; i=i+1) begin
            // Note: RISC-V Verilog Objcopy seems to output big-endian for some reason, swap to little here
            instr  = `ENDIAN_SWP_32(test_vector[i]);
            opcode = `OPCODE(instr);
            #20;
            ctrlSignals = {aluOp, exec_a, exec_b, ld_sd, mem_w, reg_w, mem2reg, bra, jmp};
            if (ctrlSignals != test_gold_vector[i]) resultStr = "ERROR";
            else                                    resultStr = "PASS ";
            $display("Test[ %2d ]: instr = 0x%8h || ctrlSigs = %b ... %s",
                i, instr, ctrlSignals, resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule