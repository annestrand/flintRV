module ImmGen_tb;
    reg     [31:0]  i_instr;
    wire    [31:0]  o_imm;

    ImmGen ImmGen_dut(.*);

    // Test vectors
    reg [31:0]  test_vector         [0:26];
    reg [31:0]  test_gold_vector    [0:26];
    initial begin
        $readmemh("build/tests/sub/sub_ImmGen.mem", test_vector);
        $readmemb("build/tests/sub/sub_ImmGen_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0;
    initial begin
        i_instr   = 'd0;
        #20;
        for (i=0; i<27; i=i+1) begin
            i_instr = test_vector[i]; #20;
            if ($signed(o_imm) != $signed(test_gold_vector[i])) resultStr = "ERROR";
            else                                                resultStr = "PASS ";
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("ImmGen tests - FAILED: %0d", errs);
        else            $display("ImmGen tests - PASSED");
    end

endmodule