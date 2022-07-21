`include "DualPortRam.v"
`include "Regfile.v"

module Regfile_tb;
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;
    reg                       i_clk, i_wrEn;
    reg   [(ADDR_WIDTH-1):0]  i_rs1Addr, i_rs2Addr, i_rdAddr;
    reg   [(DATA_WIDTH-1):0]  i_rdData;
    wire  [(DATA_WIDTH-1):0]  o_rs1Data, o_rs2Data;

    Regfile Regfile_dut(.*);
    defparam Regfile_dut.DATA_WIDTH = DATA_WIDTH;
    defparam Regfile_dut.ADDR_WIDTH = ADDR_WIDTH;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("out/Regfile.vcd");
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
        i_clk       = 0;
        i_wrEn      = 1;
        i_rs1Addr   = 5'd0;
        i_rs2Addr   = 5'd0;
        i_rdAddr    = 5'd0;
        i_rdData    = 32'd0;

        #20;
        // ============================================================================================================
        $display("\n=== Writing data =========================================");
        for (i=0; i<10; i=i+1) begin // Write
            #20; i_clk = ~i_clk;
            i_rdAddr = i[4:0];
            i_rdData = testData[i];
            #20; i_clk = ~i_clk;
            $display("Test[ %2d ]: wAddr = %b || dataIn = 0x%08h", i, i_rdAddr, i_rdData);
        end
        i_wrEn = 0;
        // ============================================================================================================
        $display("\n=== Reading data =========================================");
        for (i=0; i<10; i=i+1) begin // Read
            #20; i_clk = ~i_clk;
            i_rs1Addr = i[4:0];
            i_rs2Addr = i[4:0];
            #20; i_clk = ~i_clk;
            if (o_rs1Data != testData[i]) resultStr = "ERROR (o_rs1Data)";
            else                          resultStr = "PASS ";
            if (o_rs2Data != testData[i]) resultStr = "ERROR (o_rs2Data)";
            else                          resultStr = "PASS ";
            $display("Test[ %2d ]: rAddr = %b || q      = 0x%08h ... %s", i, i_rs1Addr, o_rs1Data, resultStr);
            if (resultStr == "ERROR") errs = errs + 1;
        end
        // ============================================================================================================
        $display("\n=== Write-through read =========================================");
        #20; i_clk = ~i_clk;
        #20; i_clk = ~i_clk;
        i_rdAddr = 5'd5;
        i_rdData = 32'hffffffff;
        i_rs1Addr = 5'd5;
        i_rs2Addr = 5'd5;
        i_wrEn = 1;
        // clk-in the new value, verify the read value
        #20; i_clk = ~i_clk;
        #20; i_clk = ~i_clk;
        if (o_rs1Data != 32'hffffffff)  resultStr = "ERROR (o_rs1Data)";
        else                            resultStr = "PASS ";
        if (o_rs2Data != 32'hffffffff)  resultStr = "ERROR (o_rs2Data)";
        else                            resultStr = "PASS ";
        $display("Test[ Write-through read ]: ... %s", resultStr);
        if (resultStr == "ERROR") errs = errs + 1;

        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
    end

endmodule