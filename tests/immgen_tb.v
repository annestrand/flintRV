`include "types.vh"
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
    reg [31:0]  test_vector         [0:26];
    reg [31:0]  test_gold_vector    [0:26];
    initial begin
        $readmemh("build/immgen.mem", test_vector);
        $readmemb("build/immgen_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0;
    initial begin
        $display("Running random ImmGen tests...\n");
        instr   = 'd0;
        #20;
        for (i=0; i<27; i=i+1) begin
            // Note: RISC-V Verilog Objcopy seems to output big-endian for some reason, swap to little here
            instr = `ENDIAN_SWP_32(test_vector[i]);
            #20;
            if ($signed(imm) != $signed(test_gold_vector[i]))   resultStr = "ERROR";
            else                                                resultStr = "PASS ";
            $display("Test[ %2d ]: instr = 0x%8h || imm = %b ... %s",
                i, instr, $signed(imm), resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule