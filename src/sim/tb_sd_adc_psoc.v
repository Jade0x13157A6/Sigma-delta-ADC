`timescale 1ns/1ps

module tb_sd_adc_top;

  // --------------------------------------------------
  // Clock + Reset
  // --------------------------------------------------
  reg clk = 0;
  reg rst = 1;

  always #5 clk = ~clk;   // 100 MHz

  // --------------------------------------------------
  // ADC LVDS Inputs (simulated)
  // --------------------------------------------------
  reg ADC_P = 0;
  reg ADC_N = 1;

  // --------------------------------------------------
  // Wishbone signals
  // --------------------------------------------------
  reg  [31:0] wb_adr_i;
  reg  [31:0] wb_dat_i;
  wire [31:0] wb_dat_o;
  reg         wb_we_i;
  reg  [3:0]  wb_sel_i;
  reg         wb_stb_i;
  reg         wb_cyc_i;
  wire        wb_ack_o;
  wire        wb_stall_o;

  // --------------------------------------------------
  // DUT Outputs
  // --------------------------------------------------
  wire dac_out;
  wire i2s_mclk;
  wire i2s_sclk;
  wire i2s_lrclk;
  wire i2s_sdata;
  wire fifo_low;

  // --------------------------------------------------
  // DUT
  // --------------------------------------------------
  sd_adc_top #(
    .OSR_BITS(4),
    .ADC_WIDTH(16),
    .FIFO_LEN_BITS(4)
  ) dut (
    .clk(clk),
    .rst(rst),

    .ADC_P(ADC_P),
    .ADC_N(ADC_N),
    .dac_out(dac_out),

    .i2s_mclk(i2s_mclk),
    .i2s_sclk(i2s_sclk),
    .i2s_lrclk(i2s_lrclk),
    .i2s_sdata(i2s_sdata),

    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_we_i (wb_we_i),
    .wb_sel_i(wb_sel_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_ack_o(wb_ack_o),
    .wb_stall_o(wb_stall_o),

    .fifo_low(fifo_low)
  );

  // --------------------------------------------------
  // Simple Wishbone Write Task
  // --------------------------------------------------
  task wb_write;
    input [3:0] addr;
    input [31:0] data;
  begin
    @(posedge clk);
    wb_adr_i <= {28'hFFD0_000, addr}; // upper bits ignored
    wb_dat_i <= data;
    wb_we_i  <= 1;
    wb_sel_i <= 4'hF;
    wb_stb_i <= 1;
    wb_cyc_i <= 1;

    wait(wb_ack_o);

    @(posedge clk);
    wb_stb_i <= 0;
    wb_cyc_i <= 0;
    wb_we_i  <= 0;
  end
  endtask

  // --------------------------------------------------
  // Simple Wishbone Read Task
  // --------------------------------------------------
  task wb_read;
    input  [3:0] addr;
  begin
    @(posedge clk);
    wb_adr_i <= {28'hFFD0_000, addr};
    wb_we_i  <= 0;
    wb_sel_i <= 4'hF;
    wb_stb_i <= 1;
    wb_cyc_i <= 1;

    wait(wb_ack_o);

    $display("WB READ [%h] = %h", addr, wb_dat_o);

    @(posedge clk);
    wb_stb_i <= 0;
    wb_cyc_i <= 0;
  end
  endtask

  // --------------------------------------------------
  // ADC stimulus (fake toggling LVDS)
  // --------------------------------------------------
  always @(posedge clk)
  begin
    ADC_P <= ~ADC_P;
    ADC_N <= ~ADC_N;
  end

  // --------------------------------------------------
  // Test Sequence
  // --------------------------------------------------
  initial begin

    // Init
    wb_adr_i = 0;
    wb_dat_i = 0;
    wb_we_i  = 0;
    wb_sel_i = 0;
    wb_stb_i = 0;
    wb_cyc_i = 0;

    // Reset release
    #100;
    rst = 0;

    // Enable audio + I2S
    wb_write(4'h0, 32'h1);   // audio_enable
    wb_write(4'h5, 32'h2);   // i2s_enable

    // Set FIFO threshold
    wb_write(4'h2, 32'h2);

    // Let ADC generate samples
    repeat(2000) @(posedge clk);

    // Read FIFO status
    wb_read(4'h4);

    // Run more cycles to observe I2S
    repeat(5000) @(posedge clk);

    $display("Simulation finished.");
    $stop;
  end

endmodule
