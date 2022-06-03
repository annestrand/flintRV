// ====================================================================================================================
//
// pinacolada (pc) uart modules
//

module uart_reciever (
    input           clk,
    input           rx,
    output          rx_done,
    output  [7:0]   rx_byte
);
    localparam  [8:0] BAUD_TICK = 9'd435;   // Baud rate of 115200: (50 MHz / 115200) = ~435 clk ticks per uart bit
    localparam  [1:0]                       // Reciever states
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg       rx_done_buffer;   // Define "done" flag for a sucessful byte reception
    reg [1:0] state;            // State machine reg
    reg [2:0] rx_byte_counter;  // Count number of recieved bits and stop at 1 byte (i.e. 8)
    reg [7:0] rx_byte_buffer;   // Reg that holds the recieved uart byte
    reg [8:0] sample_counter;   // Counter used to sample in the middle of a uart bit

`ifdef SIM
    initial begin
        state           = IDLE;
        rx_byte_buffer  = 0;
        sample_counter  = 0;
        rx_done_buffer  = 1;
        rx_byte_counter = 0;
    end
`endif // SIM

    // Assign outputs
    assign rx_done = rx_done_buffer;
    assign rx_byte = rx_byte_buffer;

    // Reciever FSM
    always@(posedge clk) begin
        case (state)
        IDLE: begin // ------------------------------------------------------------------------------------------------
            rx_byte_buffer  <= 0;
            sample_counter  <= 0;
            rx_done_buffer  <= 1;
            rx_byte_counter <= 0;
            if (!rx) begin
                state <= START;
            end
        end
        START: begin // -----------------------------------------------------------------------------------------------
            // Initially offset by half baud tick to sample the middle of a data bit
            if (sample_counter == BAUD_TICK / 2) begin
                if (!rx) begin
                    state           <= DATA;
                    rx_done_buffer  <= 0;
                    sample_counter  <= 0;
                end
                else begin
                    state <= IDLE;
                end
            end else begin
                sample_counter <= sample_counter + 1;
            end
        end
        DATA: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == BAUD_TICK) begin
                // Shift-in input rx into rx byte buffer and increment byte counter
                rx_byte_buffer  <= {rx, rx_byte_buffer[7:1]};
                rx_byte_counter <= rx_byte_counter + 1;
                if (rx_byte_counter == 7) begin
                    state           <= STOP;
                    rx_byte_counter <= 0;
                end
                // Clear sample counter
                sample_counter <= 0;
            end else begin
                sample_counter <= sample_counter + 1;
            end
        end
        STOP: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == BAUD_TICK) begin
                if (rx) begin
                    rx_done_buffer <= 1;
                end
                // Clear sample counter and go back to IDLE state
                sample_counter <= 0;
                state <= IDLE;
            end else begin
                sample_counter <= sample_counter + 1;
            end
        end
        endcase
    end
endmodule

// ====================================================================================================================
module uart_transmitter
(
    input clk,
    input tx_start,
    input [7:0] tx_byte,
    output tx,
    output tx_done
);
    localparam [8:0] BAUD_TICK = 9'd435;    // Baud rate of 115200: (50 MHz / 115200) = ~435 clk ticks per uart bit
    localparam [1:0]                        // Reciever states
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg       tx_reg;           // Define rx reg to connect to the output
    reg       tx_done_buffer;   // Define "done" flag for a sucessful byte transmission
    reg [1:0] state;            // State machine reg
    reg [2:0] tx_byte_counter;  // Count number of recieved bits and stop at 1 byte (i.e. 8)
    reg [7:0] tx_byte_buffer;   // Reg that holds the recieved uart byte
    reg [8:0] sample_counter;   // Counter used to sample in the middle of a uart bit

`ifdef SIM
    initial begin
        state           = IDLE;
        tx_reg          = 1;
        tx_byte_buffer  = 0;
        sample_counter  = 0;
        tx_done_buffer  = 1;
        tx_byte_counter = 0;
    end
`endif // SIM

    // Assign outputs
    assign tx       = tx_reg;
    assign tx_done  = tx_done_buffer;

    // Transmitter FSM
    always@(posedge clk) begin
        case (state)
        IDLE: begin // ------------------------------------------------------------------------------------------------
            tx_byte_buffer  <= 0;
            sample_counter  <= 0;
            tx_done_buffer  <= 1;
            tx_byte_counter <= 0;
            tx_reg          <= 1;
            if (tx_start) begin
                state           <= START;
                tx_byte_buffer  <= tx_byte;
                tx_done_buffer  <= 0;
            end
        end
        START: begin // -----------------------------------------------------------------------------------------------
            // Initially offset by half baud tick to sample the middle of a data bit
            if (sample_counter == BAUD_TICK) begin
                state           <= DATA;
                sample_counter  <= 0;
            end else begin
                sample_counter  <= sample_counter + 1;
            end
            tx_reg <= 0;
        end
        DATA: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == BAUD_TICK) begin
                // Send out one bit from tx_byte_buffer and increment byte counter
                tx_byte_buffer  <= tx_byte_buffer >> 1;
                tx_byte_counter <= tx_byte_counter + 1;
                if (tx_byte_counter == 7) begin
                    state           <= STOP;
                    tx_reg          <= 1;
                    tx_byte_counter <= 0;
                end
                // Clear sample counter
                sample_counter <= 0;
            end else begin
                tx_reg          <= tx_byte_buffer[0];
                sample_counter  <= sample_counter + 1;
            end
        end
        STOP: begin // ------------------------------------------------------------------------------------------------
            if (sample_counter == BAUD_TICK) begin
                // Clear sample counter and go back to IDLE state
                sample_counter  <= 0;
                tx_done_buffer  <= 1;
                state           <= IDLE;
            end else begin
                sample_counter  <= sample_counter + 1;
            end
        end
        endcase
    end
endmodule
