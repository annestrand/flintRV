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

`include "types.vh"

module Regfile (
    input                       i_clk       /*verilator public*/,
                                i_wrEn      /*verilator public*/,
    input   [(ADDR_WIDTH-1):0]  i_rs1Addr   /*verilator public*/,
                                i_rs2Addr   /*verilator public*/,
                                i_rdAddr    /*verilator public*/,
    input   [(XLEN-1):0]        i_rdData    /*verilator public*/,
    output  [(XLEN-1):0]        o_rs1Data   /*verilator public*/,
                                o_rs2Data   /*verilator public*/
);
    parameter XLEN          /*verilator public*/ = 32;
    parameter ADDR_WIDTH    /*verilator public*/ = 5;

    reg                 r_fwdRs1En      /*verilator public*/,
                        r_fwdRs2En      /*verilator public*/;
    reg  [(XLEN-1):0]   r_rdDataSave    /*verilator public*/;
    wire [(XLEN-1):0]   w_rs1PortOut    /*verilator public*/,
                        w_rs2PortOut    /*verilator public*/;

    /*
        NOTE:   Infer 2 copied/synced 32x32 (2048 KBits) BRAMs (i.e. one BRAM per read-port)
                rather than just 1 32x32 (1024 KBits) BRAM. This is somewhat wasteful but is
                simpler. Alternate approach is to have the 2 "banks" configured as 2 32x16
                BRAMs w/ additional banking logic for wr_en and output forwarding
                (no duplication with this approach but adds some more Tpcq at the output).
    */
    DualPortRam #(
        .XLEN(XLEN),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) RS1_PORT_RAM (
        .i_clk                (i_clk),
        .i_we                 (i_wrEn),
        .i_dataIn             (i_rdData),
        .i_rAddr              (i_rs1Addr),
        .i_wAddr              (i_rdAddr),
        .o_q                  (w_rs1PortOut)
    );
    DualPortRam #(
        .XLEN(XLEN),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) RS2_PORT_RAM (
        .i_clk                (i_clk),
        .i_we                 (i_wrEn),
        .i_dataIn             (i_rdData),
        .i_rAddr              (i_rs2Addr),
        .i_wAddr              (i_rdAddr),
        .o_q                  (w_rs2PortOut)
    );

    // Forward r_rdDataSave on a Read-During-Write (RDW) case - else read from regfile normally
    always @(posedge i_clk) begin
        r_fwdRs1En      <= (i_rs1Addr == i_rdAddr) && i_wrEn;
        r_fwdRs2En      <= (i_rs2Addr == i_rdAddr) && i_wrEn;
        r_rdDataSave    <= i_rdData;
    end
    assign o_rs1Data    = r_fwdRs1En ? r_rdDataSave : w_rs1PortOut;
    assign o_rs2Data    = r_fwdRs2En ? r_rdDataSave : w_rs2PortOut;

endmodule
