module ImmGen_tb;
    reg     [31:0]  i_instr;
    wire    [31:0]  o_imm;

    ImmGen ImmGen_dut(.*);

    // Test vectors
    parameter UJ_TEST_COUNT     = 2**20;
    parameter SBI_TEST_COUNT    = 2**12;
    integer i                   = 0,
            j                   = 0,
            errs                = 0;
    initial begin
        // U-type ===========================================================================================
        for (i = 0; i < UJ_TEST_COUNT; i = i + 1) begin
            i_instr = {i[19:0], i[4:0], `U_LUI}; #20
            if (o_imm != {i_instr[31:12], {12{1'b0}}}) begin
                errs = errs + 1;
            end
        end
        for (i = 0; i < UJ_TEST_COUNT; i = i + 1) begin
            i_instr = {i[19:0], i[4:0], `U_AUIPC}; #20
            if (o_imm != {i_instr[31:12], {12{1'b0}}}) begin
                errs = errs + 1;
            end
        end

        // J-type ===========================================================================================
        for (i = 0; i < UJ_TEST_COUNT; i = i + 1) begin
            i_instr = {i[19], i[9:0], i[10], i[18:11], i[4:0], `J}; #20
            if (o_imm != {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0}) begin
                errs = errs + 1;
            end
        end

        // S-type ==========================================================================================
        for (i = 0; i < SBI_TEST_COUNT; i = i + 1) begin
            i_instr = {i[11:5], i[4:0], i[4:0], i[2:0], i[4:0], `S}; #20
            if (o_imm != {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]}) begin
                errs = errs + 1;
            end
        end

        // B-type ===========================================================================================
        for (i = 0; i < SBI_TEST_COUNT; i = i + 1) begin
            i_instr = {i[12], i[10:5], i[4:0], i[4:0], i[2:0], i[4:1], i[11], `B}; #20
            if (o_imm != {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0}) begin
                errs = errs + 1;
            end
        end

        // I-type (Skip R, Fence, and System types) =========================================================
        for (i = 0; i < SBI_TEST_COUNT; i = i + 1) begin
            i_instr = {i[11:0], i[4:0], i[2:0], i[4:0], `I_JUMP}; #20
            if (o_imm != {{20{i_instr[31]}}, i_instr[31:20]}) begin
                errs = errs + 1;
            end
        end
        for (i = 0; i < SBI_TEST_COUNT; i = i + 1) begin
            i_instr = {i[11:0], i[4:0], i[2:0], i[4:0], `I_LOAD}; #20
            if (o_imm != {{20{i_instr[31]}}, i_instr[31:20]}) begin
                errs = errs + 1;
            end
        end
        for (i = 0; i < SBI_TEST_COUNT; i = i + 1) begin
            i_instr = {i[11:0], i[4:0], i[2:0], i[4:0], `I_ARITH}; #20
            if (o_imm != {{20{i_instr[31]}}, i_instr[31:20]}) begin
                errs = errs + 1;
            end
        end

        if (errs > 0)   begin $display("ImmGen tests - FAILED: %0d", errs);    end
        else            begin $display("ImmGen tests - PASSED");               end
    end

endmodule