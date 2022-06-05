`include "pinacolada_uart_tx.v"

module uart_transmitter_tb;
    reg         clk = 0;
    reg         tx_start = 0;
    reg   [7:0] tx_byte = "-";
    wire        tx;
    wire        tx_done;

    uart_transmitter uart_transmitter_dut(.*);
    localparam F_CLK                        = 10_000_000;
    localparam BAUDRATE                     = 9600;
    localparam SAMPLE_PERIOD                = F_CLK / (16 * BAUDRATE);
    defparam uart_transmitter_dut.F_CLK     = F_CLK;
    defparam uart_transmitter_dut.BAUDRATE  = BAUDRATE;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("./build/pinacolada/pinacolada_uart_tx.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    integer         i                       = 0;
    reg             started                 = 0;
    reg [31:0]      counter                 = 0;
    reg [3:0]       byte_counter            = 0;
    reg [7:0]       test_char               = 0;
    reg [7:0]       test_char_out           = 0;
    reg [12*8-1:0]  test_vector             = "------------";
    reg [12*8-1:0]  test_gold_vector        = "Hello world!";
    reg [12*8-1:0]  test_gold_vector_cpy    = "Hello world!";
    // Helper uart run loop task
    task uartLoop;
        input [7:0]ascii_char;
        begin
            started         = 0;
            counter         = 0;
            byte_counter    = 0;
            tx_byte         = ascii_char;
            for (i=0; i<BAUDRATE; i=i+1) begin
                if (i == 100) begin
                    tx_start    = 1;
                    started     = 1;
                end else begin
                    tx_start    = 0;
                end
                if (started) begin
                    if (counter == SAMPLE_PERIOD) begin
                        if (byte_counter > 0 && byte_counter < 9) begin
                            // We dont need start-stop bits
                            test_char_out = {tx, test_char_out[7:1]};
                        end
                        counter         = 0;
                        byte_counter    = byte_counter + 1;
                    end else begin
                        counter         = counter + 1;
                    end
                end else begin
                    counter = 0;
                end
                if (byte_counter == 9) begin
                    if (tx_done) begin
                        i = BAUDRATE; // We are done, gross early exit...
                    end else begin
                        started = 0;
                    end
                end
                clk = ~clk; #20; clk = ~clk; #20;
            end
        end
    endtask

    integer x = 0;
    initial begin
        $display("Running uart_transmitter test...\n"); #20;
        for (x=0; x<12; x=x+1) begin
            test_char               = test_gold_vector_cpy[12*8-1:11*8];
            uartLoop(test_char);
            test_gold_vector_cpy    = {test_gold_vector_cpy[11*8-1:0], 8'd0};
            test_vector             = {test_vector, test_char_out};
            $display("[test_vector]: %s", test_vector);
        end
        if (test_vector != test_gold_vector)    $display("\nFAILED!");
        else                                    $display("\nPASSED!");
    end
endmodule