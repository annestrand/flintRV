`include "types.vh"

module AluControl_tb;
    reg     [3:0] i_aluOp;
    reg     [6:0] i_funct7;
    reg     [2:0] i_funct3;
    wire    [4:0] o_aluControl;

    ALU_Control IAluControl_dut(.*);

    // Test vectors
    parameter TEST_COUNT    = 2**14;
    integer i               = 0,
            errs            = 0;
    reg [13:0]  test_vector         [0:TEST_COUNT-1];
    reg  [4:0]  test_gold_vector    [0:TEST_COUNT-1];
    initial begin
        for (i=0; i<TEST_COUNT; i=i+1) begin
            test_vector[i] = i;
            // Gold value assignments
            casez (i)
            /* LUI      */  {`ALU_OP_U_LUI,     7'b???????, 3'b???} : test_gold_vector[i] = `ALU_EXEC_PASSB;
            /* JAL      */  {`ALU_OP_J,         7'b???????, 3'b???} : test_gold_vector[i] = `ALU_EXEC_ADD4A;
            /* JALR     */  {`ALU_OP_I_JUMP,    7'b???????, 3'b???} : test_gold_vector[i] = `ALU_EXEC_ADD4A;
            /* BEQ      */  {`ALU_OP_B,         7'b???????, 3'b000} : test_gold_vector[i] = `ALU_EXEC_EQ;
            /* BNE      */  {`ALU_OP_B,         7'b???????, 3'b001} : test_gold_vector[i] = `ALU_EXEC_NEQ;
            /* BLT      */  {`ALU_OP_B,         7'b???????, 3'b100} : test_gold_vector[i] = `ALU_EXEC_SLT;
            /* SLTI     */  {`ALU_OP_I_ARITH,   7'b???????, 3'b010} : test_gold_vector[i] = `ALU_EXEC_SLT;
            /* SLT      */  {`ALU_OP_R,         7'b0000000, 3'b010} : test_gold_vector[i] = `ALU_EXEC_SLT;
            /* BLTU     */  {`ALU_OP_B,         7'b???????, 3'b110} : test_gold_vector[i] = `ALU_EXEC_SLTU;
            /* SLTIU    */  {`ALU_OP_I_ARITH,   7'b???????, 3'b011} : test_gold_vector[i] = `ALU_EXEC_SLTU;
            /* SLTU     */  {`ALU_OP_R,         7'b0000000, 3'b011} : test_gold_vector[i] = `ALU_EXEC_SLTU;
            /* BGE      */  {`ALU_OP_B,         7'b???????, 3'b101} : test_gold_vector[i] = `ALU_EXEC_SGTE;
            /* BGEU     */  {`ALU_OP_B,         7'b???????, 3'b111} : test_gold_vector[i] = `ALU_EXEC_SGTEU;
            /* XORI     */  {`ALU_OP_I_ARITH,   7'b???????, 3'b100} : test_gold_vector[i] = `ALU_EXEC_XOR;
            /* XOR      */  {`ALU_OP_R,         7'b0000000, 3'b100} : test_gold_vector[i] = `ALU_EXEC_XOR;
            /* ORI      */  {`ALU_OP_I_ARITH,   7'b???????, 3'b110} : test_gold_vector[i] = `ALU_EXEC_OR;
            /* OR       */  {`ALU_OP_R,         7'b0000000, 3'b110} : test_gold_vector[i] = `ALU_EXEC_OR;
            /* ANDI     */  {`ALU_OP_I_ARITH,   7'b???????, 3'b111} : test_gold_vector[i] = `ALU_EXEC_AND;
            /* AND      */  {`ALU_OP_R,         7'b0000000, 3'b111} : test_gold_vector[i] = `ALU_EXEC_AND;
            /* SLLI     */  {`ALU_OP_I_ARITH,   7'b0000000, 3'b001} : test_gold_vector[i] = `ALU_EXEC_SLL;
            /* SLL      */  {`ALU_OP_R,         7'b0000000, 3'b001} : test_gold_vector[i] = `ALU_EXEC_SLL;
            /* SRLI     */  {`ALU_OP_I_ARITH,   7'b0000000, 3'b101} : test_gold_vector[i] = `ALU_EXEC_SRL;
            /* SRL      */  {`ALU_OP_R,         7'b0000000, 3'b101} : test_gold_vector[i] = `ALU_EXEC_SRL;
            /* SRAI     */  {`ALU_OP_I_ARITH,   7'b0100000, 3'b101} : test_gold_vector[i] = `ALU_EXEC_SRA;
            /* SRA      */  {`ALU_OP_R,         7'b0100000, 3'b101} : test_gold_vector[i] = `ALU_EXEC_SRA;
            /* SUB      */  {`ALU_OP_R,         7'b0100000, 3'b000} : test_gold_vector[i] = `ALU_EXEC_SUB;
            /* AUIPC, LB, LH, LW, LBU, LHU, SB, SH, SW, ADDI, ADD, FENCE, ECALL, EBREAK */
                            default                                 : test_gold_vector[i] = `ALU_EXEC_ADD;
            endcase
        end
    end

    // Test loop
    initial begin
        i_aluOp   = 'd0;
        i_funct3  = 'd0;
        i_funct7  = 'd0;
        #20;
        for (i=0; i<TEST_COUNT; i=i+1) begin
            {i_aluOp, i_funct7, i_funct3} = test_vector[i]; #20;
            if (o_aluControl != test_gold_vector[i]) begin errs = errs + 1; end
        end
        if (errs > 0)   begin $display("ALU control tests - FAILED: %0d", errs);    end
        else            begin $display("ALU control tests - PASSED");               end
    end

endmodule