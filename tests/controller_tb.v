`include "fetch_decode.v"
`include "types.vh"
`include "ucode.vh"

module Controller_tb;
    reg     [31:0] instr,
    wire    [15:0] ctrlSignals

    Controller Controller_dut(instr, ctrlSignals);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("build/controller_tb.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    // Test vectors
    reg [31:0]  test_vector         [0:26];
    reg [15:0]  test_gold_vector    [0:26];
    integer x = 0;
    initial begin
        $readmemh("build/controller.mem", test_vector);
        `define INSTR(NAME, ISA_ENC, ENC, EX_OP, EXEA, EXEB, LDEXT, MEMR, MEMW, REGW, M2R, BRA, JMP) \
            test_gold_vector
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0;
    initial begin
        $display("Running random ImmGen tests...\n");
        instr   = 'd0;
        #20;
        for (i=0; i<27; i=i+1) begin
            instr = test_vector[i];
            if (ctrlSignals != test_gold_vector[i]) resultStr = "ERROR";
            else                                    resultStr = "PASS ";
            $display("Test[ %2d ]: instr = 0x%8h || imm = %b ... %s",
                i, instr, ctrlSignals, resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule