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
    parameter XLEN                  = 32;
    parameter PC_START              = 0;
    parameter INSTR_WIDTH           = 32; // 16 for RV32C (otherwise 32)
    parameter ICACHE_LATENCY        = 0;  // 0 cc: LUT cache, 1 cc: BRAM cache
    parameter REGFILE_ADDR_WIDTH    = 5;  // 4 for RV32E (otherwise 5)

    // Helper Aliases
    localparam REG_0    `VP= 5'b00000; // Register x0
    localparam EBREAK   `VP= 20;
    localparam NOP      `VP= 32'h13;
    localparam S_B_OP   `VP= 3'b000;
    localparam S_H_OP   `VP= 3'b001;
    localparam S_W_OP   `VP= 3'b010;
    localparam S_BU_OP  `VP= 3'b100;
    localparam S_HU_OP  `VP= 3'b101;
    localparam L_B_OP   `VP= 3'b000;
    localparam L_H_OP   `VP= 3'b001;
    localparam L_W_OP   `VP= 3'b010;
    localparam L_BU_OP  `VP= 3'b100;
    localparam L_HU_OP  `VP= 3'b101;

    // Pipeline regs (p_*)
    localparam  EXEC    `VP= 0;
    localparam  MEM     `VP= 1;
    localparam  WB      `VP= 2;
    reg [XLEN-1:0]  p_rs1       [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_rs2       [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_aluOut    [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_readData  [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_PC        [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_IMM       [EXEC:WB]   `VP;
    reg [XLEN-1:0]  p_jumpAddr  [EXEC:WB]   `VP;
    reg      [6:0]  p_funct7    [EXEC:WB]   `VP;
    reg      [4:0]  p_rs1Addr   [EXEC:WB]   `VP;
    reg      [4:0]  p_rs2Addr   [EXEC:WB]   `VP;
    reg      [4:0]  p_rdAddr    [EXEC:WB]   `VP;
    reg      [4:0]  p_aluOp     [EXEC:WB]   `VP;
    reg      [2:0]  p_funct3    [EXEC:WB]   `VP;
    reg             p_mem_w     [EXEC:WB]   `VP;
    reg             p_reg_w     [EXEC:WB]   `VP;
    reg             p_mem2reg   [EXEC:WB]   `VP;
    reg             p_exec_a    [EXEC:WB]   `VP;
    reg             p_exec_b    [EXEC:WB]   `VP;
    reg             p_bra       [EXEC:WB]   `VP;
    reg             p_jmp       [EXEC:WB]   `VP;
    reg             p_ebreak    [EXEC:WB]   `VP;
    reg             p_jalr      [EXEC:WB]   `VP;

    // Internal regs
    reg  [XLEN-1:0] PC;
    reg  [XLEN-1:0] PCReg                   `VP;
    reg  [XLEN-1:0] instrReg                `VP;
    reg  [XLEN-1:0] loadData                `VP;
    reg  [XLEN-1:0] storeData               `VP;
    // Internal wires
    wire [XLEN-1:0] IMM                     `VP;
    wire [XLEN-1:0] aluOut                  `VP;
    wire [XLEN-1:0] jumpAddr                `VP;
    wire [XLEN-1:0] rs1Out                  `VP;
    wire [XLEN-1:0] rs2Out                  `VP;
    wire [XLEN-1:0] rs1Exec                 `VP;
    wire [XLEN-1:0] rs2Exec                 `VP;
    wire [XLEN-1:0] WB_result               `VP;
    wire [XLEN-1:0] aluSrcA                 `VP;
    wire [XLEN-1:0] aluSrcB                 `VP;
    wire [XLEN-1:0] ctrlTransSrcA           `VP;
    wire [XLEN-1:0] jmpResult               `VP;
    wire     [13:0] ctrlSigs                `VP;
    wire      [4:0] aluOp                   `VP;
    wire            exec_a                  `VP;
    wire            exec_b                  `VP;
    wire            mem_w                   `VP;
    wire            reg_w                   `VP;
    wire            mem2reg                 `VP;
    wire            bra                     `VP;
    wire            jmp                     `VP;
    wire            braOutcome              `VP;
    wire            writeRd                 `VP;
    wire            pcJump                  `VP;
    wire            RS1_fwd_mem             `VP;
    wire            RS1_fwd_wb              `VP;
    wire            RS2_fwd_mem             `VP;
    wire            RS2_fwd_wb              `VP;
    wire            rdFwdRs1En              `VP;
    wire            rdFwdRs2En              `VP;
    wire            load_hazard             `VP;
    wire            load_wait               `VP;
    wire            FETCH_stall             `VP;
    wire            EXEC_stall              `VP;
    wire            MEM_stall               `VP;
    wire            FETCH_flush             `VP;
    wire            EXEC_flush              `VP;
    wire            MEM_flush               `VP;
    wire            WB_flush                `VP;
    wire            ecall                   `VP;
    wire            ebreak                  `VP;
    wire            jalr                    `VP;

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
        p_aluOp     [EXEC]  <= EXEC_flush ? 5'd0 : EXEC_stall ? p_aluOp     [EXEC] : aluOp;
        p_mem_w     [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem_w     [EXEC] : mem_w;
        p_reg_w     [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_reg_w     [EXEC] : writeRd;
        p_mem2reg   [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_mem2reg   [EXEC] : mem2reg;
        p_exec_a    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_a    [EXEC] : exec_a;
        p_exec_b    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_exec_b    [EXEC] : exec_b;
        p_bra       [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_bra       [EXEC] : bra;
        p_jmp       [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_jmp       [EXEC] : jmp;
        p_ebreak    [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_ebreak    [EXEC] : ebreak;
        p_jalr      [EXEC]  <= EXEC_flush ? 1'd0 : EXEC_stall ? p_jalr      [EXEC] : jalr;
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
            reg [XLEN-1:0]  PC2              `VP;
            reg             FETCH_flush2     `VP;
            wire            FETCH_flush_line `VP;
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
    ControlUnit CTRL_unit (
        .i_opcode   (`OPCODE_RV32(instrReg)),
        .i_funct3   (`FUNCT3(instrReg)),
        .i_funct7   (`FUNCT7(instrReg)),
        .o_ctrlSigs (ctrlSigs)
    );
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
    assign ebreak   = `CTRL_EBREAK(ctrlSigs) || (ecall & instrReg[EBREAK]);
    assign jalr     = `OP_MAP_JALR == `OPCODE_RV32(instrReg);

    // --- [Stage]: Execute ---
    // ALU
    assign aluSrcA  = (p_exec_a[EXEC] == `PC)   ? p_PC[EXEC]  : rs1Exec;
    assign aluSrcB  = (p_exec_b[EXEC] == `IMM)  ? p_IMM[EXEC] : rs2Exec;
    ALU #(.XLEN(XLEN)) alu_unit (
        .i_a      (aluSrcA),
        .i_b      (aluSrcB),
        .i_op     (p_aluOp[EXEC]),
        .o_result (aluOut)
    );
    // Generate jump address
    assign ctrlTransSrcA    = p_jalr[EXEC] ? rs1Exec : p_PC[EXEC];
    assign jmpResult        = ctrlTransSrcA + p_IMM[EXEC];
    assign jumpAddr         = p_jalr[EXEC] ? {jmpResult[XLEN-1:1],1'b0} : jmpResult;

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
