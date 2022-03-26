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
    reg [31:0]  test_a      [0:2];
    reg [31:0]  test_b      [0:2];
    reg [0:0]   test_subEn  [0:2];
    reg [31:0]  gold_result [0:2];
    initial begin
        // TODO: Good for now ... replace with $readmemh(...) later
        test_a[0]       = 1435;
        test_b[0]       = 145;
        test_a[1]       = 1435;
        test_b[1]       = 145;
        test_subEn[0]   = 0;
        test_subEn[1]   = 1;
        gold_result[0]  = 1580; // 1435 + 145
        gold_result[1]  = 1290; // 1435 - 145
    end

    // Test loop
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        a       = 'd0;
        b       = 'd0;
        subEn   = 'd0;
        #20;
        for (i=0; i<2; i=i+1) begin
            subfail = 0;
            a       = test_a[i];
            b       = test_b[i];
            subEn   = test_subEn[i];
            #20;
            $display("Time[ %0t ]: i = %0d, a = %0d, b = %0d, subEn = %0d",
                $time, i, a, b, subEn
            );
            if (result != gold_result[i]) begin
                $display("ERROR: result(%0d) != gold_result[%0d](%0d)!",
                    result, i, gold_result[i]
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