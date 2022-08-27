module uart_reciever (
    input         clk,
    input         rx,
    output        rx_done,
    output  [7:0] rx_byte
);
    parameter   F_CLK               = 1_000_000;                // Default Clk frequency
    parameter   BAUDRATE            = 9600;                     // Default symbols/sec
    localparam  SAMPLE_PERIOD       = F_CLK / (16 * BAUDRATE);  // 16x sample-rate
    localparam  HALF_SAMPLE_PERIOD  = SAMPLE_PERIOD / 2;
    localparam  [1:0]
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg         rx_done_buffer;   // Define "done" flag for a sucessful byte reception
    reg [1:0]   state;            // State machine reg
    reg [3:0]   rx_byte_counter;  // Count number of recieved bits and stop at 1 byte (i.e. 8)
    reg [7:0]   rx_byte_buffer;   // Reg that holds the recieved uart byte
    reg [31:0]  sample_counter;   // Counter used to sample in the middle of a uart bit

`ifdef SIM
    initial begin
        state           = IDLE;
        rx_byte_buffer  = 8'd0;
        sample_counter  = 32'd0;
        rx_done_buffer  = 1'b1;
        rx_byte_counter = 4'd0;
        $display("--- UART config: ---");
        $display("    F_CLK( %0d )\n    BAUDRATE( %0d )\n    SAMPLE_PERIOD( %0d )\n    HALF_SAMPLE_PERIOD( %0d )\n",
            F_CLK, BAUDRATE, SAMPLE_PERIOD, HALF_SAMPLE_PERIOD
        );
    end
`endif // SIM

    assign rx_done = rx_done_buffer;
    assign rx_byte = rx_byte_buffer;

    // Reciever FSM
    always@(posedge clk) begin
        case (state)
        IDLE: begin // ------------------------------------------------------------------------------------------------
            if (!rx) begin
                state           <= START;
                rx_done_buffer  <= 1'b0;
            end else begin
                sample_counter  <= 32'd0;
                rx_byte_counter <= 3'd0;
                rx_done_buffer  <= 1'b1;
            end
        end
        START: begin // -----------------------------------------------------------------------------------------------
            if (sample_counter == HALF_SAMPLE_PERIOD) begin
                if (!rx) begin // Check if start-bit is still valid
                    state           <= DATA;
                    sample_counter  <= 32'd0;
                end else begin
                    state           <= IDLE;
                end
            end else begin
                sample_counter <= sample_counter + 1;
            end
        end
        DATA: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == SAMPLE_PERIOD) begin
                if (rx_byte_counter == 8) begin
                    state           <= STOP;
                    rx_byte_counter <= 4'd0;
                    sample_counter  <= 32'd0;
                end else begin
                    rx_byte_buffer  <= {rx, rx_byte_buffer[7:1]}; // Right-shift rx into buffer
                    rx_byte_counter <= rx_byte_counter + 1;
                    sample_counter  <= 32'd0;
                end
            end else begin
                sample_counter  <= sample_counter + 1;
            end
        end
        STOP: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == SAMPLE_PERIOD) begin
                state           <= IDLE;
                sample_counter  <= 32'd0;
                rx_byte_counter <= 4'd0;
                rx_done_buffer  <= 1'b1;
            end else begin
                sample_counter  <= sample_counter + 1;
            end
        end
        endcase
    end
endmodule
