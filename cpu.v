`include "types.vh"
// ====================================================================================================================
module pineapplecore
(
    input               clk, rst,
    input       [31:0]  instr, dataIn,
    input               ifValid, memValid,
    output      [31:0]  pcOut, dataAddr, dataOut,
    output              dataWe
);
    localparam  [4:0] REG_0 = 5'b00000; // Register x0

    // Pipeline regs (p_*)
    localparam  EXEC = 0;
    localparam  MEM  = 1;
    localparam  WB   = 2;
    reg         p_mem_w     [EXEC:WB];
    reg         p_reg_w     [EXEC:WB];
    reg         p_mem2reg   [EXEC:WB];
    reg [2:0]   p_funct3    [EXEC:WB];
    reg [6:0]   p_funct7    [EXEC:WB];
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
    reg     [31:0]  PC, instrReg;
    wire    [31:0]  IMM,
                    aluOut,
                    jumpAddr,
                    loadData;
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
    wire    [31:0]  WB_result       = p_mem2reg[WB] ? loadData : p_aluOut[WB];
    wire            braMispredict   = p_bra[EXEC] && aluOut[0];                 // Assume branch not-taken
    wire            writeRd         = (`RD(instrReg) != REG_0) ? reg_w : 1'b0;  // Skip regfile write for x0
    wire            pcJump          = braMispredict || p_jmp[EXEC];

    // Core modules
    FetchDecode FETCH_DECODE_unit(
        .instr              (instrReg           ),
        .imm                (IMM                ),
        .aluOp              (aluOp              ),
        .exec_a             (exec_a             ),
        .exec_b             (exec_b             ),
        .mem_w              (mem_w              ),
        .reg_w              (reg_w              ),
        .mem2reg            (mem2reg            ),
        .bra                (bra                ),
        .jmp                (jmp                )
    );
    Execute EXECUTE_unit(
        .funct7             (p_funct7[EXEC]     ),
        .funct3             (p_funct3[EXEC]     ),
        .aluOp              (p_aluOp[EXEC]      ),
        .fwdRs1             (fwdRs1             ),
        .fwdRs2             (fwdRs2             ),
        .aluSrcA            (p_exec_a[EXEC]     ),
        .aluSrcB            (p_exec_b[EXEC]     ),
        .EXEC_rs1           (p_rs1[EXEC]        ),
        .EXEC_rs2           (p_rs2[EXEC]        ),
        .MEM_rd             (p_aluOut[MEM]      ),
        .WB_rd              (WB_result          ),
        .PC                 (p_PC[EXEC]         ),
        .IMM                (p_IMM[EXEC]        ),
        .aluOut             (aluOut             ),
        .addrGenOut         (jumpAddr           )
    );
    Memory MEMORY_unit(
        .funct3             (p_funct3[MEM]      ),
        .dataIn             (p_rs2[MEM]         ),
        .dataOut            (dataOut            )
    );
    Writeback WRITEBACK_unit(
        .funct3             (p_funct3[WB]       ),
        .dataIn             (p_readData[WB]     ),
        .dataOut            (loadData           )
    );
    Hazard HZD_FWD_unit(
        // Forwarding
        .MEM_rd_reg_write   (p_reg_w[MEM]       ),
        .WB_rd_reg_write    (p_reg_w[WB]        ),
        .EXEC_rs1           (p_rs1Addr[EXEC]    ),
        .EXEC_rs2           (p_rs2Addr[EXEC]    ),
        .MEM_rd             (p_rdAddr[MEM]      ),
        .WB_rd              (p_rdAddr[WB]       ),
        .FWD_rs1            (fwdRs1             ),
        .FWD_rs2            (fwdRs2             ),
        // Stall and Flush
        .BRA                (braMispredict      ),
        .JMP                (p_jmp[EXEC]        ),
        .FETCH_valid        (ifValid            ),
        .MEM_valid          (memValid           ),
        .EXEC_mem2reg       (p_mem2reg[EXEC]    ),
        .FETCH_rs1          (`RS1(instrReg)     ),
        .FETCH_rs2          (`RS2(instrReg)     ),
        .EXEC_rd            (p_rdAddr[EXEC]     ),
        .FETCH_stall        (FETCH_stall        ),
        .EXEC_stall         (EXEC_stall         ),
        .EXEC_flush         (EXEC_flush         ),
        .MEM_flush          (MEM_flush          )
    );

    // Regfile assignments
    /*
        NOTE:   Infer 2 copied/synced 32x32 (2048 KBits) BRAMs (i.e. one BRAM per read-port)
                rather than just 1 32x32 (1024 KBits) BRAM. This is somewhat wasteful but is
                simpler. Alternate approach is to have the 2 "banks" configured as 2 32x16
                BRAMs w/ additional banking logic for wr_en and output forwarding
                (no duplication with this approach but adds some more Tpcq at the output).
    */
    wire [31:0] rs1Out, rs2Out;
    DualPortRam RS1_PORT (
        .clk                (clk                ),
        .we                 (p_reg_w[WB]        ),
        .dataIn             (WB_result          ),
        .rAddr              (`RS1(instr)        ),
        .wAddr              (p_rdAddr[WB]       ),
        .q                  (rs1Out             )
    );
    DualPortRam RS2_PORT (
        .clk                (clk                ),
        .we                 (p_reg_w[WB]        ),
        .dataIn             (WB_result          ),
        .rAddr              (`RS2(instr)        ),
        .wAddr              (p_rdAddr[WB]       ),
        .q                  (rs2Out             )
    );
    defparam RS1_PORT.DATA_WIDTH = 32;
    defparam RS2_PORT.DATA_WIDTH = 32;
    defparam RS1_PORT.ADDR_WIDTH = 5;
    defparam RS2_PORT.ADDR_WIDTH = 5;

    // Pipeline assignments
    always @(posedge clk) begin
        // Execute
        p_rs1       [EXEC]  <= rst || EXEC_flush ? 32'd0 : EXEC_stall ? p_rs1       [EXEC] : rs1Out;
        p_rs2       [EXEC]  <= rst || EXEC_flush ? 32'd0 : EXEC_stall ? p_rs2       [EXEC] : rs2Out;
        p_rdAddr    [EXEC]  <= rst || EXEC_flush ?  5'd0 : EXEC_stall ? p_rdAddr    [EXEC] : `RD(instrReg);
        p_IMM       [EXEC]  <= rst || EXEC_flush ? 32'd0 : EXEC_stall ? p_IMM       [EXEC] : IMM;
        p_PC        [EXEC]  <= rst || EXEC_flush ? 32'd0 : EXEC_stall ? p_PC        [EXEC] : PC;
        p_funct3    [EXEC]  <= rst || EXEC_flush ?  3'd0 : EXEC_stall ? p_funct3    [EXEC] : `FUNCT3(instrReg);
        p_funct7    [EXEC]  <= rst || EXEC_flush ?  7'd0 : EXEC_stall ? p_funct7    [EXEC] : `FUNCT7(instrReg);
        p_mem_w     [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_mem_w     [EXEC] : mem_w;
        p_reg_w     [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_reg_w     [EXEC] : writeRd;
        p_mem2reg   [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_mem2reg   [EXEC] : mem2reg;
        p_rs1Addr   [EXEC]  <= rst || EXEC_flush ?  5'd0 : EXEC_stall ? p_rs1Addr   [EXEC] : `RS1(instrReg);
        p_rs2Addr   [EXEC]  <= rst || EXEC_flush ?  5'd0 : EXEC_stall ? p_rs2Addr   [EXEC] : `RS2(instrReg);
        p_rdAddr    [EXEC]  <= rst || EXEC_flush ?  5'd0 : EXEC_stall ? p_rdAddr    [EXEC] : `RD(instrReg);
        p_aluOp     [EXEC]  <= rst || EXEC_flush ?  4'd0 : EXEC_stall ? p_aluOp     [EXEC] : aluOp;
        p_exec_a    [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_exec_a    [EXEC] : exec_a;
        p_exec_b    [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_exec_b    [EXEC] : exec_b;
        p_bra       [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_bra       [EXEC] : bra;
        p_jmp       [EXEC]  <= rst || EXEC_flush ?  1'd0 : EXEC_stall ? p_jmp       [EXEC] : jmp;
        // Memory
        p_mem_w     [MEM]   <= rst || MEM_flush ?  1'd0 : p_mem_w      [EXEC];
        p_reg_w     [MEM]   <= rst || MEM_flush ?  1'd0 : p_reg_w      [EXEC];
        p_mem2reg   [MEM]   <= rst || MEM_flush ?  1'd0 : p_mem2reg    [EXEC];
        p_funct3    [MEM]   <= rst || MEM_flush ?  3'd0 : p_funct3     [EXEC];
        p_rs2       [MEM]   <= rst || MEM_flush ? 32'd0 : p_rs2        [EXEC];
        p_aluOut    [MEM]   <= rst || MEM_flush ? 32'd0 : aluOut;
        p_rdAddr    [MEM]   <= rst || MEM_flush ?  5'd0 : p_rdAddr     [EXEC];
        // Writeback
        p_reg_w     [WB]    <= rst ? 32'd0  : p_reg_w       [MEM];
        p_mem2reg   [WB]    <= rst ? 1'd0   : p_mem2reg     [MEM];
        p_funct3    [WB]    <= rst ? 3'd0   : p_funct3      [MEM];
        p_aluOut    [WB]    <= rst ? 32'd0  : p_aluOut      [MEM];
        p_rdAddr    [WB]    <= rst ? 5'd0   : p_rdAddr      [MEM];
        p_readData  [WB]    <= rst ? 32'd0  : dataIn;
    end

    // Program counter and instruction reg assignments
    always @(posedge clk) begin
        PC          <=  rst         ?   32'd0       :
                        FETCH_stall ?   PC          :
                        pcJump      ?   jumpAddr    :
                                        PC + 32'd4;
        // Buffer instruction fetch to balance the BRAM-based regfile read
        instrReg    <=  rst || EXEC_stall   ?   32'd0    :
                        FETCH_stall         ?   instrReg :
                                                instr;
    end

    // Other output assignments
    assign pcOut    = PC;
    assign dataAddr = p_aluOut[MEM];
    assign dataWe   = p_mem_w[MEM];

// ====================================================================================================================
// === CPU-state dumping for simulation ===============================================================================
// ====================================================================================================================
`ifdef SIM
    always @(posedge clk) begin
        // TODO: Dump other items?
        $display("[pineapplecore - TRACE]:");
        $display("             PC: 0x%08h", PC);
        $display("    INSTRUCTION: 0x%08h", instrReg);
        // Dump disassembled instruction
        `DBG_INSTR_TRACE_PRINT(instrReg, IMM)
        $display("%s", `PRINT_LINE);
    end
`endif // SIM

endmodule