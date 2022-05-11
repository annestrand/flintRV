`include "types.vh"
`include "cpu.v"
`include "fetch_decode.v"
`include "execute.v"
`include "hazard.v"
`include "memory.v"
`include "writeback.v"
`include "dual_port_ram.v"

module cpu_tb;
    reg               clk, rst;
    reg       [31:0]  instr, dataIn;
    reg               ifValid, memValid;
    wire      [31:0]  pcOut, dataAddr, dataOut;
    wire              dataWe;

    pineapplecore pineapplecore_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/cpu_tb.vcd");
        $dumpvars(0, pineapplecore_dut);
    end
`endif // DUMP_VCD

    reg [31:0] test_vector [0:8];
    initial begin
        $readmemh("build/cpu.mem", test_vector);
    end

    // Test loop
    reg [31:0] pcReg;
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        $display("%s", `PRINT_LINE);
        // Reset CPU
        clk         = 0;
        rst         = 1;
        ifValid     = 1;
        memValid    = 1;
        dataIn      = 32'hcafebabe;
        instr       = 32'd0;
        // Toggle clk and clear reset line
        #20; clk = ~clk; #20; clk = ~clk;
        rst = 0;
        // Run though instructions
        for (i=0; i<20; i=i+1) begin
            pcReg = pcOut[31:2];
            instr = `ENDIAN_SWP_32(test_vector[pcReg]);
            if (instr === 32'dx) instr = 32'd0;
            // Toggle clk
            #20; clk = ~clk; #20; clk = ~clk;
        end
    end

endmodule