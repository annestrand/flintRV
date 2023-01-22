// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`define SWAP_BYTE_BITS(x) {x[0],x[1],x[2],x[3],x[4],x[5],x[6],x[7]}

module IAlu_tb;
    reg     [31:0]  i_a, i_b;
    reg     [4:0]   i_op;
    wire    [31:0]  o_result;
    wire            o_eflag, o_cflag, o_lflag;

    ALU Alu_dut(.*);
    defparam Alu_dut.XLEN = 32;

    parameter TEST_RANGE    = 2**5;
    parameter TEST_OP_RANGE = 2**8;
    integer i               = 0,
            j               = 0,
            errs            = 0;

    reg [31:0] r;
    initial begin
        i_a       = 'd0;
        i_b       = 'd0;
        i_op      = 'd0;
        #20;

        // Test loop
        for (i = 0; i < TEST_OP_RANGE; i = i + 1) begin
            i_op = i;
            for (j = 0; j < TEST_RANGE; j = j + 1) begin
                i_a = {j[7:0], j[7:0], j[7:0], j[7:0]};
                i_b = {`SWAP_BYTE_BITS(j), `SWAP_BYTE_BITS(j), `SWAP_BYTE_BITS(j), `SWAP_BYTE_BITS(j)};
                #20;
                case (i_op)
                    `ALU_EXEC_ADD   : begin
                        r = i_a + i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_PASSB : begin
                        r = i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_ADD4A : begin
                        r = i_a + 4;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_XOR   : begin
                        r = i_a ^ i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SRL   : begin
                        r = i_a >> i_b[4:0];
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SRA   : begin
                        r = $signed(i_a) >>> i_b[4:0];
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_OR    : begin
                        r = i_a | i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_AND   : begin
                        r = i_a & i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SUB   ,
                    `ALU_EXEC_EQ    ,
                    `ALU_EXEC_NEQ   ,
                    `ALU_EXEC_SGTE  ,
                    `ALU_EXEC_SGTEU : begin
                        r = i_a - i_b;
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SLL   : begin
                        r = i_a << i_b[4:0];
                        if (o_result != r) begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SLT   : begin
                        r = $signed(i_a) < $signed(i_b);
                        if (o_result != r)      begin errs = errs + 1; end
                        if (o_lflag  != r[0])   begin errs = errs + 1; end
                    end
                    `ALU_EXEC_SLTU  : begin
                        r = i_a < i_b;
                        if (o_result != r)      begin errs = errs + 1; end
                        if (o_cflag == r[0])    begin errs = errs + 1; end
                    end
                    default         : begin
                        // Default op is adder/subtractor
                        if ((i_op == `ALU_EXEC_SGTE) || (i_op == `ALU_EXEC_SGTEU)) begin
                            r = i_a - i_b;
                        end else begin
                            r = i_a + i_b;
                        end
                        if (o_result != r) begin errs = errs + 1; end
                    end
                endcase
                if (i_a == i_b && !o_eflag) begin  errs = errs + 1; end
            end
        end
        if (errs > 0)   $display("ALU tests - FAILED: %0d", errs);
        else            $display("ALU tests - PASSED");
    end

endmodule