// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
// Description: This module is designed to verify the integration and functionality of the Sigma-Delta ADC (sd_adc_top) within a simplified SoC-style environment.
//It connects a Wishbone master (from the testbench) to the ADC module through a Wishbone crossbar (wb_xbar), enabling register access and data transfer via the Wishbone protocol.

module soc_wb_test_top(
input clk,
input rst,
input ADC_P,
input ADC_N,
output dac_out,

// Wishbone master from 'tb_wb.v'
input  [31:0] wb_adr,
input  [31:0] wb_dat_o,
output [31:0] wb_dat_i,
input  wb_we,
input  [3:0] wb_sel,
input  wb_stb,
input  wb_cyc,
output wb_ack
);

// wires between xbar and ADC slave (sd_adc_top)
wire [31:0] wb_audio_adr;
wire [31:0] wb_audio_dat_i;
wire [31:0] wb_audio_dat_o;
wire wb_audio_we;
wire [3:0] wb_audio_sel;
wire wb_audio_stb;
wire wb_audio_cyc;
wire wb_audio_ack;


// Wishbone XBAR
wb_xbar xbar(
    .wb_adr(wb_adr),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_we(wb_we),
    .wb_sel(wb_sel),
    .wb_stb(wb_stb),
    .wb_cyc(wb_cyc),
    .wb_ack(wb_ack),

    // unused slaves
    .wb_i2s_adr(),
    .wb_i2s_dat_i(32'b0),
    .wb_i2s_dat_o(),
    .wb_i2s_we(),
    .wb_i2s_sel(),
    .wb_i2s_stb(),
    .wb_i2s_cyc(),
    .wb_i2s_ack(1'b0),

    .wb_io_adr(),
    .wb_io_dat_i(32'b0),
    .wb_io_dat_o(),
    .wb_io_we(),
    .wb_io_sel(),
    .wb_io_stb(),
    .wb_io_cyc(),
    .wb_io_ack(1'b0),

    .wb_sd_adr(),
    .wb_sd_dat_i(32'b0),
    .wb_sd_dat_o(),
    .wb_sd_we(),
    .wb_sd_sel(),
    .wb_sd_stb(),
    .wb_sd_cyc(),
    .wb_sd_ack(1'b0),

    // ADC slave
    .wb_adc_adr(wb_audio_adr),
    .wb_adc_dat_i(wb_audio_dat_i),
    .wb_adc_dat_o(wb_audio_dat_o),
    .wb_adc_we(wb_audio_we),
    .wb_adc_sel(wb_audio_sel),
    .wb_adc_stb(wb_audio_stb),
    .wb_adc_cyc(wb_audio_cyc),
    .wb_adc_ack(wb_audio_ack)
);

// Wishbone slave --> 'sd_adc_top.v'
sd_adc_top adc(
    .clk(clk),
    .rst(rst),
    .ADC_P(ADC_P),
    .ADC_N(ADC_N),
    .dac_out(dac_out),

    .i2s_mclk(),
    .i2s_sclk(),
    .i2s_lrclk(),
    .i2s_sdata(),

    .wb_adr_i(wb_audio_adr),
    .wb_dat_i(wb_audio_dat_o),
    .wb_dat_o(wb_audio_dat_i),
    .wb_we_i(wb_audio_we),
    .wb_sel_i(wb_audio_sel),
    .wb_stb_i(wb_audio_stb),
    .wb_cyc_i(wb_audio_cyc),
    .wb_ack_o(wb_audio_ack),
    .wb_stall_o(),

    .fifo_low()
);

endmodule