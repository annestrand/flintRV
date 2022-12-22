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

// Really simple example SoC design
module drop32soc (
    input   i_clk, i_rst,
    output  o_led
);
    wire [31:0] pcOut, dataAddr, dataOut, bootRomOut, dataMemOut;
    reg  [31:0] dataIn;
    wire loadReq, storeReq, imem_data_sel, dmem_data_sel, led_data_sel;

    reg ifValid     = 1'b0; // Reading/Writing from DualPortRam takes 1cc (we can pipeline the reads after)
    reg memValid    = 1'b0; // Reading/Writing from DualPortRam takes 1cc

    // TODO: Add UART module
    // ...

    // Reset logic
    reg [3:0] resetReg  = 0;
    wire startupRstDone = &resetReg;
    wire rst            = i_rst | !startupRstDone;
    always @(posedge i_clk) begin
        resetReg <= startupRstDone ? resetReg : resetReg + 4'b1;
    end

    // IMEM ROM (bootrom.v)
    bootrom #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10), // 1KB
        .MEMFILE("firmware.mem")
    ) IMEM (
        .i_clk                  (i_clk),
        .i_en                   (1'b1),
        .i_addr                 ({2'd0, pcOut[9:2]}),
        .o_data                 (bootRomOut)
    );
    // Data memory (core_generated.v)
    DualPortRam #(
        .XLEN(32),
        .ADDR_WIDTH(10) // 1KB
    ) DMEM (
        .i_clk                  (i_clk),
        .i_we                   (dmem_data_sel && storeReq),
        .i_dataIn               (dataOut),
        .i_rAddr                (dataAddr[10:0]),
        .i_wAddr                (dataAddr[10:0]),
        .o_q                    (dataMemOut)
    );
    // CPU (core_generated.v)
    CPU CPU_unit (
        .i_clk                  (i_clk),
        .i_rst                  (rst),
        .i_ifValid              (ifValid),
        .i_memValid             (memValid),
        .i_instr                (bootRomOut),
        .i_dataIn               (dataIn),
        .o_storeReq             (storeReq),
        .o_loadReq              (loadReq),
        .o_pcOut                (pcOut),
        .o_dataAddr             (dataAddr),
        .o_dataOut              (dataOut)
    );

    // Output MMIO led reg
    reg [31:0] ledReg = 32'd0;
    always @(posedge i_clk) begin
        ledReg <= rst ? 32'd0 : (storeReq && led_data_sel) ? dataOut : ledReg;
    end

    // Data memory valid logic on load/store requests (reset after each transaction)
    always @(posedge i_clk) begin
        memValid <= (rst || memValid) ? 1'b0 : (loadReq | storeReq);
    end
    // Instruction memory valid logic (need to wait 1cc per transaction)
    always @(posedge i_clk) begin
        ifValid <= rst ? 1'b0 : ~ifValid;
    end

    // Simple memory map controller
    // Address decoding logic
    // -------------------------------------------------------------------------
    // | Address Range             | Description                               |
    // | ------------------------- | ---------------------------------------   |
    // | 0x00000000 ... 0x000003FF | Internal IMEM ROM (BRAM) - 1KB (readonly) |
    // | 0x00000400 ... 0x000007FF | Internal DMEM (BRAM) - 1KB                |
    // | 0x00003000 ... 0x00003003 | Output LED                                |
    // -------------------------------------------------------------------------
    assign imem_data_sel    = ~dataAddr[12] & ~dataAddr[10];
    assign dmem_data_sel    = ~dataAddr[12] &  dataAddr[10];
    assign led_data_sel     =  dataAddr[12];
    always @* begin
        if (imem_data_sel) begin
            dataIn = bootRomOut;
        end else if (dmem_data_sel) begin
            dataIn = dataMemOut;
        end else if (led_data_sel) begin
            dataIn = ledReg;
        end else begin
            dataIn = 32'd0;
        end
    end

    // SoC I/O
    assign o_led = ledReg[0];

endmodule