`include "pinacolada_uart.v"

module uart_transmitter_tb;
    reg clk;
    reg tx_start;
    reg [7:0] tx_byte;
    wire tx;
    wire tx_done;

    uart_transmitter uart_transmitter_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("./build/pinacolada/pc_uart_tx.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    integer i;
    initial begin
        clk = 0;
        tx_start = 0;
        tx_byte = 65;
        for (i = 0; i < 10500; i = i + 1)
        begin
            if (i == 500)
                tx_start = 1;
            else
                tx_start = 0;

            clk = ~clk;
            #100;
        end
    end
endmodule