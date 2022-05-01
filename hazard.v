// ====================================================================================================================
module Hazard
(
    // Forwarding
    input           MEM_rd_reg_write, WB_rd_reg_write,
    input   [4:0]   EXEC_rs1, EXEC_rs2, MEM_rd, WB_rd,
    output  [1:0]   FWD_rs1, FWD_rs2,
    // Stall and Flush
    input           BRA, JMP, FETCH_valid, MEM_valid, EXEC_mem_read,
    input   [4:0]   FETCH_rs1, FETCH_rs2, EXEC_rd,
    output          FETCH_stall, EXEC_stall,
                    EXEC_flush, MEM_flush
);
    // Forwarding logic
    wire RS1_fwd_mem    = MEM_rd_reg_write && (EXEC_rs1 == MEM_rd);
    wire RS1_fwd_wb     = ~RS1_fwd_mem && WB_rd_reg_write && (EXEC_rs1 == WB_rd);
    wire RS2_fwd_mem    = MEM_rd_reg_write && (EXEC_rs2 == MEM_rd);
    wire RS2_fwd_wb     = ~RS2_fwd_mem && WB_rd_reg_write && (EXEC_rs2 == WB_rd);
    assign FWD_rs1      = {RS1_fwd_wb, RS1_fwd_mem};
    assign FWD_rs2      = {RS2_fwd_wb, RS2_fwd_mem};

    // Stall and flush logic
    wire   load_stall   = EXEC_mem_read && ((FETCH_rs1 == EXEC_rd) || (FETCH_rs2 == EXEC_rd))
    assign EXEC_stall   = ~MEM_valid;       // Invalid D-Fetch
    assign FETCH_stall  = ~FETCH_valid  ||  // Invalid I-Fetch
                          EXEC_stall    ||
                          load_stall;
    assign MEM_flush    = EXEC_stall;       // Bubble
    assign EXEC_flush   = BRA           ||  // Mispredicted branch
                          JMP           ||
                          FETCH_stall;      // Bubble

endmodule