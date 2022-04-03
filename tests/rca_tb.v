`include "execute.v"

module RCA_tb;
    reg     [31:0]  a, b;
    reg             subEn;
    wire    [31:0]  result;
    wire            cout;

    RCA RCA_dut(a, b, subEn, result, cout);
    defparam RCA_dut.WIDTH = 32;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/rca_tb.vcd");
        $dumpvars(0, RCA_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [64:0]  test_vector         [0:31];
    reg [31:0]  test_gold_vector    [0:31];
    initial begin
        $readmemb("build/adder.mem", test_vector);
        $readmemb("build/adder_gold.mem", test_gold_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        $display("Running random Ripple Carry Adder (RCA) tests...\n");
        a       = 'd0;
        b       = 'd0;
        subEn   = 'd0;
        #20;
        for (i=0; i<32; i=i+1) begin
            subfail = 0;
            {a,b,subEn} = test_vector[i];
            #20;
            if ($signed(result) != $signed(test_gold_vector[i]))    resultStr = "ERROR";
            else                                                    resultStr = "PASS ";
            $display("Test[ %2d ]: a = %8d | b = %8d | subEn = %1d || result = %8d ... %s",
                i, $signed(a), $signed(b), subEn, $signed(result), resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule