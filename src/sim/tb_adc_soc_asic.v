// ============================================================
// Date: 2026/01/18
// File: tb_adc_soc_asic.v
// testbench for adc_soc_asic.v
// ============================================================

module tb_adc_soc_asic;

  reg clk = 0;
  reg rst = 1;
  reg [11:0] vin = 12'd1000;
  wire [7:0] adc_out;

  always #5 clk = ~clk;

  adc_soc_asic dut (
    .clk(clk),
    .rst(rst),
    .vin(vin),
    .adc_out(adc_out)
  );

  initial begin
    #20 rst = 0;
    #1000 $finish;
  end

endmodule


