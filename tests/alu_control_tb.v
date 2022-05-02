`include "execute.v"

module AluControl_tb;
    reg     [3:0] aluOp;
    reg     [6:0] funct7;
    reg     [2:0] funct3;
    wire    [4:0] aluControl;

    AluControl AluControl_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/alu_control_tb.vcd");
        $dumpvars(0, AluControl_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:39];
    reg [4:0]   test_gold_vector    [0:39];
    initial begin
        $readmemh("build/alu_control.mem", test_vector);
        $readmemb("build/alu_control_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [31:0] instr;
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        $display("Running ALU control tests...\n");
        aluOp   = 'd0;
        funct3  = 'd0;
        funct7  = 'd0;
        #20;
        for (i=0; i<40; i=i+1) begin
            instr = `ENDIAN_SWP_32(test_vector[i]);
            if      (`OPCODE(instr) == `R      ) aluOp = `ALU_OP_R;
            else if (`OPCODE(instr) == `I_JUMP ) aluOp = `ALU_OP_I_JUMP;
            else if (`OPCODE(instr) == `I_LOAD ) aluOp = `ALU_OP_I_LOAD;
            else if (`OPCODE(instr) == `I_ARITH) aluOp = `ALU_OP_I_ARITH;
            else if (`OPCODE(instr) == `I_SYS  ) aluOp = `ALU_OP_I_SYS;
            else if (`OPCODE(instr) == `I_FENCE) aluOp = `ALU_OP_I_FENCE;
            else if (`OPCODE(instr) == `S      ) aluOp = `ALU_OP_S;
            else if (`OPCODE(instr) == `B      ) aluOp = `ALU_OP_B;
            else if (`OPCODE(instr) == `U_LUI  ) aluOp = `ALU_OP_U_LUI;
            else if (`OPCODE(instr) == `U_AUIPC) aluOp = `ALU_OP_U_AUIPC;
            else if (`OPCODE(instr) == `J      ) aluOp = `ALU_OP_J;
            funct3 = `FUNCT3(instr);
            funct7 = `FUNCT7(instr);
            #20;
            if (aluControl != test_gold_vector[i]) resultStr = "ERROR";
            else                                   resultStr = "PASS ";
            $display("Test[ %2d ]: aluOp = %b | funct3 = %b | funct7 = %b || aluControl = %b ... %s",
                i, aluOp, funct3, funct7, aluControl, resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule