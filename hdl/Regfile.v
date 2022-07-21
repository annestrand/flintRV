`include "types.vh"

module Regfile (
    input                       i_clk, i_wrEn,
    input   [(ADDR_WIDTH-1):0]  i_rs1Addr, i_rs2Addr, i_rdAddr,
    input   [(DATA_WIDTH-1):0]  i_rdData,
    output  [(DATA_WIDTH-1):0]  o_rs1Data, o_rs2Data
);
    parameter DATA_WIDTH    = 32;
    parameter ADDR_WIDTH    = 5;

    reg                     r_fwdRs1En, r_fwdRs2En;
    reg  [(DATA_WIDTH-1):0] r_rdDataSave;
    wire [(DATA_WIDTH-1):0] w_rs1PortOut, w_rs2PortOut;

    /*
        NOTE:   Infer 2 copied/synced 32x32 (2048 KBits) BRAMs (i.e. one BRAM per read-port)
                rather than just 1 32x32 (1024 KBits) BRAM. This is somewhat wasteful but is
                simpler. Alternate approach is to have the 2 "banks" configured as 2 32x16
                BRAMs w/ additional banking logic for wr_en and output forwarding
                (no duplication with this approach but adds some more Tpcq at the output).
    */
    DualPortRam #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) RS1_PORT (
        .clk                (i_clk          ),
        .we                 (i_wrEn         ),
        .dataIn             (i_rdData       ),
        .rAddr              (i_rs1Addr      ),
        .wAddr              (i_rdAddr       ),
        .q                  (w_rs1PortOut   )
    );
    DualPortRam #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) RS2_PORT (
        .clk                (i_clk          ),
        .we                 (i_wrEn         ),
        .dataIn             (i_rdData       ),
        .rAddr              (i_rs2Addr      ),
        .wAddr              (i_rdAddr       ),
        .q                  (w_rs2PortOut   )
    );

    always @(posedge i_clk) begin
        r_fwdRs1En      <= (i_rs1Addr == i_rdAddr) && i_wrEn;
        r_fwdRs2En      <= (i_rs2Addr == i_rdAddr) && i_wrEn;
        r_rdDataSave    <= i_rdData;
    end
    assign o_rs1Data = r_fwdRs1En ? r_rdDataSave : w_rs1PortOut;
    assign o_rs2Data = r_fwdRs2En ? r_rdDataSave : w_rs2PortOut;

endmodule