`include "execute.v"

module CLA_tb;
    reg     [31:0]  a, b;
    reg             subEn;
    wire    [31:0]  result;
    wire            cout;

    CLA CLA_dut(a, b, subEn, result, cout);
    defparam CLA_dut.WIDTH = 32;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/cla_tb.vcd");
        $dumpvars(0, CLA_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [64:0]  test_vector         [0:31];
    reg [31:0]  test_gold_vector    [0:31];
    initial begin
        $readmemb("build/cla_tb.mem", test_vector);
        $readmemb("build/cla_tb.gold.mem", test_gold_vector);
    end

    // Test loop
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        a       = 'd0;
        b       = 'd0;
        subEn   = 'd0;
        #20;
        for (i=0; i<32; i=i+1) begin
            subfail = 0;
            {a,b,subEn} = test_vector[i];
            #20;
            $display("Time[ %0t ]: i = %0d, a = %0d, b = %0d, subEn = %0d",
                $time, i, $signed(a), $signed(b), subEn
            );
            if ($signed(result) != $signed(test_gold_vector[i])) begin
                $display("ERROR: result(%0d) != gold_result[%0d](%0d)!",
                    $signed(result), i, $signed(test_gold_vector[i])
                );
                subfail = 1;
            end
            if (subfail) errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule