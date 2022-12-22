// Copyright (c) 2022 Austin Annestrand
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module Regfile_tb;
    localparam XLEN = 32;
    localparam ADDR_WIDTH = 5;
    reg                         i_clk, i_wrEn;
    reg   [(ADDR_WIDTH-1):0]    i_rs1Addr, i_rs2Addr, i_rdAddr;
    reg   [(XLEN-1):0]          i_rdData;
    wire  [(XLEN-1):0]          o_rs1Data, o_rs2Data;

    Regfile Regfile_dut(.*);
    defparam Regfile_dut.XLEN = XLEN;
    defparam Regfile_dut.ADDR_WIDTH = ADDR_WIDTH;

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
        for (i=0; i<10; i=i+1) begin // Write
            #20; i_clk = ~i_clk;
            i_rdAddr = i[4:0];
            i_rdData = testData[i];
            #20; i_clk = ~i_clk;
        end
        i_wrEn = 0;
        // ============================================================================================================
        for (i=0; i<10; i=i+1) begin // Read
            #20; i_clk = ~i_clk;
            i_rs1Addr = i[4:0];
            i_rs2Addr = i[4:0];
            #20; i_clk = ~i_clk;
            if (o_rs1Data != testData[i]) resultStr = "ERROR (o_rs1Data)";
            else                          resultStr = "PASS ";
            if (o_rs2Data != testData[i]) resultStr = "ERROR (o_rs2Data)";
            else                          resultStr = "PASS ";
            if (resultStr == "ERROR") errs = errs + 1;
        end
        // ============================================================================================================
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
        if (resultStr == "ERROR") errs = errs + 1;

        if (errs > 0)   $display("Regfile tests - FAILED: %0d", errs);
        else            $display("Regfile tests - PASSED");
    end

endmodule