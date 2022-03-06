module decoder(
    input clk, input [16:0]inAddr, 
    output reg [7:0]decoderOut
)
    reg [7:0]ucode[0:39];
    wire[11:0]ucodeAddr;
    always@* begin
        case({[15:15]inAddr,[10:0]inAddr})
        /* LB       */ 12'b000000000011 : ucodeAddr = 'd0;     // ucode[   0]: 00000001
        /* FENCE    */ 12'b000000001111 : ucodeAddr = 'd1;     // ucode[   1]: 00000000
        /* ADDI     */ 12'b000000010011 : ucodeAddr = 'd2;     // ucode[   2]: 00000001
        /* AUIPC    */ 12'b000000010111 : ucodeAddr = 'd3;     // ucode[   3]: 00000101
        /* SB       */ 12'b000000100011 : ucodeAddr = 'd4;     // ucode[   4]: 00000001
        /* ADD      */ 12'b000000110011 : ucodeAddr = 'd5;     // ucode[   5]: 00000000
        /* LUI      */ 12'b000000110111 : ucodeAddr = 'd6;     // ucode[   6]: 11100101
        /* BEQ      */ 12'b000001100011 : ucodeAddr = 'd7;     // ucode[   7]: 00000001
        /* JALR     */ 12'b000001100111 : ucodeAddr = 'd8;     // ucode[   8]: 00000001
        /* JAL      */ 12'b000001101111 : ucodeAddr = 'd9;     // ucode[   9]: 00000001
        /* ECALL    */ 12'b000001110011 : ucodeAddr = 'd10;    // ucode[  10]: 00000001
        /* LH       */ 12'b000010000011 : ucodeAddr = 'd11;    // ucode[  11]: 00000001
        /* SLLI     */ 12'b000010010011 : ucodeAddr = 'd12;    // ucode[  12]: 01010001
        /* SH       */ 12'b000010100011 : ucodeAddr = 'd13;    // ucode[  13]: 00000001
        /* SLL      */ 12'b000010110011 : ucodeAddr = 'd14;    // ucode[  14]: 01010000
        /* BNE      */ 12'b000011100011 : ucodeAddr = 'd15;    // ucode[  15]: 00000001
        /* LW       */ 12'b000100000011 : ucodeAddr = 'd16;    // ucode[  16]: 00000001
        /* SLTI     */ 12'b000100010011 : ucodeAddr = 'd17;    // ucode[  17]: 00000001
        /* SW       */ 12'b000100100011 : ucodeAddr = 'd18;    // ucode[  18]: 00000001
        /* SLT      */ 12'b000100110011 : ucodeAddr = 'd19;    // ucode[  19]: 00000001
        /* SLTIU    */ 12'b000110010011 : ucodeAddr = 'd20;    // ucode[  20]: 00000001
        /* SLTU     */ 12'b000110110011 : ucodeAddr = 'd21;    // ucode[  21]: 00000001
        /* LBU      */ 12'b001000000011 : ucodeAddr = 'd22;    // ucode[  22]: 00000001
        /* XORI     */ 12'b001000010011 : ucodeAddr = 'd23;    // ucode[  23]: 01000001
        /* XOR      */ 12'b001000110011 : ucodeAddr = 'd24;    // ucode[  24]: 01000000
        /* BLT      */ 12'b001001100011 : ucodeAddr = 'd25;    // ucode[  25]: 00000001
        /* LHU      */ 12'b001010000011 : ucodeAddr = 'd26;    // ucode[  26]: 00000001
        /* SRLI     */ 12'b001010010011 : ucodeAddr = 'd27;    // ucode[  27]: 01100001
        /* SRL      */ 12'b001010110011 : ucodeAddr = 'd28;    // ucode[  28]: 01100000
        /* BGE      */ 12'b001011100011 : ucodeAddr = 'd29;    // ucode[  29]: 00000001
        /* ORI      */ 12'b001100010011 : ucodeAddr = 'd30;    // ucode[  30]: 00110001
        /* OR       */ 12'b001100110011 : ucodeAddr = 'd31;    // ucode[  31]: 00110000
        /* BLTU     */ 12'b001101100011 : ucodeAddr = 'd32;    // ucode[  32]: 00000001
        /* ANDI     */ 12'b001110010011 : ucodeAddr = 'd33;    // ucode[  33]: 00000001
        /* AND      */ 12'b001110110011 : ucodeAddr = 'd34;    // ucode[  34]: 00100000
        /* BGEU     */ 12'b001111100011 : ucodeAddr = 'd35;    // ucode[  35]: 00000001
        /* EBREAK   */ 12'b010001110011 : ucodeAddr = 'd36;    // ucode[  36]: 00000001
        /* SUB      */ 12'b100000110011 : ucodeAddr = 'd37;    // ucode[  37]: 00010000
        /* SRAI     */ 12'b101010010011 : ucodeAddr = 'd38;    // ucode[  38]: 01110001
        /* SRA      */ 12'b101010110011 : ucodeAddr = 'd39;    // ucode[  39]: 01110000
        /* ECALL    */ default          : ucodeAddr = 'd10; 
        endcase
    end
    initial begin
        $readmemb("g_ucode.dat", ucode)
    end
    always@(posedge clk) begin
        decoderOut <= ucode[ucodeAddr]
    end
endmodule
