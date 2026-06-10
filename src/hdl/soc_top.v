// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
// Description: Top-Level Verilog integrating the PSoC audio IP with neorv32 CPU
module soc_top #(
        parameter [15:0] sysinfo = 16'h1001
    )(
        inout[31:0] pads,
        input  wire ADC_P,
        input  wire ADC_N,
        output wire dac_out
    );

    // system clock
    wire clk, arstn, rst;
    reset_logic reset_logic(
        .clk(clk),
        .arstn(arstn),
        .rst(rst)
    );

    // Wishbone bus for xbar
    wire[31:0] wb_xbar_adr, wb_xbar_dat_i, wb_xbar_dat_o;
    wire wb_xbar_we, wb_xbar_stb, wb_xbar_cyc, wb_xbar_ack;
    wire[3:0] wb_xbar_sel;
    // Wishbone bus for I2S module
    wire[31:0] wb_i2s_adr, wb_i2s_dat_i, wb_i2s_dat_o;
    wire wb_i2s_we, wb_i2s_stb, wb_i2s_cyc, wb_i2s_ack;
    wire[3:0] wb_i2s_sel;
    // Wishbone bus for IO module
    wire[31:0] wb_io_adr, wb_io_dat_i, wb_io_dat_o;
    wire wb_io_we, wb_io_stb, wb_io_cyc, wb_io_ack;
    wire[3:0] wb_io_sel;
    // Wishbone bus for SD module
    wire[31:0] wb_sd_adr, wb_sd_dat_i, wb_sd_dat_o;
    wire wb_sd_we, wb_sd_stb, wb_sd_cyc, wb_sd_ack;
    wire[3:0] wb_sd_sel;
    // Wishbone bus for AUDIO module
    wire[31:0] wb_audio_adr, wb_audio_dat_i, wb_audio_dat_o;
    wire       wb_audio_we, wb_audio_stb, wb_audio_cyc, wb_audio_ack;
    wire[3:0]  wb_audio_sel; 

    // Audio module interrupt line
    wire audio_fifo_low;
    // GPIO Signals
    wire[31:0] gpio_i, gpio_o;
    // I2S signals
    wire i2s_mclk, i2s_sdata, i2s_sclk, i2s_lrclk;
    // Delta-Sigma Outputs
    wire audio_l, audio_r;
    // i2c signals
    wire i2c_sda_i, i2c_sda_o, i2c_scl_i, i2c_scl_o;
    // UART
    wire uart0_txd_o, uart0_rxd_i;
    // SPI
    wire spi_sck_o, spi_sdo_o, spi_sdi_i;
    wire[7:0] spi_csn_o;
    // PWM
    wire[15:0] pwm_o;
    // JTAG
    wire jtag_tck_i, jtag_tdi_i, jtag_tdo_o, jtag_tms_i;
    // XIP
    wire xip_csn_o, xip_clk_o, xip_sdi_i, xip_sdo_o;
    // SD
    wire sd_clk_o, sd_cmd_o, sd_cmd_i, sd_cmd_oe;
    wire sd_dat0_o, sd_dat0_i, sd_dat0_oe;
    wire sd_dat1_o, sd_dat1_i, sd_dat1_oe;
    wire sd_dat2_o, sd_dat2_i, sd_dat2_oe;
    wire sd_dat3_o, sd_dat3_i, sd_dat3_oe;
    wire[3:0] sd_dat_o, sd_dat_i, sd_dat_oe;
    wire sd_irq, sd_flag_data;

    neorv32_wrap cpu(
        .clk_i(clk),
        .rstn_i(~rst),

        .jtag_tck_i(jtag_tck_i),
        .jtag_tdi_i(jtag_tdi_i),
        .jtag_tdo_o(jtag_tdo_o),
        .jtag_tms_i(jtag_tms_i),

        .wb_adr_o(wb_xbar_adr),
        .wb_dat_i(wb_xbar_dat_i),
        .wb_dat_o(wb_xbar_dat_o),
        .wb_we_o(wb_xbar_we),
        .wb_sel_o(wb_xbar_sel),
        .wb_stb_o(wb_xbar_stb),
        .wb_cyc_o(wb_xbar_cyc),
        .wb_ack_i(wb_xbar_ack),

        .xip_csn_o(xip_csn_o),
        .xip_clk_o(xip_clk_o),
        .xip_sdi_i(xip_sdi_i),
        .xip_sdo_o(xip_sdo_o),

        .gpio_o(gpio_o),
        .gpio_i(gpio_i),

        .uart0_txd_o(uart0_txd_o),
        .uart0_rxd_i(uart0_rxd_i),

        .spi_sck_o(spi_sck_o),
        .spi_sdo_o(spi_sdo_o),
        .spi_sdi_i(spi_sdi_i),
        .spi_csn_o(spi_csn_o),

        .twi_sda_i(i2c_sda_i),
        .twi_sda_o(i2c_sda_o),
        .twi_scl_i(i2c_scl_i),
        .twi_scl_o(i2c_scl_o),

        .pwm_o(pwm_o)
    );

    wb_xbar xbar(
        .wb_adr(wb_xbar_adr),
        .wb_dat_i(wb_xbar_dat_i),
        .wb_dat_o(wb_xbar_dat_o),
        .wb_we(wb_xbar_we),
        .wb_sel(wb_xbar_sel),
        .wb_stb(wb_xbar_stb),
        .wb_cyc(wb_xbar_cyc),
        .wb_ack(wb_xbar_ack),

        .wb_i2s_adr(wb_i2s_adr),
        .wb_i2s_dat_i(wb_i2s_dat_i),
        .wb_i2s_dat_o(wb_i2s_dat_o),
        .wb_i2s_we(wb_i2s_we),
        .wb_i2s_sel(wb_i2s_sel),
        .wb_i2s_stb(wb_i2s_stb),
        .wb_i2s_cyc(wb_i2s_cyc),
        .wb_i2s_ack(wb_i2s_ack),

        .wb_io_adr(wb_io_adr),
        .wb_io_dat_i(wb_io_dat_i),
        .wb_io_dat_o(wb_io_dat_o),
        .wb_io_we(wb_io_we),
        .wb_io_sel(wb_io_sel),
        .wb_io_stb(wb_io_stb),
        .wb_io_cyc(wb_io_cyc),
        .wb_io_ack(wb_io_ack),

        .wb_sd_adr(wb_sd_adr),
        .wb_sd_dat_i(wb_sd_dat_i),
        .wb_sd_dat_o(wb_sd_dat_o),
        .wb_sd_we(wb_sd_we),
        .wb_sd_sel(wb_sd_sel),
        .wb_sd_stb(wb_sd_stb),
        .wb_sd_cyc(wb_sd_cyc),
        .wb_sd_ack(wb_sd_ack),
        // AUDIO 
        .wb_adc_adr(wb_audio_adr),
        .wb_adc_dat_i(wb_audio_dat_i),
        .wb_adc_dat_o(wb_audio_dat_o),
        .wb_adc_we(wb_audio_we),
        .wb_adc_sel(wb_audio_sel),
        .wb_adc_stb(wb_audio_stb),
        .wb_adc_cyc(wb_audio_cyc),
        .wb_adc_ack(wb_audio_ack) 

    );
    
      sd_adc_top #(
      .OSR_BITS(8),
      .ADC_WIDTH(16),
      .FIFO_LEN_BITS(8)
    ) sd_adc (
      .clk(clk),
      .rst(rst),

      .ADC_P(ADC_P),
      .ADC_N(ADC_N),
      .dac_out(dac_out),

      .wb_adr_i(wb_audio_adr),
      .wb_dat_i(wb_audio_dat_o),
      .wb_dat_o(wb_audio_dat_i),
      .wb_we_i (wb_audio_we),
      .wb_sel_i(wb_audio_sel),
      .wb_stb_i(wb_audio_stb),
      .wb_cyc_i(wb_audio_cyc),
      .wb_ack_o(wb_audio_ack),
      .wb_stall_o(),

      .fifo_low(audio_fifo_low),

      .i2s_mclk(i2s_mclk),
      .i2s_sdata(i2s_sdata),
      .i2s_sclk(i2s_sclk),
      .i2s_lrclk(i2s_lrclk)
    ); 


    // Hardcode this to GPIO port 23 for sd interrupt
    assign gpio_i[23] = sd_irq;
    assign gpio_i[22] = audio_fifo_low;

    
    neosd sd (
        .clk_i(clk),
        .rstn_i(~rst),

        .wb_adr_i(wb_sd_adr),
        .wb_dat_i(wb_sd_dat_o),
        .wb_dat_o(wb_sd_dat_i),
        .wb_we_i(wb_sd_we),
        .wb_sel_i(wb_sd_sel),
        .wb_stb_i(wb_sd_stb),
        .wb_cyc_i(wb_sd_cyc),
        .wb_ack_o(wb_sd_ack),

        .irq_o(sd_irq),
        .flag_data_o(sd_flag_data),

        .sd_clk_o(sd_clk_o),
        .sd_cmd_o(sd_cmd_o),
        .sd_cmd_i(sd_cmd_i),
        .sd_cmd_oe(sd_cmd_oe),
        .sd_dat_o(sd_dat_o),
        .sd_dat_i(sd_dat_i),
        .sd_dat_oe(sd_dat_oe)
    );
    assign sd_dat_i = {sd_dat3_i, sd_dat2_i, sd_dat1_i, sd_dat0_i};
    assign sd_dat0_o = sd_dat_o[0];
    assign sd_dat1_o = sd_dat_o[1];
    assign sd_dat2_o = sd_dat_o[2];
    assign sd_dat3_o = sd_dat_o[3];
    assign sd_dat0_oe = sd_dat_oe[0];
    assign sd_dat1_oe = sd_dat_oe[1];
    assign sd_dat2_oe = sd_dat_oe[2];
    assign sd_dat3_oe = sd_dat_oe[3];

    io_subsystem #(
        .sysinfo(sysinfo)
    ) io (
        .clk(clk),
        .arstn(arstn),
        .rst(rst),

        .wb_adr(wb_io_adr),
        .wb_dat_i(wb_io_dat_i),
        .wb_dat_o(wb_io_dat_o),
        .wb_we(wb_io_we),
        .wb_sel(wb_io_sel),
        .wb_stb(wb_io_stb),
        .wb_cyc(wb_io_cyc),
        .wb_ack(wb_io_ack),

        .gpio_i(gpio_i[21:0]),
        .gpio_o(gpio_o[21:0]),

        .i2s_mclk(i2s_mclk),
        .i2s_sdata(i2s_sdata),
        .i2s_sclk(i2s_sclk),
        .i2s_lrclk(i2s_lrclk),

        .audio_l(audio_l),
        .audio_r(audio_r),

        .i2c_sda_i(i2c_sda_i),
        .i2c_sda_o(i2c_sda_o),
        .i2c_scl_i(i2c_scl_i),
        .i2c_scl_o(i2c_scl_o),

        .uart0_txd(uart0_txd_o),
        .uart0_rxd(uart0_rxd_i),

        .spi_sck(spi_sck_o),
        .spi_sdo(spi_sdo_o),
        .spi_sdi(spi_sdi_i),
        .spi_csn(spi_csn_o[0]),

        .pwm(pwm_o[1:0]),

        .jtag_tck(jtag_tck_i),
        .jtag_tdi(jtag_tdi_i),
        .jtag_tdo(jtag_tdo_o),
        .jtag_tms(jtag_tms_i),

        .xip_csn(xip_csn_o),
        .xip_clk(xip_clk_o),
        .xip_sdi(xip_sdi_i),
        .xip_sdo(xip_sdo_o),

        .sd_clk_o(sd_clk_o),
        .sd_cmd_o(sd_cmd_o),
        .sd_cmd_i(sd_cmd_i),
        .sd_cmd_oe(sd_cmd_oe),
        .sd_dat0_o(sd_dat0_o),
        .sd_dat1_o(sd_dat1_o),
        .sd_dat2_o(sd_dat2_o),
        .sd_dat3_o(sd_dat3_o),
        .sd_dat0_i(sd_dat0_i),
        .sd_dat1_i(sd_dat1_i),
        .sd_dat2_i(sd_dat2_i),
        .sd_dat3_i(sd_dat3_i),
        .sd_dat0_oe(sd_dat0_oe),
        .sd_dat1_oe(sd_dat1_oe),
        .sd_dat2_oe(sd_dat2_oe),
        .sd_dat3_oe(sd_dat3_oe),

        .pads(pads)
    );

endmodule