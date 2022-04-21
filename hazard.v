// ====================================================================================================================
module Hazard
(
    // Forwarding
    input           MEM_rd_rw, WB_rd_rw,
    input   [4:0]   EXEC_rs1, EXEC_rs2, MEM_rd, WB_rd,
    output  [1:0]   FWD_rs1, FWD_rs2,
    // Stall and Flush
    input           BRA_mispredict, JMP_ctrl, IF_valid, MEM_valid, EXEC_mem_read,
    input   [4:0]   IF_ID_rs1, IF_ID_rs2, EXEC_rd,
    output          IF_stall, IF_ID_stall, EXEC_MEM_stall,
                    IF_ID_flush, EXEC_MEM_flush, ctrlBubble
);
    // Forwarding logic
    wire RS1_fwd_mem        = MEM_rd_rw && ~|(EXEC_rs1 ^ MEM_rd);
    wire RS1_fwd_wb         = ~RS1_fwd_mem && WB_rd_rw && ~|(EXEC_rs1 ^ WB_rd);
    wire RS2_fwd_mem        = MEM_rd_rw && ~|(EXEC_rs2 ^ MEM_rd);
    wire RS2_fwd_wb         = ~RS2_fwd_mem && WB_rd_rw && ~|(EXEC_rs2 ^ WB_rd);
    assign FWD_rs1          = {RS1_fwd_wb, RS1_fwd_mem};
    assign FWD_rs2          = {RS2_fwd_wb, RS2_fwd_mem};

    // Stall and flush logic
    wire load_stall         = EXEC_mem_read && (~|(IF_ID_rs1 ^ EXEC_rd) || ~|(IF_ID_rs2 ^ EXEC_rd))
    assign IF_stall         = load_stall || ~IF_valid || ~MEM_valid;
    assign IF_ID_stall      = load_stall || ~IF_valid || ~MEM_valid;
    assign EXEC_MEM_stall   = ~MEM_valid;
    assign IF_ID_flush      = JMP_ctrl || BRA_mispredict;
    assign EXEC_MEM_flush   = BRA_mispredict;
    assign ctrlBubble       = load_stall || ~IF_valid || ~MEM_valid;

endmodule
