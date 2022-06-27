`include "cpu.v"
`include "cla.v"
`include "ialu.v"
`include "hazard.v"
`include "memory.v"
`include "immgen.v"
`include "execute.v"
`include "writeback.v"
`include "controller.v"
`include "full_adder.v"
`include "alu_control.v"
`include "fetch_decode.v"
`include "dual_port_ram.v"

module cpu_tb;
    reg               clk, rst;
    reg       [31:0]  instr, dataIn;
    reg               ifValid, memValid;
    wire      [31:0]  pcOut, dataAddr, dataOut;
    wire              dataWe;

    boredcore boredcore_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/cpu_tb.vcd");
        $dumpvars(0, boredcore_dut);
    end
`endif // DUMP_VCD

    reg [31:0] test_vector [0:8];
    initial begin
        $readmemh("build/cpu.mem", test_vector);
    end

    // Init pipeline reg "memory-cells"
    integer x;
    initial begin
        for (x=0; x<3; x=x+1) begin
            $dumpvars(0, boredcore_dut.p_mem_w    [x]);
            $dumpvars(0, boredcore_dut.p_reg_w    [x]);
            $dumpvars(0, boredcore_dut.p_mem2reg  [x]);
            $dumpvars(0, boredcore_dut.p_funct3   [x]);
            $dumpvars(0, boredcore_dut.p_funct7   [x]);
            $dumpvars(0, boredcore_dut.p_rs1      [x]);
            $dumpvars(0, boredcore_dut.p_rs2      [x]);
            $dumpvars(0, boredcore_dut.p_aluOut   [x]);
            $dumpvars(0, boredcore_dut.p_readData [x]);
            $dumpvars(0, boredcore_dut.p_PC       [x]);
            $dumpvars(0, boredcore_dut.p_IMM      [x]);
            $dumpvars(0, boredcore_dut.p_rs1Addr  [x]);
            $dumpvars(0, boredcore_dut.p_rs2Addr  [x]);
            $dumpvars(0, boredcore_dut.p_rdAddr   [x]);
            $dumpvars(0, boredcore_dut.p_aluOp    [x]);
            $dumpvars(0, boredcore_dut.p_exec_a   [x]);
            $dumpvars(0, boredcore_dut.p_exec_b   [x]);
            $dumpvars(0, boredcore_dut.p_bra      [x]);
            $dumpvars(0, boredcore_dut.p_jmp      [x]);
        end
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
        ifValid     = 0; // Not valid until we fetch after the reset
        memValid    = 1;
        dataIn      = 32'hcafebabe;
        instr       = 32'd0;
        // Run though instructions
        for (i=0; i<20; i=i+1) begin
            if (i > 0) begin
                rst = 0;
            end
            if (instr === 32'dx || instr === 32'd0) begin
                ifValid = 0;
            end else begin
                ifValid = 1;
            end
            pcReg       = pcOut[31:2];
            instr       = `ENDIAN_SWP_32(test_vector[pcReg]);

            // Toggle clk
            #20; clk = ~clk; #20; clk = ~clk;
        end
        $display("%s", `PRINT_LINE);
    end

endmodule