`include "types.vh"

module boredcore (
    input                       i_clk, i_rst, i_ifValid, i_memValid,
    input   [INSTR_WIDTH-1:0]   i_instr,
    input          [XLEN-1:0]   i_dataIn,
    output                      o_storeReq, o_loadReq,
    output         [XLEN-1:0]   o_pcOut, o_dataAddr, o_dataOut
);
    // CPU configs
    parameter         PC_START              /*verilator public*/ = 0;
    parameter         REGFILE_ADDR_WIDTH    /*verilator public*/ = 5;  //  4 for RV32E (otherwise 5)
    parameter         INSTR_WIDTH           /*verilator public*/ = 32; // 16 for RV32C (otherwise 32)
    parameter         XLEN                  /*verilator public*/ = 32;
    // Helper Aliases
    localparam  [4:0] REG_0                 /*verilator public*/ = 5'b00000; // Register x0
    // Init values
    initial begin
        PC = PC_START;
    end

    // Pipeline regs (p_*)
    localparam  EXEC /*verilator public*/ = 0;
    localparam  MEM  /*verilator public*/ = 1;
    localparam  WB   /*verilator public*/ = 2;
    reg [XLEN-1:0]  p_rs1       [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_rs2       [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_aluOut    [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_readData  [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_PC        [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_IMM       [EXEC:WB] /*verilator public*/;
    reg      [6:0]  p_funct7    [EXEC:WB] /*verilator public*/;
    reg      [4:0]  p_rs1Addr   [EXEC:WB] /*verilator public*/;
    reg      [4:0]  p_rs2Addr   [EXEC:WB] /*verilator public*/;
    reg      [4:0]  p_rdAddr    [EXEC:WB] /*verilator public*/;
    reg      [3:0]  p_aluOp     [EXEC:WB] /*verilator public*/;
    reg      [2:0]  p_funct3    [EXEC:WB] /*verilator public*/;
    reg             p_mem_w     [EXEC:WB] /*verilator public*/;
    reg             p_reg_w     [EXEC:WB] /*verilator public*/;
    reg             p_mem2reg   [EXEC:WB] /*verilator public*/;
    reg             p_exec_a    [EXEC:WB] /*verilator public*/;
    reg             p_exec_b    [EXEC:WB] /*verilator public*/;
    reg             p_bra       [EXEC:WB] /*verilator public*/;
    reg             p_jmp       [EXEC:WB] /*verilator public*/;

    // Internal wires/regs
    reg  [XLEN-1:0] PC              /*verilator public*/,
                    PCReg           /*verilator public*/,
                    instrReg        /*verilator public*/;
    wire [XLEN-1:0] IMM             /*verilator public*/,
                    aluOut          /*verilator public*/,
                    jumpAddr        /*verilator public*/,
                    loadData        /*verilator public*/,
                    rs1Out          /*verilator public*/,
                    rs2Out          /*verilator public*/,
                    rs2FwdOut       /*verilator public*/,
                    WB_result       /*verilator public*/;
    wire      [3:0] aluOp           /*verilator public*/;
    wire      [1:0] fwdRs1          /*verilator public*/,
                    fwdRs2          /*verilator public*/;
    wire            exec_a          /*verilator public*/,
                    exec_b          /*verilator public*/,
                    mem_w           /*verilator public*/,
                    reg_w           /*verilator public*/,
                    mem2reg         /*verilator public*/,
                    bra             /*verilator public*/,
                    jmp             /*verilator public*/,
                    braMispredict   /*verilator public*/,
                    writeRd         /*verilator public*/,
                    pcJump          /*verilator public*/,
                    RS1_fwd_mem     /*verilator public*/,
                    RS1_fwd_wb      /*verilator public*/,
                    RS2_fwd_mem     /*verilator public*/,
                    RS2_fwd_wb      /*verilator public*/,
                    rdFwdRs1En      /*verilator public*/,
                    rdFwdRs2En      /*verilator public*/,
                    load_hazard     /*verilator public*/,
                    load_wait       /*verilator public*/,
                    FETCH_stall     /*verilator public*/,
                    EXEC_stall      /*verilator public*/,
                    MEM_stall       /*verilator public*/,
                    FETCH_flush     /*verilator public*/,
                    EXEC_flush      /*verilator public*/,
                    MEM_flush       /*verilator public*/,
                    WB_flush        /*verilator public*/;

    // Branch/jump logic
    assign pcJump          = braMispredict || p_jmp[EXEC];
    assign braMispredict   = p_bra[EXEC] && aluOut[0];                 // Assume branch not-taken

    // Writeback select and enable logic
    assign WB_result       = p_mem2reg[WB] ? loadData : p_aluOut[WB];
    assign writeRd         = `RD(instrReg) != REG_0 ? reg_w : 1'b0;    // Skip regfile write for x0

    // Forwarding logic
    assign RS1_fwd_mem  = p_reg_w[MEM] && (p_rs1Addr[EXEC] == p_rdAddr[MEM]);
    assign RS1_fwd_wb   = ~RS1_fwd_mem && p_reg_w[WB] && (p_rs1Addr[EXEC] == p_rdAddr[WB]);
    assign RS2_fwd_mem  = p_reg_w[MEM] && (p_rs2Addr[EXEC] == p_rdAddr[MEM]);
    assign RS2_fwd_wb   = ~RS2_fwd_mem && p_reg_w[WB] && (p_rs2Addr[EXEC] == p_rdAddr[WB]);
    assign fwdRs1       = {RS1_fwd_wb, RS1_fwd_mem};
    assign fwdRs2       = {RS2_fwd_wb, RS2_fwd_mem};
    assign rdFwdRs1En   = p_reg_w[WB] && (`RS1(instrReg) == p_rdAddr[WB]); // Bogus read if true, fwd RD[WB]
    assign rdFwdRs2En   = p_reg_w[WB] && (`RS2(instrReg) == p_rdAddr[WB]); // Bogus read if true, fwd RD[WB]
    // Stall and flush logic
    assign load_hazard  = p_mem2reg[EXEC] && ((`RS1(instrReg) == p_rdAddr[EXEC]) || (`RS2(instrReg) == p_rdAddr[EXEC]));
    assign load_wait    = o_loadReq && ~i_memValid;
    assign FETCH_stall  = ~i_ifValid || EXEC_stall || MEM_stall || load_hazard;
    assign EXEC_stall   = MEM_stall;
    assign MEM_stall    = load_wait;
    assign FETCH_flush  = i_rst || braMispredict || p_jmp[EXEC];
    assign EXEC_flush   = i_rst || braMispredict || p_jmp[EXEC] || load_hazard /* bubble */;
    assign MEM_flush    = i_rst;
    assign WB_flush     = i_rst || load_wait /* bubble */;

    // Core submodules
    FetchDecode #(
        .XLEN               (XLEN),
        .REGFILE_ADDR_WIDTH (REGFILE_ADDR_WIDTH)
    ) FETCH_DECODE_unit (
        .i_clk          (i_clk),
        .i_instr        (instrReg),
        .i_regWrEn      (p_reg_w[WB]),
        .i_regRs1Addr   (FETCH_stall ? `RS1(instrReg) : `RS1(i_instr)),
        .i_regRs2Addr   (FETCH_stall ? `RS2(instrReg) : `RS2(i_instr)),
        .i_regRdAddr    (p_rdAddr[WB]),
        .i_regRdData    (WB_result),
        .o_regRs1Data   (rs1Out),
        .o_regRs2Data   (rs2Out),
        .o_imm          (IMM),
        .o_aluOp        (aluOp),
        .o_exec_a       (exec_a),
        .o_exec_b       (exec_b),
        .o_mem_w        (mem_w),
        .o_reg_w        (reg_w),
        .o_mem2reg      (mem2reg),
        .o_bra          (bra),
        .o_jmp          (jmp)
    );
    Execute #(.XLEN(XLEN)) EXECUTE_unit (
        .i_funct7       (p_funct7[EXEC]),
        .i_funct3       (p_funct3[EXEC]),
        .i_aluOp        (p_aluOp[EXEC]),
        .i_fwdRs1       (fwdRs1),
        .i_fwdRs2       (fwdRs2),
        .i_aluSrcA      (p_exec_a[EXEC]),
        .i_aluSrcB      (p_exec_b[EXEC]),
        .i_EXEC_rs1     (p_rs1[EXEC]),
        .i_EXEC_rs2     (p_rs2[EXEC]),
        .i_MEM_rd       (p_aluOut[MEM]),
        .i_WB_rd        (WB_result),
        .i_PC           (p_PC[EXEC]),
        .i_IMM          (p_IMM[EXEC]),
        .o_aluOut       (aluOut),
        .o_addrGenOut   (jumpAddr),
        .o_rs2FwdOut    (rs2FwdOut)
    );
    Memory #(.XLEN(XLEN)) MEMORY_unit (
        .i_funct3       (p_funct3[MEM]),
        .i_dataIn       (p_rs2[MEM]),
        .o_dataOut      (o_dataOut)
    );
    Writeback #(.XLEN(XLEN)) WRITEBACK_unit (
        .i_funct3       (p_funct3[WB]),
        .i_dataIn       (p_readData[WB]),
        .o_dataOut      (loadData)
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
        p_rs1      [EXEC]  <= EXEC_stall ? p_rs1     [EXEC] : rdFwdRs1En ? WB_result : rs1Out;
        p_rs2      [EXEC]  <= EXEC_stall ? p_rs2     [EXEC] : rdFwdRs2En ? WB_result : rs2Out;
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
