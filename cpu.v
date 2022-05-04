`include "types.vh"
// ====================================================================================================================
module pineapplecore
(
    input               clk,
    input       [31:0]  instr, dataIn,
    input               ifValid, memValid,
    output      [31:0]  pcOut, dataAddr, dataOut,
    output              dataWe
);
    localparam  [4:0] REG0 = 5'b00000; // Register x0

    // Pipeline regs (p_*)
    localparam  EXEC = 0;
    localparam  MEM  = 1;
    localparam  WB   = 2;
    reg         p_mem_w     [EXEC:WB];
    reg         p_reg_w     [EXEC:WB];
    reg         p_mem2reg   [EXEC:WB];
    reg         p_funct3    [EXEC:WB];
    reg         p_funct7    [EXEC:WB];
    reg [31:0]  p_rs1       [EXEC:WB];
    reg [31:0]  p_rs2       [EXEC:WB];
    reg [31:0]  p_aluOut    [EXEC:WB];
    reg [31:0]  p_readData  [EXEC:WB];
    reg [31:0]  p_PC        [EXEC:WB];
    reg [31:0]  p_IMM       [EXEC:WB];
    reg [4:0]   p_rs1Addr   [EXEC:WB];
    reg [4:0]   p_rs2Addr   [EXEC:WB];
    reg [4:0]   p_rdAddr    [EXEC:WB];
    reg [3:0]   p_aluOp     [EXEC:WB];
    reg         p_exec_a    [EXEC:WB];
    reg         p_exec_b    [EXEC:WB];
    reg         p_bra       [EXEC:WB];
    reg         p_jmp       [EXEC:WB];

    // Internal wires/regs
    reg     [31:0]  PC;
    reg     [31:0]  regfile [0:31];
    wire    [31:0]  IMM,
                    aluOut,
                    addrGenOut,
                    loadData;
    wire    [31:0]  WB_result = p_mem2reg[WB] ? loadData : p_aluOut[WB];
    wire    [1:0]   fwdRs1,
                    fwdRs2;
    wire    [3:0]   aluOp;
    wire            exec_a,
                    exec_b,
                    mem_w,
                    reg_w,
                    mem2reg,
                    bra,
                    jmp,
                    FETCH_stall,
                    EXEC_stall,
                    EXEC_flush,
                    MEM_flush;
    wire            braMispredict = p_bra[EXEC] && aluOut[0];   // Assume branch not-taken
    wire            writeRd = (`RD(instr) != REG0) ? reg_w : 0; // Skip regfile write for x0

    // Core modules
    FetchDecode FETCH_DECODE_unit(
        .instr              (instr                      ),
        .imm                (IMM                        ),
        .aluOp              (aluOp                      ),
        .exec_a             (exec_a                     ),
        .exec_b             (exec_b                     ),
        .mem_w              (mem_w                      ),
        .reg_w              (reg_w                      ),
        .mem2reg            (mem2reg                    ),
        .bra                (bra                        ),
        .jmp                (jmp                        )
    );
    Execute EXECUTE_unit(
        .funct7             (p_funct7[EXEC]             ),
        .funct3             (p_funct3[EXEC]             ),
        .aluOp              (p_aluOp[EXEC]              ),
        .fwdRs1             (fwdRs1                     ),
        .fwdRs2             (fwdRs2                     ),
        .aluSrcA            (p_exec_a[EXEC]             ),
        .aluSrcB            (p_exec_b[EXEC]             ),
        .EXEC_rs1           (p_rs1[EXEC]                ),
        .EXEC_rs2           (p_rs2[EXEC]                ),
        .MEM_rd             (p_aluOut[MEM]              ),
        .WB_rd              (WB_result                  ),
        .PC                 (p_PC[EXEC]                 ),
        .IMM                (p_IMM[EXEC]                ),
        .aluOut             (aluOut                     ),
        .addrGenOut         (addrGenOut                 )
    );
    Memory MEMORY_unit(
        .funct3             (p_funct3[MEM]              ),
        .dataIn             (p_rs2[MEM]                 ),
        .dataOut            (dataOut                    )
    );
    Writeback WRITEBACK_unit(
        .funct3             (p_funct3[WB]               ),
        .dataIn             (p_readData[WB]             ),
        .dataOut            (loadData                   )
    );
    Hazard HZD_FWD_unit(
        // Forwarding
        .MEM_rd_reg_write   (p_reg_w[MEM]               ),
        .WB_rd_reg_write    (p_reg_w[WB]                ),
        .EXEC_rs1           (p_rs1Addr[EXEC]            ),
        .EXEC_rs2           (p_rs2Addr[EXEC]            ),
        .MEM_rd             (p_rdAddr[MEM]              ),
        .WB_rd              (p_rdAddr[WB]               ),
        .FWD_rs1            (fwdRs1                     ),
        .FWD_rs2            (fwdRs2                     ),
        // Stall and Flush
        .BRA                (braMispredict              ),
        .JMP                (p_jmp[EXEC]                ),
        .FETCH_valid        (ifValid                    ),
        .MEM_valid          (memValid                   ),
        .EXEC_mem2reg       (p_mem2reg[EXEC]            ),
        .FETCH_rs1          (`RS1(instr)                ),
        .FETCH_rs2          (`RS2(instr)                ),
        .EXEC_rd            (p_rdAddr[EXEC]             ),
        .FETCH_stall        (FETCH_stall                ),
        .EXEC_stall         (EXEC_stall                 ),
        .EXEC_flush         (EXEC_flush                 ),
        .MEM_flush          (MEM_flush                  )
    );

    // Pipeline logic
    always @(posedge clk) begin
        if (p_reg_w[WB]) begin
            // Update regfile
            regfile[p_rdAddr[WB]] <= WB_result;
        end
        // Execute
        p_rs1       [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rs1       [EXEC] : regfile[`RS1(instr)];
        p_rs2       [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rs2       [EXEC] : regfile[`RS2(instr)];
        p_rdAddr    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rdAddr    [EXEC] : `RD(instr);
        p_IMM       [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_IMM       [EXEC] : IMM;
        p_PC        [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_PC        [EXEC] : PC;
        p_funct3    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_funct3    [EXEC] : `FUNCT3(instr);
        p_funct7    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_funct7    [EXEC] : `FUNCT7(instr);
        p_mem_w     [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_mem_w     [EXEC] : mem_w;
        p_reg_w     [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_reg_w     [EXEC] : writeRd;
        p_mem2reg   [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_mem2reg   [EXEC] : mem2reg;
        p_rs1Addr   [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rs1Addr   [EXEC] : `RS1(instr);
        p_rs2Addr   [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rs2Addr   [EXEC] : `RS2(instr);
        p_rdAddr    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_rdAddr    [EXEC] : `RD(instr);
        p_aluOp     [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_aluOp     [EXEC] : aluOp;
        p_exec_a    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_exec_a    [EXEC] : exec_a;
        p_exec_b    [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_exec_b    [EXEC] : exec_b;
        p_bra       [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_bra       [EXEC] : bra;
        p_jmp       [EXEC]  <= EXEC_flush ? 'd0 : EXEC_stall ? p_jmp       [EXEC] : jmp;
        // Memory
        p_mem_w     [MEM]   <= MEM_flush ? 'd0 : p_mem_w      [EXEC];
        p_reg_w     [MEM]   <= MEM_flush ? 'd0 : p_reg_w      [EXEC];
        p_mem2reg   [MEM]   <= MEM_flush ? 'd0 : p_mem2reg    [EXEC];
        p_funct3    [MEM]   <= MEM_flush ? 'd0 : p_funct3     [EXEC];
        p_rs2       [MEM]   <= MEM_flush ? 'd0 : p_rs2        [EXEC];
        p_aluOut    [MEM]   <= MEM_flush ? 'd0 : aluOut;
        p_rdAddr    [MEM]   <= MEM_flush ? 'd0 : p_rdAddr     [EXEC];
        // Writeback
        p_reg_w     [WB]    <= p_reg_w       [MEM];
        p_mem2reg   [WB]    <= p_mem2reg     [MEM];
        p_funct3    [WB]    <= p_funct3      [MEM];
        p_aluOut    [WB]    <= p_aluOut      [MEM];
        p_rdAddr    [WB]    <= p_rdAddr      [MEM];
        p_readData  [WB]    <= dataIn;
    end

    // Program counter logic
    always @(posedge clk) begin
        PC <= FETCH_stall ? PC : (braMispredict || p_jmp[EXEC]) ? p_IMM[EXEC] + p_PC[EXEC] : PC + 32'd4;
    end

    // Other output assignments
    assign pcOut    = PC;
    assign dataAddr = p_aluOut[MEM];
    assign dataWe   = p_mem_w[MEM];
endmodule