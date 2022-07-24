`include "Hazard.v"

module Hazard_tb;
    // Forwarding
    reg           i_MEM_rd_reg_write, i_WB_rd_reg_write;
    reg   [4:0]   i_EXEC_rs1, i_EXEC_rs2, i_MEM_rd, i_WB_rd;
    wire  [1:0]   o_FWD_rs1, o_FWD_rs2;
    // Stall and Flush
    reg           i_BRA, i_JMP, i_FETCH_valid, i_MEM_valid, i_EXEC_mem2reg;
    reg   [4:0]   i_FETCH_rs1, i_FETCH_rs2, i_EXEC_rd;
    wire          o_FETCH_stall, o_EXEC_stall, o_EXEC_flush, o_MEM_flush;

    Hazard Hazard_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("out/sub_Hazard.vcd");
        $dumpvars(0, Hazard_tb);
    end
`endif // DUMP_VCD

    // Test vectors
    reg [41:0]  test_fwd_vector         [0:31];
    reg [41:0]  test_hzd_vector         [0:31];
    reg [7:0]   test_gold_fwd_vector    [0:31];
    reg [7:0]   test_gold_hzd_vector    [0:31];
    initial begin
        $readmemb("out/sub_Hazard_fwd.mem", test_fwd_vector);
        $readmemb("out/sub_Hazard_fwd_gold.mem", test_gold_fwd_vector);
        $readmemb("out/sub_Hazard_hzd.mem", test_hzd_vector);
        $readmemb("out/sub_Hazard_hzd_gold.mem", test_gold_hzd_vector);
    end

    // Test loop
    reg [39:0] resultStr;
    integer i = 0, errs = 0, subfail = 0;
    initial begin
        i_MEM_rd_reg_write    = 'd0;
        i_WB_rd_reg_write     = 'd0;
        i_EXEC_rs1            = 'd0;
        i_EXEC_rs2            = 'd0;
        i_MEM_rd              = 'd0;
        i_WB_rd               = 'd0;
        i_BRA                 = 'd0;
        i_JMP                 = 'd0;
        i_FETCH_valid         = 'd0;
        i_MEM_valid           = 'd0;
        i_EXEC_mem2reg        = 'd0;
        i_FETCH_rs1           = 'd0;
        i_FETCH_rs2           = 'd0;
        i_EXEC_rd             = 'd0;
        $display("\n=== Running random Hazard (FWD) tests... =========================================");
        #20;
        $display("INPUTS : i_MEM_rd_reg_write, i_WB_rd_reg_write, i_EXEC_rs1, i_EXEC_rs2, i_MEM_rd, i_WB_rd");
        $display("OUTPUTS: o_FWD_rs1, o_FWD_rs2");
        $display("");
        for (i=0; i<32; i=i+1) begin
            subfail = 0;
            {
                i_MEM_rd_reg_write,
                i_WB_rd_reg_write,
                i_EXEC_rs1,
                i_EXEC_rs2,
                i_MEM_rd,
                i_WB_rd,
                i_BRA,
                i_JMP,
                i_FETCH_valid,
                i_MEM_valid,
                i_EXEC_mem2reg,
                i_FETCH_rs1,
                i_FETCH_rs2,
                i_EXEC_rd
            } = test_fwd_vector[i];
            #20;
            if ({o_FWD_rs1, o_FWD_rs2} != test_gold_fwd_vector[i][7:4]) resultStr = "ERROR";
            else                                                    resultStr = "PASS ";
            $display("Test[ %2d ]: %b_%b_%b_%b_%b_%b || %b_%b ... %s",
                i,
                i_MEM_rd_reg_write,
                i_WB_rd_reg_write,
                i_EXEC_rs1,
                i_EXEC_rs2,
                i_MEM_rd,
                i_WB_rd,
                o_FWD_rs1,
                o_FWD_rs2,
                resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
        $display("\n=== Running random Hazard (HZD) tests... =========================================");
        $display("INPUTS : i_BRA, i_JMP, i_FETCH_valid, i_MEM_valid, i_EXEC_mem2reg, i_FETCH_rs1, i_FETCH_rs2, i_EXEC_rd");
        $display("OUTPUTS: o_FETCH_stall, o_EXEC_stall, o_EXEC_flush, o_MEM_flush");
        $display("");
        for (i=0; i<32; i=i+1) begin
            subfail = 0;
            {
                i_MEM_rd_reg_write,
                i_WB_rd_reg_write,
                i_EXEC_rs1,
                i_EXEC_rs2,
                i_MEM_rd,
                i_WB_rd,
                i_BRA,
                i_JMP,
                i_FETCH_valid,
                i_MEM_valid,
                i_EXEC_mem2reg,
                i_FETCH_rs1,
                i_FETCH_rs2,
                i_EXEC_rd
            } = test_hzd_vector[i];
            #20;
            if ({o_FETCH_stall, o_EXEC_stall, o_EXEC_flush, o_MEM_flush} != test_gold_hzd_vector[i][3:0]) resultStr = "ERROR";
            else                                                                                  resultStr = "PASS ";
            $display("Test[ %2d ]: %b_%b_%b_%b_%b_%b_%b_%b || %b_%b_%b_%b ... %s",
                i,
                i_BRA,
                i_JMP,
                i_FETCH_valid,
                i_MEM_valid,
                i_EXEC_mem2reg,
                i_FETCH_rs1,
                i_FETCH_rs2,
                i_EXEC_rd,
                o_FETCH_stall, o_EXEC_stall, o_EXEC_flush, o_MEM_flush,
                resultStr
            );
            if (resultStr == "ERROR") errs = errs + 1;
        end
        if (errs > 0)   $display("\nFAILED: %0d", errs);
        else            $display("\nPASSED");
        // TODO: Use VPI to have $myReturn(...) return the "errs" value?
    end

endmodule