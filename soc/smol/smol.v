// Really simple example SoC design
module smol (
    input   i_clk, i_rst,
    output  o_led
);
    wire [31:0] pcOut, dataAddr, dataOut, bootRomOut, dataMemOut;
    reg  [31:0] dataIn;
    wire loadReq, storeReq;

    reg ifValid     = 1'b0; // Reading/Writing from DualPortRam takes 1cc (we can pipeline the reads after)
    reg memValid    = 1'b0; // Reading/Writing from DualPortRam takes 1cc

    // IMEM ROM (from "common/")
    bootrom #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(11), // 2KB
        .MEMFILE("firmware.mem")
    ) IMEM (
        .i_clk                  (i_clk),
        .i_en                   (1'b1),
        .i_addr                 (pcOut[10:0]),
        .o_data                 (bootRomOut)
    );
    // Data memory (this module is included in "g_core.v")
    DualPortRam #(
        .XLEN(32),
        .ADDR_WIDTH(11) // 2KB
    ) DMEM (
        .i_clk                  (i_clk),
        .i_we                   (dmem_data_sel && storeReq),
        .i_dataIn               (dataOut),
        .i_rAddr                (dataAddr[10:0]),
        .i_wAddr                (dataAddr[10:0]),
        .o_q                    (dataMemOut)
    );
    // CPU
    CPU CPU_unit (
        .i_clk                  (i_clk),
        .i_rst                  (i_rst),
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
        ledReg <= i_rst ? 32'd0 : (storeReq && led_data_sel) ? dataOut : ledReg;
    end

    // Data memory valid logic on load/store requests (reset after each transaction)
    always @(posedge i_clk) begin
        memValid <= (i_rst || memValid) ? 1'b0 : (loadReq | storeReq);
    end
    // Instruction memory valid logic (we need to wait 1cc on start/rst)
    always @(posedge i_clk) begin
        ifValid <= i_rst ? 1'b0 : 1'b1;
    end

    // Simple memory map controller
    // Address decoding logic
    // -----------------------------------------------------------------------\
    // | Address Range             | Description                               |
    // | ------------------------- | ---------------------------------------   |
    // | 0x00000000 ... 0x000001FF | Internal IMEM ROM (BRAM) - 2KB (readonly) |
    // | 0x00000200 ... 0x000003FF | Internal DMEM (BRAM) - 2KB                |
    // | 0x00003000 ... 0x00003003 | Output LED                                |
    // -----------------------------------------------------------------------/
    wire imem_data_sel       = ~dataAddr[12] & ~dataAddr[9];
    wire dmem_data_sel       = ~dataAddr[12] &  dataAddr[9];
    wire led_data_sel        =  dataAddr[12];
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