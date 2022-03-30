`include "fetch_decode.v"

module ImmGen_tb;
    reg     [31:0]  instr;
    wire    [31:0]  imm;

    ImmGen ImmGen_dut(instr, imm);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/immgen_tb.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:25];
    reg [31:0]  test_gold_vector    [0:25];
    initial begin
        $readmemh("build/immgen_tb.mem", test_vector);
        $readmemb("build/immgen_tb.gold.mem", test_gold_vector);
    end

    // Test loop
    integer i = 0, errs = 0;
    initial begin
        signExt = 'd0;
        opcode  = 'd0;
        instr   = 'd0;
        #20;
        for (i=0; i<26; i=i+1) begin
            opcode  = test_opcodes[i];
            instr   = test_instrs[i];
            #20;
            $display("Time[ %0t ]: i = %0d, signExt = %0d, opcode = 0x%h, instr = 0x%h",
                $time, i, signExt, opcode, instr
            );
            if ($signed(imm) != $signed(gold_imms[i])) begin
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