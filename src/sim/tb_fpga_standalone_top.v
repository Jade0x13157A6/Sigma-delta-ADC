`timescale 1ns/1ps

module fpga_standalone_top_tb;

    reg clk;
    reg arstn;

    wire [1:0] gpio_o;
    wire phone_l;
    wire phone_r;

    // ---------------------------------------------------------
    // Instantiate DUT
    // ---------------------------------------------------------
    fpga_standalone_top dut (
        .clk(clk),
        .arstn(arstn),
        .gpio_o(gpio_o),
        .phone_l(phone_l),
        .phone_r(phone_r)
    );

    // ---------------------------------------------------------
    // Clock generation (100 MHz)
    // ---------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // 10ns period → 100MHz

    // ---------------------------------------------------------
    // Reset sequence
    // ---------------------------------------------------------
    initial begin
        arstn = 0;         // assert reset (rst=1)
        #100;              // hold reset for 100ns
        arstn = 1;         // release reset (rst=0)
    end

    // ---------------------------------------------------------
    // Simulation duration
    // ---------------------------------------------------------
    initial begin
        #200000;           // run for 200us
        $stop;
    end

endmodule
