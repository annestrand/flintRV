`include "ALU_Control.v"

module AluControl_tb;
    reg     [3:0] i_aluOp;
    reg     [6:0] i_funct7;
    reg     [2:0] i_funct3;
    wire    [4:0] o_aluControl;

    ALU_Control IAluControl_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("out/ALU_Control.vcd");
        $dumpvars(0, AluControl_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:39];
    reg [4:0]   test_gold_vector    [0:39];
    initial begin
        $readmemh("out/unit_ALU_Control.mem", test_vector);
        $readmemb("out/unit_ALU_Control_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [31:0] instr;
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        $display("Running ALU control tests...\n");
        i_aluOp   = 'd0;
        i_funct3  = 'd0;
        i_funct7  = 'd0;
        #20;
        for (i=0; i<40; i=i+1) begin
            instr = `ENDIAN_SWP_32(test_vector[i]);
            if      (`OPCODE(instr) == `R      ) i_aluOp = `ALU_OP_R;
            else if (`OPCODE(instr) == `I_JUMP ) i_aluOp = `ALU_OP_I_JUMP;
            else if (`OPCODE(instr) == `I_LOAD ) i_aluOp = `ALU_OP_I_LOAD;
            else if (`OPCODE(instr) == `I_ARITH) i_aluOp = `ALU_OP_I_ARITH;
            else if (`OPCODE(instr) == `I_SYS  ) i_aluOp = `ALU_OP_I_SYS;
            else if (`OPCODE(instr) == `I_FENCE) i_aluOp = `ALU_OP_I_FENCE;
            else if (`OPCODE(instr) == `S      ) i_aluOp = `ALU_OP_S;
            else if (`OPCODE(instr) == `B      ) i_aluOp = `ALU_OP_B;
            else if (`OPCODE(instr) == `U_LUI  ) i_aluOp = `ALU_OP_U_LUI;
            else if (`OPCODE(instr) == `U_AUIPC) i_aluOp = `ALU_OP_U_AUIPC;
            else if (`OPCODE(instr) == `J      ) i_aluOp = `ALU_OP_J;
            i_funct3 = `FUNCT3(instr);
            i_funct7 = `FUNCT7(instr);
            #20;
            if (o_aluControl != test_gold_vector[i]) resultStr = "ERROR";
            else                                     resultStr = "PASS ";
            $display("Test[ %2d ]: i_aluOp = %b | i_funct3 = %b | i_funct7 = %b || o_aluControl = %b ... %s",
                i, i_aluOp, i_funct3, i_funct7, o_aluControl, resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule