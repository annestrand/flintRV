`include "uart_rx.v"

module uart_reciever_tb;
    reg clk = 0;
    reg rx  = 1;
    wire rx_done;
    wire [7:0] rx_byte;

    uart_reciever uart_reciever_dut(.*);
    localparam F_CLK                    = 10_000_000;
    localparam BAUDRATE                 = 9600;
    localparam SAMPLE_PERIOD            = F_CLK / (16 * BAUDRATE) + 1;
    defparam uart_reciever_dut.F_CLK    = F_CLK;
    defparam uart_reciever_dut.BAUDRATE = BAUDRATE;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("./obj_dir/sub/pinacolada/uart_rx.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    integer         i                       = 0;
    reg             started                 = 0;
    reg [31:0]      counter                 = 0;
    reg [3:0]       byte_counter            = 0;
    reg [7:0]       test_char               = 0;
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
            for (i=0; i<BAUDRATE; i=i+1) begin
                if (i == 100) begin
                    rx = 0;
                end
                if (!rx_done) begin
                    counter = counter + 1;
                    started = 1;
                end else begin
                    counter = 0;
                end
                if (counter > 0 && counter == SAMPLE_PERIOD) begin
                    rx              = ascii_char[0];
                    counter         = 0;
                    ascii_char      = ascii_char >> 1;
                    byte_counter    = byte_counter + 1;
                end
                if (byte_counter == 9) begin
                    rx              = 1;
                    counter         = 0;
                    byte_counter    = 0;
                end
                if (rx_done && started) begin
                    i   = BAUDRATE; // We are done, gross early exit...
                    rx  = 1;
                end
                clk = ~clk; #20; clk = ~clk; #20;
            end
        end
    endtask

    integer x;
    initial begin
        $display("Running uart_reciever test...\n"); #20;
        for (x=0; x<12; x=x+1) begin
            test_char               = test_gold_vector_cpy[12*8-1:11*8];
            uartLoop(test_char);
            test_gold_vector_cpy    = {test_gold_vector_cpy[11*8-1:0], 8'd0};
            test_vector             = {test_vector, rx_byte};
            $display("[test_vector]: %s", test_vector);
        end
        if (test_vector != test_gold_vector)    $display("\nFAILED!");
        else                                    $display("\nPASSED!");
    end
endmodule
