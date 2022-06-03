`include "pinacolada_uart.v"

module uart_reciever_tb;
    reg clk;
    reg rx;
    wire rx_done;
    wire [7:0] rx_byte;

    uart_reciever uart_reciever_dut(.*);

`ifdef DUMP_VCD
    initial begin
        $dumpfile("../build/pinacolada/pc_uart_rx.vcd");
        $dumpvars;
    end
`endif // DUMP_VCD

    integer i;
    initial begin
        clk = 0;
        rx = 1;
        for (i = 'd0; i < 10000; i = i + 1)
        begin
            if (i == 4)
                rx = 0;
            else if (i >= 5690)
                rx = 1;

            clk = ~clk;
            #100;
        end
    end
endmodule