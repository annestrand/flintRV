module IAlu_tb;
    reg     [31:0]  i_a, i_b;
    reg     [4:0]   i_op;
    wire    [31:0]  o_result;

    ALU Alu_dut(.*);
    defparam Alu_dut.XLEN = 32;

    // Test vectors
    reg [68:0]  test_vector         [0:15];
    reg [31:0]  test_gold_vector    [0:15];
    initial begin
        $readmemb("build/tests/sub/sub_ALU.mem", test_vector);
        $readmemb("build/tests/sub/sub_ALU_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        i_a       = 'd0;
        i_b       = 'd0;
        i_op      = 'd0;
        #20;
        for (i=0; i<16; i=i+1) begin
            subfail = 0;
            {i_a,i_b,i_op} = test_vector[i];
            #20;
            if ($signed(o_result) != $signed(test_gold_vector[i])) resultStr = "ERROR";
            else                                                   resultStr = "PASS ";
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("ALU tests - FAILED: %0d", errs);
        else            $display("ALU tests - PASSED");
    end

endmodule