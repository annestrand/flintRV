`include "types.vh"

module boredcore (
    input                       i_clk, i_rst, i_ifValid, i_memValid,
    input   [INSTR_WIDTH-1:0]   i_instr,
    input          [XLEN-1:0]   i_dataIn,
    output                      o_storeReq, o_loadReq,
    output         [XLEN-1:0]   o_pcOut, o_dataAddr, o_dataOut
);
    // CPU configs
    parameter         PC_START              = 0;
    parameter         REGFILE_ADDR_WIDTH    = 5;    //  4 for RV32E (otherwise 5)
    parameter         INSTR_WIDTH           = 32;   // 16 for RV32C (otherwise 32)
    parameter         XLEN                  = 32;
    // Helper Aliases
    localparam  [4:0] REG_0                 = 5'b00000; // Register x0
    // Init values
    initial begin
        PC = PC_START;
    end

    // Pipeline regs (p_*)
    localparam  EXEC = 0;
    localparam  MEM  = 1;
    localparam  WB   = 2;
    reg [XLEN-1:0]  p_rs1       [EXEC:WB];
    reg [XLEN-1:0]  p_rs2       [EXEC:WB];
    reg [XLEN-1:0]  p_aluOut    [EXEC:WB];
    reg [XLEN-1:0]  p_readData  [EXEC:WB];
    reg [XLEN-1:0]  p_PC        [EXEC:WB];
    reg [XLEN-1:0]  p_IMM       [EXEC:WB];
    reg      [6:0]  p_funct7    [EXEC:WB];
    reg      [4:0]  p_rs1Addr   [EXEC:WB];
    reg      [4:0]  p_rs2Addr   [EXEC:WB];
    reg      [4:0]  p_rdAddr    [EXEC:WB];
    reg      [3:0]  p_aluOp     [EXEC:WB];
    reg      [2:0]  p_funct3    [EXEC:WB];
    reg             p_mem_w     [EXEC:WB];
    reg             p_reg_w     [EXEC:WB];
    reg             p_mem2reg   [EXEC:WB];
    reg             p_exec_a    [EXEC:WB];
    reg             p_exec_b    [EXEC:WB];
    reg             p_bra       [EXEC:WB];
    reg             p_jmp       [EXEC:WB];
    // Internal wires/regs
    reg  [XLEN-1:0] PC, PCReg, instrReg;
    wire [XLEN-1:0] IMM, aluOut, jumpAddr, loadData, rs1Out, rs2Out, rdDataSave, rs2FwdOut;
    wire      [3:0] aluOp;
    wire            exec_a, exec_b, mem_w, reg_w, mem2reg, bra, jmp, fwdRdwRs1, fwdRdwRs2;
    wire [XLEN-1:0] WB_result       = p_mem2reg[WB] ? loadData : p_aluOut[WB];
    wire            braMispredict   = p_bra[EXEC] && aluOut[0];                 // Assume branch not-taken
    wire            writeRd         = `RD(instrReg) != REG_0 ? reg_w : 1'b0;    // Skip regfile write for x0
    wire            pcJump          = braMispredict || p_jmp[EXEC];
    //          (Forwarding logic)
    wire            RS1_fwd_mem     = p_reg_w[MEM] && (p_rs1Addr[EXEC] == p_rdAddr[MEM]);
    wire            RS1_fwd_wb      = ~RS1_fwd_mem && p_reg_w[WB] && (p_rs1Addr[EXEC] == p_rdAddr[WB]);
    wire            RS1_fwd_reg_rdw = ~RS1_fwd_wb  && fwdRdwRs1;
    wire            RS2_fwd_mem     = p_reg_w[MEM] && (p_rs2Addr[EXEC] == p_rdAddr[MEM]);
    wire            RS2_fwd_wb      = ~RS2_fwd_mem && p_reg_w[WB] && (p_rs2Addr[EXEC] == p_rdAddr[WB]);
    wire            RS2_fwd_reg_rdw = ~RS2_fwd_wb  && fwdRdwRs2;
    wire      [1:0] fwdRs1          = RS1_fwd_reg_rdw ? `FWD_REG_RDW : {RS1_fwd_wb, RS1_fwd_mem},
                    fwdRs2          = RS2_fwd_reg_rdw ? `FWD_REG_RDW : {RS2_fwd_wb, RS2_fwd_mem};
    //          (Stall and flush logic)
    wire            load_hazard     = p_mem2reg[EXEC] && (
                                        (`RS1(instrReg) == p_rdAddr[EXEC]) || (`RS2(instrReg) == p_rdAddr[EXEC])
                                    );
    wire            load_wait       = o_loadReq && ~i_memValid;
    wire            FETCH_stall     = ~i_ifValid || EXEC_stall || MEM_stall || load_hazard;
    wire            EXEC_stall      = MEM_stall;
    wire            MEM_stall       = load_wait;
    wire            FETCH_flush     = i_rst || braMispredict || p_jmp[EXEC];
    wire            EXEC_flush      = i_rst || braMispredict || p_jmp[EXEC] || load_hazard /* bubble */;
    wire            MEM_flush       = i_rst;
    wire            WB_flush        = i_rst || load_wait /* bubble */;

    // Core submodules
    FetchDecode FETCH_DECODE_unit(
        .i_instr              (instrReg),
        .o_imm                (IMM),
        .o_aluOp              (aluOp),
        .o_exec_a             (exec_a),
        .o_exec_b             (exec_b),
        .o_mem_w              (mem_w),
        .o_reg_w              (reg_w),
        .o_mem2reg            (mem2reg),
        .o_bra                (bra),
        .o_jmp                (jmp)
    );
    Execute #(.XLEN(XLEN)) EXECUTE_unit (
        .i_funct7             (p_funct7[EXEC]),
        .i_funct3             (p_funct3[EXEC]),
        .i_aluOp              (p_aluOp[EXEC]),
        .i_fwdRs1             (fwdRs1),
        .i_fwdRs2             (fwdRs2),
        .i_aluSrcA            (p_exec_a[EXEC]),
        .i_aluSrcB            (p_exec_b[EXEC]),
        .i_EXEC_rs1           (p_rs1[EXEC]),
        .i_EXEC_rs2           (p_rs2[EXEC]),
        .i_MEM_rd             (p_aluOut[MEM]),
        .i_WB_rd              (WB_result),
        .i_rdDataSave         (rdDataSave),
        .i_PC                 (p_PC[EXEC]),
        .i_IMM                (p_IMM[EXEC]),
        .o_aluOut             (aluOut),
        .o_addrGenOut         (jumpAddr),
        .o_rs2FwdOut          (rs2FwdOut)
    );
    Memory MEMORY_unit(
        .i_funct3             (p_funct3[MEM]),
        .i_dataIn             (p_rs2[MEM]),
        .o_dataOut            (o_dataOut)
    );
    Writeback WRITEBACK_unit(
        .i_funct3             (p_funct3[WB]),
        .i_dataIn             (p_readData[WB]),
        .o_dataOut            (loadData)
    );
    Regfile #(.XLEN(XLEN), .ADDR_WIDTH(REGFILE_ADDR_WIDTH)) REGFILE_unit (
        .i_clk          (i_clk),
        .i_wrEn         (p_reg_w[WB]),
        .i_rs1Addr      (`RS1(i_instr)),
        .i_rs2Addr      (`RS2(i_instr)),
        .i_rdAddr       (p_rdAddr[WB]),
        .i_rdData       (WB_result),
        .o_rs1Data      (rs1Out),
        .o_rs2Data      (rs2Out),
        .o_rdDataSave   (rdDataSave),
        .o_fwdRdwRs1    (fwdRdwRs1),
        .o_fwdRdwRs2    (fwdRdwRs2)
    );

    // Pipeline CTRL reg assignments
    always @(posedge i_clk) begin
        // --- Execute ---
        p_aluOp    [EXEC]  <= EXEC_flush ? 4'd0 : EXEC_stall ? p_aluOp   [EXEC] : aluOp;
        p_mem_w    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem_w   [EXEC] : mem_w;
        p_reg_w    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_reg_w   [EXEC] : writeRd;
        p_mem2reg  [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem2reg [EXEC] : mem2reg;
        p_exec_a   [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_a  [EXEC] : exec_a;
        p_exec_b   [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_b  [EXEC] : exec_b;
        p_bra      [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_bra     [EXEC] : bra;
        p_jmp      [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_jmp     [EXEC] : jmp;
        // --- Memory ---
        p_mem_w    [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_mem_w    [MEM] : p_mem_w   [EXEC];
        p_reg_w    [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_reg_w    [MEM] : p_reg_w   [EXEC];
        p_mem2reg  [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_mem2reg  [MEM] : p_mem2reg [EXEC];
        // --- Writeback ---
        p_reg_w    [WB]    <= WB_flush ? 1'd0 : p_reg_w   [MEM];
        p_mem2reg  [WB]    <= WB_flush ? 1'd0 : p_mem2reg [MEM];
    end
    // Pipeline DATA reg assignments
    always @(posedge i_clk) begin
        // --- Execute ---
        p_rs1      [EXEC]  <= EXEC_stall ? p_rs1     [EXEC] : rs1Out;
        p_rs2      [EXEC]  <= EXEC_stall ? p_rs2     [EXEC] : rs2Out;
        p_IMM      [EXEC]  <= EXEC_stall ? p_IMM     [EXEC] : IMM;
        p_PC       [EXEC]  <= EXEC_stall ? p_PC      [EXEC] : PCReg;
        p_funct7   [EXEC]  <= EXEC_stall ? p_funct7  [EXEC] : `FUNCT7(instrReg);
        p_funct3   [EXEC]  <= EXEC_stall ? p_funct3  [EXEC] : `FUNCT3(instrReg);
        p_rs1Addr  [EXEC]  <= EXEC_stall ? p_rs1Addr [EXEC] : `RS1(instrReg);
        p_rs2Addr  [EXEC]  <= EXEC_stall ? p_rs2Addr [EXEC] : `RS2(instrReg);
        p_rdAddr   [EXEC]  <= EXEC_stall ? p_rdAddr  [EXEC] : `RD(instrReg);
        // --- Memory ---
        p_rs2      [MEM]   <= MEM_stall ? p_rs2    [MEM] : rs2FwdOut;
        p_rdAddr   [MEM]   <= MEM_stall ? p_rdAddr [MEM] : p_rdAddr  [EXEC];
        p_funct3   [MEM]   <= MEM_stall ? p_funct3 [MEM] : p_funct3  [EXEC];
        p_aluOut   [MEM]   <= MEM_stall ? p_aluOut [MEM] : aluOut;
        // --- Writeback ---
        p_aluOut   [WB]    <= p_aluOut  [MEM];
        p_rdAddr   [WB]    <= p_rdAddr  [MEM];
        p_funct3   [WB]    <= p_funct3  [MEM];
        p_readData [WB]    <= i_dataIn;
    end

    // Fetch/Decode reg assignments
    always @(posedge i_clk) begin
        PC          <=  i_rst       ?   {(XLEN){1'b0}}  :
                        FETCH_stall ?   PC              :
                        pcJump      ?   jumpAddr        :
                                        PC + 32'd4;
        // Buffer PC reg to balance the 1cc BRAM-based regfile read
        PCReg       <=  FETCH_flush ?   {(XLEN){1'b0}}  :
                        FETCH_stall ?   PCReg           :
                                        PC;
        // Buffer instruction fetch to balance the 1cc BRAM-based regfile read
        instrReg    <=  FETCH_flush ?   {(XLEN){1'b0}}  :
                        FETCH_stall ?   instrReg        :
                                        i_instr;
    end

    // CPU outputs
    assign o_pcOut      = PC;
    assign o_dataAddr   = p_aluOut[MEM];
    assign o_storeReq   = p_mem_w[MEM];
    assign o_loadReq    = p_mem2reg[MEM];

endmodule
