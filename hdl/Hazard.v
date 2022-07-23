module Hazard (
    // Forwarding
    input           i_MEM_rd_reg_write, i_WB_rd_reg_write,
    input   [4:0]   i_EXEC_rs1, i_EXEC_rs2, i_MEM_rd, i_WB_rd,
    output  [1:0]   o_FWD_rs1, o_FWD_rs2,
    // Stall and Flush
    input           i_BRA, i_JMP, i_FETCH_valid, i_MEM_valid, i_EXEC_mem2reg,
    input   [4:0]   i_FETCH_rs1, i_FETCH_rs2, i_EXEC_rd,
    output          o_FETCH_stall, o_EXEC_stall,
                    o_EXEC_flush,  o_MEM_flush
);
    // Forwarding logic
    wire RS1_fwd_mem        = i_MEM_rd_reg_write && (i_EXEC_rs1 == i_MEM_rd);
    wire RS1_fwd_wb         = ~RS1_fwd_mem && i_WB_rd_reg_write && (i_EXEC_rs1 == i_WB_rd);
    wire RS2_fwd_mem        = i_MEM_rd_reg_write && (i_EXEC_rs2 == i_MEM_rd);
    wire RS2_fwd_wb         = ~RS2_fwd_mem && i_WB_rd_reg_write && (i_EXEC_rs2 == i_WB_rd);
    assign o_FWD_rs1        = {RS1_fwd_wb, RS1_fwd_mem};
    assign o_FWD_rs2        = {RS2_fwd_wb, RS2_fwd_mem};

    // Stall and flush logic
    wire   load_stall     = i_EXEC_mem2reg  && ((i_FETCH_rs1 == i_EXEC_rd) || (i_FETCH_rs2 == i_EXEC_rd));
    assign o_EXEC_stall   = ~i_MEM_valid;       // Invalid D-Fetch
    assign o_FETCH_stall  = ~i_FETCH_valid  ||  // Invalid I-Fetch
                            o_EXEC_stall    ||
                            load_stall;
    assign o_MEM_flush    = o_EXEC_stall;       // Bubble
    assign o_EXEC_flush   = ~o_EXEC_stall   &&
                            i_BRA           ||  // Mispredicted branch
                            i_JMP           ||
                            o_FETCH_stall;      // Bubble

endmodule
