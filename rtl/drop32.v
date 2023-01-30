// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module drop32 (
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
    parameter         ICACHE_LATENCY        /*verilator public*/ = 0;  // 0 cc: LUT cache, 1 cc: BRAM cache

    // Helper Aliases
    localparam   [4:0]  REG_0               /*verilator public*/ = 5'b00000; // Register x0
    localparam  [31:0]  NOP                 /*verilator public*/ = 32'h13;
    localparam          S_B_OP              /*verilator public*/ = 3'b000;
    localparam          S_H_OP              /*verilator public*/ = 3'b001;
    localparam          S_W_OP              /*verilator public*/ = 3'b010;
    localparam          S_BU_OP             /*verilator public*/ = 3'b100;
    localparam          S_HU_OP             /*verilator public*/ = 3'b101;
    localparam          L_B_OP              /*verilator public*/ = 3'b000;
    localparam          L_H_OP              /*verilator public*/ = 3'b001;
    localparam          L_W_OP              /*verilator public*/ = 3'b010;
    localparam          L_BU_OP             /*verilator public*/ = 3'b100;
    localparam          L_HU_OP             /*verilator public*/ = 3'b101;

    // Pipeline regs (p_*)
    localparam  EXEC    /*verilator public*/ = 0;
    localparam  MEM     /*verilator public*/ = 2;
    localparam  WB      /*verilator public*/ = 3;
    reg [XLEN-1:0]  p_rs1       [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_rs2       [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_aluOut    [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_readData  [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_PC        [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_IMM       [EXEC:WB] /*verilator public*/;
    reg [XLEN-1:0]  p_jumpAddr  [EXEC:WB] /*verilator public*/;
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
    reg             p_ebreak    [EXEC:WB] /*verilator public*/;

    // Internal regs
    reg  [XLEN-1:0] PC              /*verilator public*/;
    reg  [XLEN-1:0] PCReg           /*verilator public*/;
    reg  [XLEN-1:0] instrReg        /*verilator public*/;
    reg  [XLEN-1:0] loadData        /*verilator public*/;
    reg  [XLEN-1:0] storeData       /*verilator public*/;

    // Internal wires
    wire [XLEN-1:0] IMM             /*verilator public*/;
    wire [XLEN-1:0] aluOut          /*verilator public*/;
    wire [XLEN-1:0] jumpAddr        /*verilator public*/;
    wire [XLEN-1:0] rs1Out          /*verilator public*/;
    wire [XLEN-1:0] rs2Out          /*verilator public*/;
    wire [XLEN-1:0] rs1Exec         /*verilator public*/;
    wire [XLEN-1:0] rs2Exec         /*verilator public*/;
    wire [XLEN-1:0] ctrlSigs        /*verilator public*/;
    wire [XLEN-1:0] WB_result       /*verilator public*/;
    wire [XLEN-1:0] aluSrcA         /*verilator public*/;
    wire [XLEN-1:0] aluSrcB         /*verilator public*/;
    wire [XLEN-1:0] ctrlTransSrcA   /*verilator public*/;
    wire [XLEN-1:0] jmpResult       /*verilator public*/;
    wire      [4:0] aluControl      /*verilator public*/;
    wire      [3:0] aluOp           /*verilator public*/;
    wire            indirJump       /*verilator public*/;
    wire            exec_a          /*verilator public*/;
    wire            exec_b          /*verilator public*/;
    wire            mem_w           /*verilator public*/;
    wire            reg_w           /*verilator public*/;
    wire            mem2reg         /*verilator public*/;
    wire            bra             /*verilator public*/;
    wire            jmp             /*verilator public*/;
    wire            braOutcome      /*verilator public*/;
    wire            writeRd         /*verilator public*/;
    wire            pcJump          /*verilator public*/;
    wire            RS1_fwd_mem     /*verilator public*/;
    wire            RS1_fwd_wb      /*verilator public*/;
    wire            RS2_fwd_mem     /*verilator public*/;
    wire            RS2_fwd_wb      /*verilator public*/;
    wire            rdFwdRs1En      /*verilator public*/;
    wire            rdFwdRs2En      /*verilator public*/;
    wire            load_hazard     /*verilator public*/;
    wire            load_wait       /*verilator public*/;
    wire            FETCH_stall     /*verilator public*/;
    wire            EXEC_stall      /*verilator public*/;
    wire            MEM_stall       /*verilator public*/;
    wire            FETCH_flush     /*verilator public*/;
    wire            EXEC_flush      /*verilator public*/;
    wire            MEM_flush       /*verilator public*/;
    wire            WB_flush        /*verilator public*/;
    wire            ecall           /*verilator public*/;
    wire            ebreak          /*verilator public*/;

    // Control signals
    assign aluOp    = `CTRL_ALU_OP(ctrlSigs);
    assign exec_a   = `CTRL_EXEC_A(ctrlSigs);
    assign exec_b   = `CTRL_EXEC_B(ctrlSigs);
    assign mem_w    = `CTRL_MEM_W(ctrlSigs);
    assign reg_w    = `CTRL_REG_W(ctrlSigs);
    assign mem2reg  = `CTRL_MEM2REG(ctrlSigs);
    assign bra      = `CTRL_BRA(ctrlSigs);
    assign jmp      = `CTRL_JMP(ctrlSigs);
    assign ecall    = `CTRL_ECALL(ctrlSigs);
    assign ebreak   = `CTRL_EBREAK(ctrlSigs);

    // Branch/jump logic
    assign pcJump       = braOutcome || p_jmp[MEM];
    assign braOutcome   = p_bra[MEM] && p_aluOut[MEM][0]; // [Static predictor]: Assume branch not-taken

    // Writeback select and enable logic
    assign WB_result    = p_mem2reg[WB] ? p_readData[WB] : p_aluOut[WB];
    assign writeRd      = `RD(instrReg) != REG_0 ? reg_w : 1'b0; // Skip regfile write for x0

    // Forwarding logic
    assign RS1_fwd_mem  = p_reg_w[MEM] && (p_rs1Addr[EXEC] == p_rdAddr[MEM]);
    assign RS1_fwd_wb   = ~RS1_fwd_mem && p_reg_w[WB] && (p_rs1Addr[EXEC] == p_rdAddr[WB]);
    assign RS2_fwd_mem  = p_reg_w[MEM] && (p_rs2Addr[EXEC] == p_rdAddr[MEM]);
    assign RS2_fwd_wb   = ~RS2_fwd_mem && p_reg_w[WB] && (p_rs2Addr[EXEC] == p_rdAddr[WB]);
    assign rs1Exec      = RS1_fwd_wb    ?   WB_result       :
                          RS1_fwd_mem   ?   p_aluOut[MEM]   :
                                            p_rs1[EXEC]     ;
    assign rs2Exec      = RS2_fwd_wb    ?   WB_result       :
                          RS2_fwd_mem   ?   p_aluOut[MEM]   :
                                            p_rs2[EXEC]     ;
    assign rdFwdRs1En   = p_reg_w[WB] && (`RS1(instrReg) == p_rdAddr[WB]); // Bogus read if true, fwd RD[WB]
    assign rdFwdRs2En   = p_reg_w[WB] && (`RS2(instrReg) == p_rdAddr[WB]); // Bogus read if true, fwd RD[WB]

    // Stall and flush logic
    assign load_hazard  = p_mem2reg[EXEC] && ((`RS1(instrReg) == p_rdAddr[EXEC]) || (`RS2(instrReg) == p_rdAddr[EXEC]));
    assign load_wait    = o_loadReq && ~i_memValid;
    assign FETCH_stall  = ~i_ifValid || EXEC_stall || MEM_stall || load_hazard;
    assign EXEC_stall   = MEM_stall;
    assign MEM_stall    = load_wait;
    assign FETCH_flush  = i_rst || ~i_ifValid || braOutcome || p_jmp[MEM];
    assign EXEC_flush   = i_rst || braOutcome || p_jmp[MEM] || load_hazard /* bubble */;
    assign MEM_flush    = i_rst || braOutcome || p_jmp[MEM];
    assign WB_flush     = i_rst || load_wait /* bubble */;

    // Pipeline CTRL reg assignments
    always @(posedge i_clk) begin
        // Execute
        p_aluOp     [EXEC]  <= EXEC_flush ? 4'd0 : EXEC_stall ? p_aluOp     [EXEC] : aluOp;
        p_mem_w     [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem_w     [EXEC] : mem_w;
        p_reg_w     [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_reg_w     [EXEC] : writeRd;
        p_mem2reg   [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem2reg   [EXEC] : mem2reg;
        p_exec_a    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_a    [EXEC] : exec_a;
        p_exec_b    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_b    [EXEC] : exec_b;
        p_bra       [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_bra       [EXEC] : bra;
        p_jmp       [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_jmp       [EXEC] : jmp;
        p_ebreak    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_ebreak    [EXEC] : ebreak;
        // Memory
        p_mem_w     [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_mem_w   [MEM] : p_mem_w     [EXEC];
        p_reg_w     [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_reg_w   [MEM] : p_reg_w     [EXEC];
        p_mem2reg   [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_mem2reg [MEM] : p_mem2reg   [EXEC];
        p_bra       [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_bra     [MEM] : p_bra       [EXEC];
        p_jmp       [MEM]   <= MEM_flush ? 1'd0 : MEM_stall ? p_jmp     [MEM] : p_jmp       [EXEC];
        // Writeback
        p_reg_w     [WB]    <= WB_flush ? 1'd0 : p_reg_w    [MEM];
        p_mem2reg   [WB]    <= WB_flush ? 1'd0 : p_mem2reg  [MEM];
    end

    // Pipeline DATA reg assignments
    always @(posedge i_clk) begin
        // Execute
        p_rs1       [EXEC]  <= EXEC_stall ? p_rs1       [EXEC] : rdFwdRs1En ? WB_result : rs1Out;
        p_rs2       [EXEC]  <= EXEC_stall ? p_rs2       [EXEC] : rdFwdRs2En ? WB_result : rs2Out;
        p_IMM       [EXEC]  <= EXEC_stall ? p_IMM       [EXEC] : IMM;
        p_PC        [EXEC]  <= EXEC_stall ? p_PC        [EXEC] : PCReg;
        p_funct7    [EXEC]  <= EXEC_stall ? p_funct7    [EXEC] : `FUNCT7(instrReg);
        p_funct3    [EXEC]  <= EXEC_stall ? p_funct3    [EXEC] : `FUNCT3(instrReg);
        p_rs1Addr   [EXEC]  <= EXEC_stall ? p_rs1Addr   [EXEC] : `RS1(instrReg);
        p_rs2Addr   [EXEC]  <= EXEC_stall ? p_rs2Addr   [EXEC] : `RS2(instrReg);
        p_rdAddr    [EXEC]  <= EXEC_stall ? p_rdAddr    [EXEC] : `RD(instrReg);
        // Memory
        p_rs2       [MEM]   <= MEM_stall  ? p_rs2       [MEM] : rs2Exec;
        p_rdAddr    [MEM]   <= MEM_stall  ? p_rdAddr    [MEM] : p_rdAddr  [EXEC];
        p_funct3    [MEM]   <= MEM_stall  ? p_funct3    [MEM] : p_funct3  [EXEC];
        p_aluOut    [MEM]   <= MEM_stall  ? p_aluOut    [MEM] : aluOut;
        p_jumpAddr  [MEM]   <= MEM_stall  ? p_jumpAddr  [MEM] : jumpAddr;
        // Writeback
        p_aluOut    [WB]    <= p_aluOut [MEM];
        p_rdAddr    [WB]    <= p_rdAddr [MEM];
        p_funct3    [WB]    <= p_funct3 [MEM];
        p_readData  [WB]    <= loadData;
    end

    // --- [Stage]: Fetch/Decode ---
    always @(posedge i_clk) begin
        PC          <=  i_rst       ?   PC_START        :
                        pcJump      ?   p_jumpAddr[MEM] :
                        FETCH_stall ?   PC              :
                                        PC + 32'd4      ;
    end
    generate
        if (ICACHE_LATENCY == 1) begin // BRAM-based I$
            reg [XLEN-1:0]  PC2                 /*verilator public*/;
            reg             FETCH_flush2        /*verilator public*/;
            wire            FETCH_flush_line    /*verilator public*/;
            assign          FETCH_flush_line = FETCH_flush || FETCH_flush2;
            always @(posedge i_clk) begin
                // Hold fetch-flush line for 1cc extra
                FETCH_flush2    <= FETCH_flush;
                // Buffer PC reg to balance the 1cc BRAM-based I$ read
                PC2             <=  i_rst               ?   0           :
                                    FETCH_stall         ?   PC2         :
                                                            PC          ;
                // Buffer instruction fetch to balance the 1cc BRAM-based regfile read
                instrReg        <=  FETCH_flush_line    ?   NOP         :
                                    FETCH_stall         ?   instrReg    :
                                                            i_instr     ;
                // Buffer PC reg to balance the 1cc BRAM-based regfile read
                PCReg           <=  FETCH_flush_line    ?   0           :
                                    FETCH_stall         ?   PCReg       :
                                                            PC2         ;
            end
        end else begin // LUT-based I$
            always @(posedge i_clk) begin
                // Buffer instruction fetch to balance the 1cc BRAM-based regfile read
                instrReg    <=  FETCH_flush ?   NOP         :
                                FETCH_stall ?   instrReg    :
                                                i_instr     ;
                // Buffer PC reg to balance the 1cc BRAM-based regfile read
                PCReg       <=  FETCH_flush ?   0           :
                                FETCH_stall ?   PCReg       :
                                                PC          ;
            end
        end
    endgenerate
    ImmGen #(.XLEN(XLEN)) IMMGEN_unit (
        .i_instr    (instrReg),
        .o_imm      (IMM)
    );
    ControlUnit #(.XLEN(XLEN)) CTRL_unit (
        .i_instr    (instrReg),
        .o_ctrlSigs (ctrlSigs)
    );
    Regfile #(
        .XLEN       (XLEN),
        .ADDR_WIDTH (REGFILE_ADDR_WIDTH)
    ) REGFILE_unit (
        .i_clk      (i_clk),
        .i_wrEn     (p_reg_w[WB]),
        .i_rs1Addr  (FETCH_stall ? `RS1(instrReg) : `RS1(i_instr)),
        .i_rs2Addr  (FETCH_stall ? `RS2(instrReg) : `RS2(i_instr)),
        .i_rdAddr   (p_rdAddr[WB]),
        .i_rdData   (WB_result),
        .o_rs1Data  (rs1Out),
        .o_rs2Data  (rs2Out)
    );

    // --- [Stage]: Execute ---
    // ALU input selects
    assign aluSrcA  = (p_exec_a[EXEC] == `PC)   ? p_PC[EXEC]  : rs1Exec;
    assign aluSrcB  = (p_exec_b[EXEC] == `IMM)  ? p_IMM[EXEC] : rs2Exec;

    // ALU/ALU_Control
    ALU_Control ALU_CTRL_unit (
        .i_aluOp        (p_aluOp[EXEC]),
        .i_funct7       (p_funct7[EXEC]),
        .i_funct3       (p_funct3[EXEC]),
        .o_aluControl   (aluControl)
    );
    ALU #(.XLEN(XLEN)) alu_unit (
        .i_a      (aluSrcA),
        .i_b      (aluSrcB),
        .i_op     (aluControl),
        .o_result (aluOut)
    );

    // Generate jump address
    assign indirJump        = `ALU_OP_I_JUMP == p_aluOp[EXEC]; // (i.e. JALR)
    assign ctrlTransSrcA    = indirJump ? rs1Exec : p_PC[EXEC];
    assign jmpResult        = ctrlTransSrcA + p_IMM[EXEC];
    assign jumpAddr         = indirJump ? {jmpResult[XLEN-1:1],1'b0} : jmpResult;

    // --- [Stage]: Memory ---
    always @(*) begin
        case (p_funct3[MEM])
            S_B_OP  : storeData = {24'd0, p_rs2[MEM][7:0]};
            S_H_OP  : storeData = {16'd0, p_rs2[MEM][15:0]};
            S_W_OP  : storeData = p_rs2[MEM];
            S_BU_OP : storeData = {24'd0, p_rs2[MEM][7:0]};
            S_HU_OP : storeData = {16'd0, p_rs2[MEM][15:0]};
            default : storeData = p_rs2[MEM];
        endcase
    end

    // --- [Stage]: Writeback ---
    always @(*) begin
        case (p_funct3[MEM])
            L_B_OP  : loadData = {{24{i_dataIn[7]}},   i_dataIn[7:0]};
            L_H_OP  : loadData = {{16{i_dataIn[15]}},  i_dataIn[15:0]};
            L_W_OP  : loadData = i_dataIn;
            L_BU_OP : loadData = {24'd0, i_dataIn[7:0]};
            L_HU_OP : loadData = {16'd0, i_dataIn[15:0]};
            default : loadData = i_dataIn;
        endcase
    end

    // CPU outputs
    assign o_pcOut      = PC;
    assign o_dataAddr   = p_aluOut[MEM];
    assign o_storeReq   = p_mem_w[MEM];
    assign o_loadReq    = p_mem2reg[MEM];
    assign o_dataOut    = storeData;

endmodule
