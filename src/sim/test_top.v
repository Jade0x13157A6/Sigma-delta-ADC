`timescale 1ns / 1ps

module sd_test_top #(
    parameter OSR_BITS   = 8,
    parameter ADC_WIDTH  = 16
)(
    input  wire clk,        // System Clock
    input  wire rstn,       // Reset (active low)

    output wire led,        // Status LED
    output wire dac_out,    // 1-bit DAC (Debug)

    output wire led_clk,    // Clock alive LED
    output wire led_comp,   // Comparator LED
    output wire gpio_comp,  // Comparator GPIO
    output wire gpio_clk,    // Clock GPIO
    output wire gpio_rstn
);

    // ==================================================
    // Reset synchronisiert (wichtig!)
    // ==================================================
    reg [1:0] rst_sync;
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            rst_sync <= 2'b00;
        else
            rst_sync <= 2'b11;
    end
    wire rst = rst_sync[1];
   // assign gpio_rstn = rstn;

    // ==================================================
    // Clock Debug
    // ==================================================
    assign gpio_clk = clk;   // direkt Clock raus
    assign led_clk  = clk_div[25];  // Blink-LED

    reg [25:0] clk_div;
    always @(posedge clk) begin
        if(!rst)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end

    // ==================================================
    // Testsignal (virtueller Analogwert)
    // ==================================================
    reg [15:0] test_cnt;
    always @(posedge clk) begin
        if(!rst)
            test_cnt <= 16'd0;
        else
            test_cnt <= test_cnt + 1;
    end

    // Comparator-Testsignal
    wire cmp_test = test_cnt[15];   // MSB = langsames Rechteck

    // ==================================================
    // Sigma-Delta Modulator
    // ==================================================
    wire signed [1:0] bitstream;

    sd_modulator_1 u_mod (
        .clk(clk),
        .rstn(rst),
        .cmp_in(cmp_test),
        .dac_out(dac_out),
        .bitstream(bitstream)
    );

    // ==================================================
    // CIC / Sinc3 Decimator
    // ==================================================
    wire signed [ADC_WIDTH-1:0] adc_data;
    wire adc_valid;

    cic_decimator #(
        .OSR_BITS(OSR_BITS),
        .ADC_WIDTH(ADC_WIDTH)
    ) u_cic (
        .clk(clk),
        .rstn(rst),
        .data_in(bitstream),
        .data_out(adc_data),
        .out_valid(adc_valid)
    );

    // ==================================================
    // Debug LEDs / GPIOs
    // ==================================================

    // Comparator sichtbar machen
    //assign led_comp  = cmp_test;
    assign gpio_comp = cmp_test;

    // ADC valid LED (toggle)
    reg led_r;
    always @(posedge clk) begin
        if(!rst)
            led_r <= 1'b0;
        else if(adc_valid)
            led_r <= ~led_r;
    end
    //assign led = led_r;
    //assign led_comp = bitstream;
    
    assign gpio_rstn = (adc_data != 0);


endmodule
