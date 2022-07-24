`include "ImmGen.v"

module ImmGen_tb;
    reg     [31:0]  i_instr;
    wire    [31:0]  o_imm;

    ImmGen ImmGen_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("obj_dir/sub/ImmGen.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:26];
    reg [31:0]  test_gold_vector    [0:26];
    initial begin
        $readmemh("obj_dir/sub/sub_ImmGen.mem", test_vector);
        $readmemb("obj_dir/sub/sub_ImmGen_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0;
    initial begin
        $display("Running random ImmGen tests...\n");
        i_instr   = 'd0;
        #20;
        for (i=0; i<27; i=i+1) begin
            // Note: RISC-V Verilog Objcopy seems to output big-endian for some reason, swap to little here
            i_instr = `ENDIAN_SWP_32(test_vector[i]);

            #20;
            if ($signed(o_imm) != $signed(test_gold_vector[i])) resultStr = "ERROR";
            else                                                resultStr = "PASS ";
            $display("Test[ %2d ]: i_instr = 0x%8h || o_imm = %b ... %s",
                i, i_instr, $signed(o_imm), resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule