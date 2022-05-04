// ====================================================================================================================
module Memory
(
    input       [2:0]   funct3,
    input       [31:0]  dataIn,
    output reg  [31:0]  dataOut
);
    // Just output store-type (w/ - w/o sign-ext) for now
    always @(*) begin
        case (funct3)
            `LS_B_OP    : dataOut = {{24{dataIn[31]}}, dataIn[7:0]};
            `LS_H_OP    : dataOut = {{16{dataIn[31]}}, dataIn[15:0]};
            `LS_W_OP    : dataOut = dataIn;
            `LS_BU_OP   : dataOut = {24'd0, dataIn[7:0]};
            `LS_HU_OP   : dataOut = {16'd0, dataIn[15:0]};
            default     : dataOut = dataIn;
        endcase
    end
endmodule