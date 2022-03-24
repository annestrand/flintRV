`include "fetch_decode.v"

module ImmGen_tb;
    reg     [21:0]  signExt;
    reg     [4:0]   opcode;
    reg     [31:0]  instr;
    wire    [31:0]  imm;

    ImmGen ImmGen_dut(signExt, opcode, instr, imm);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("./sim_build/immgen.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    // Test vectors
    reg [4:0]   test_opcodes    [0:2];
    reg [31:0]  test_instrs     [0:2];
    reg [31:0]  gold_imms       [0:2];
    initial begin
        // TODO: Good for now ... replace with $readmemh(...) later
        test_opcodes[0] = 'b00100;      // I-Type
        test_opcodes[1] = 'b00100;      // I-Type
        test_instrs[0]  = 'h0a018613;   // addi a2,gp,160
        test_instrs[1]  = 'h04418513;   // addi a0,gp,68
        gold_imms[0]    = 'd160;
        gold_imms[1]    = 'd68;
    end

    // Test loop
    integer i, errs = 0;
    initial begin
        signExt = 'd0;
        opcode  = 'd0;
        instr   = 'd0;
        #20;
        for (i=0; i<2; i=i+1) begin
            opcode  = test_opcodes[i];
            instr   = test_instrs[i];
            #20;
            $display("Time[ %0t ]: i = 0x%h, signExt = 0x%h, opcode = 0x%h, instr = 0x%h",
                $time, i, signExt, opcode, instr
            );
            if (imm != gold_imms[i]) begin
                $display("ERROR: imm(0x%h) != gold_imm[%0d](0x%h)!",
                    imm, i, gold_imms[i]
                );
                errs = errs + 1;
            end
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule