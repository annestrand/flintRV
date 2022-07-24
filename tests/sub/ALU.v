`include "ALU.v"

module IAlu_tb;
    reg     [31:0]  i_a, i_b;
    reg     [4:0]   i_op;
    wire    [31:0]  o_result;

    ALU Alu_dut(.*);
    defparam Alu_dut.WIDTH = 32;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("out/ALU.vcd");
        $dumpvars(0, IAlu_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [68:0]  test_vector         [0:15];
    reg [31:0]  test_gold_vector    [0:15];
    initial begin
        $readmemb("out/sub_ALU.mem", test_vector);
        $readmemb("out/sub_ALU_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        $display("Running random ALU tests...\n");
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
            $display("Test[ %2d ]: i_a = %10d | i_b = %10d | i_op = %2d || o_result = %10d ... %s",
                i, $signed(i_a), $signed(i_b), i_op, $signed(o_result), resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule