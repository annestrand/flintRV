// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

module uart_transmitter (
    input         clk,
    input         tx_start,
    input   [7:0] tx_byte,
    output        tx,
    output        tx_done
);
    parameter   F_CLK           = 1_000_000;                // Default Clk frequency
    parameter   BAUDRATE        = 9600;                     // Default symbols/sec
    localparam  SAMPLE_PERIOD   = F_CLK / (16 * BAUDRATE);  // 16x sample-rate
    localparam  [1:0]
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg         tx_reg;           // Define rx reg to connect to the output
    reg         tx_done_buffer;   // Define "done" flag for a sucessful byte transmission
    reg [1:0]   state;            // State machine reg
    reg [3:0]   tx_byte_counter;  // Count number of recieved bits and stop at 1 byte (i.e. 8)
    reg [7:0]   tx_byte_buffer;   // Reg that holds the recieved uart byte
    reg [31:0]  sample_counter;   // Counter used to sample in the middle of a uart bit

`ifdef SIM
    initial begin
        state           = IDLE;
        tx_reg          = 1'b1;
        tx_byte_buffer  = 8'd0;
        sample_counter  = 32'd0;
        tx_done_buffer  = 1'b1;
        tx_byte_counter = 4'd0;
        $display("--- UART config: ---");
        $display("    F_CLK( %0d )\n    BAUDRATE( %0d )\n    SAMPLE_PERIOD( %0d )\n", F_CLK, BAUDRATE, SAMPLE_PERIOD);
    end
`endif // SIM

    assign tx       = tx_reg;
    assign tx_done  = tx_done_buffer;

    // Transmitter FSM
    always@(posedge clk) begin
        case (state)
        IDLE: begin // ------------------------------------------------------------------------------------------------
            if (tx_start) begin
                state           <= START;
                tx_byte_buffer  <= tx_byte;
                tx_done_buffer  <= 1'b0;
                tx_reg          <= 1'b0; // Start-bit
            end else begin
                tx_byte_buffer  <= 8'd0;
                sample_counter  <= 32'd0;
                tx_byte_counter <= 4'd0;
                tx_done_buffer  <= 1'b1;
                tx_reg          <= 1'b1;
            end
        end
        START: begin // -----------------------------------------------------------------------------------------------
            if (sample_counter == SAMPLE_PERIOD) begin
                state           <= DATA;
                sample_counter  <= 32'd0;
                tx_byte_counter <= 4'd0;
                tx_reg          <= tx_byte_buffer[0];
            end else begin
                sample_counter  <= sample_counter + 1;
            end
        end
        DATA: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == SAMPLE_PERIOD) begin
                if (tx_byte_counter == 8) begin
                    state           <= STOP;
                    tx_byte_counter <= 4'd0;
                    tx_reg          <= 1'b1; // Stop-bit
                    sample_counter  <= 32'd0;
                end else begin
                    tx_byte_buffer  <= tx_byte_buffer >> 1;
                    tx_byte_counter <= tx_byte_counter + 1;
                    sample_counter  <= 32'd0;
                end
            end else begin
                tx_reg          <= tx_byte_buffer[0];
                sample_counter  <= sample_counter + 1;
            end
        end
        STOP: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == SAMPLE_PERIOD) begin
                state           <= IDLE;
                sample_counter  <= 32'd0;
                tx_done_buffer  <= 1'b1;
            end else begin
                sample_counter  <= sample_counter + 1;
            end
        end
        endcase
    end
endmodule
