`include "types.vh"
`include "cpu.v"
`include "fetch_decode.v"
`include "execute.v"
`include "hazard.v"
`include "memory.v"
`include "writeback.v"
`include "dual_port_ram.v"

module cpu_tb;
    reg               clk;
    reg       [31:0]  instr, dataIn;
    reg               ifValid, memValid;
    wire      [31:0]  pcOut, dataAddr, dataOut;
    wire              dataWe;

    pineapplecore pineapplecore_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/cpu_tb.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    reg [31:0] test_vector [0:8];
    initial begin
        $readmemh("build/cpu.mem", test_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        clk         = 0;
        ifValid     = 1;
        memValid    = 1;
        dataIn      = 32'hcafebabe;
        #20;
        $display("=== Run CPU =========================================");
        for (i=0; i<40; i=i+1) begin
            instr = `ENDIAN_SWP_32(test_vector[i]);
            // Toggle clk
            #20; clk = ~clk; #20; clk = ~clk;
        end
    end

endmodule