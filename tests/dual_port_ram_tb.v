`include "DualPortRam.v"

module DualPortRam_tb;
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;
    reg                         clk, we;
    reg     [(DATA_WIDTH-1):0]  dataIn;
    reg     [(ADDR_WIDTH-1):0]  rAddr, wAddr;
    wire    [(DATA_WIDTH-1):0]  q;

    DualPortRam DualPortRam_dut(.*);
    defparam DualPortRam_dut.DATA_WIDTH = DATA_WIDTH;
    defparam DualPortRam_dut.ADDR_WIDTH = ADDR_WIDTH;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/dual_port_ram_tb.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    reg [31:0] testData [0:9];
    initial begin
        testData[0] = 32'hdeadbeef;
        testData[1] = 32'h8badf00d;
        testData[2] = 32'h00c0ffee;
        testData[3] = 32'hdeadc0de;
        testData[4] = 32'hbadf000d;
        testData[5] = 32'hdefac8ed;
        testData[6] = 32'hcafebabe;
        testData[7] = 32'hdeadd00d;
        testData[8] = 32'hcafed00d;
        testData[9] = 32'hdeadbabe;
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        clk     = 0;
        we      = 1;
        dataIn  = 'd0;
        rAddr   = 'd0;
        wAddr   = 'd0;
        #20;
        $display("\n=== Writing data =========================================");
        for (i=0; i<10; i=i+1) begin // Write
            #20; clk = ~clk;
            wAddr  = i[4:0];
            dataIn = testData[i];
            #20; clk = ~clk;
            $display("Test[ %2d ]: wAddr = %b || dataIn = 0x%08h", i, wAddr, dataIn);
        end
        we      = 0;
        $display("\n=== Reading data =========================================");
        for (i=0; i<10; i=i+1) begin // Read
            #20; clk = ~clk;
            rAddr = i[4:0];
            #20; clk = ~clk;
            if (q != testData[i]) resultStr = "ERROR";
            else                  resultStr = "PASS ";
            $display("Test[ %2d ]: rAddr = %b || q      = 0x%08h ... %s", i, rAddr, q, resultStr);
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
    end

endmodule