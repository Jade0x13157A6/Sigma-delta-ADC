// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
//Description: This testbench is for 'wb_test.v' and is used to verify correct Wishbone communication with the ADC system.

`timescale 1ns/1ps
module tb;

// CLOCK 50MHz
reg clk = 0;
always #10 clk = ~clk;

// RESET
reg rst;
initial begin
    rst = 1;
    #200;
    rst = 0;
end

// LVDS stimulus
reg ADC_P ;
reg ADC_N ;

/*always @(posedge clk) begin
    if (rst) begin
        ADC_P <= 0;
        ADC_N <= 1;
    end else begin
        ADC_P <= ~ADC_P;
        ADC_N <=  ADC_P;
    end
end
*/

// SINE input stimulus
real t = 0;
real fs = 50e6;      // sampling clock = 50MHz
real fin = 20000.0;  // 20kHz sine
real amp = 0.9;      // amplitude
real v;

always @(posedge clk) begin
    if (rst) begin
        ADC_P <= 0;
        ADC_N <= 1;
        t <= 0;
    end else begin
        t = t + 1.0/fs;
        v = amp * $sin(2.0 * 3.1415926 * fin * t);

        if(v > 0) begin
            ADC_P <= 1;
            ADC_N <= 0;
        end else begin
            ADC_P <= 0;
            ADC_N <= 1;
        end
    end
end

// Wishbone master signals
reg  [31:0] adr;
reg  [31:0] dat_o;
wire [31:0] dat_i;
reg         wb_we;
reg  [3:0]  wb_sel;
reg         wb_stb;
reg         wb_cyc;
wire        wb_ack;

wire dac_out;

// DUT
soc_wb_test_top dut(
    .clk(clk),
    .rst(rst),
    .ADC_P(ADC_P),
    .ADC_N(ADC_N),
    .dac_out(dac_out),

    .wb_adr(adr),
    .wb_dat_o(dat_o),
    .wb_dat_i(dat_i),
    .wb_we(wb_we),
    .wb_sel(wb_sel),
    .wb_stb(wb_stb),
    .wb_cyc(wb_cyc),
    .wb_ack(wb_ack)
);

// peek xbar->adc internal routing
wire adc_stb = dut.wb_audio_stb;
wire adc_cyc = dut.wb_audio_cyc;
wire adc_ack = dut.wb_audio_ack;

task wb_idle;
begin
    adr   = 32'h0;
    dat_o = 32'h0;
    wb_we = 1'b0;
    wb_sel= 4'hF;
    wb_stb= 1'b0;
    wb_cyc= 1'b0;
end
endtask

task wb_write(input [31:0] addr, input [31:0] data);
integer timeout;
begin
    @(posedge clk);
    adr   <= addr;
    dat_o <= data;
    wb_we <= 1'b1;
    wb_sel<= 4'hF;
    wb_stb<= 1'b1;
    wb_cyc<= 1'b1;

    timeout = 0;
    while (wb_ack !== 1'b1 && timeout < 500) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    $display("[WB WRITE] addr=%h data=%h ack=%b | route_to_adc: stb=%b cyc=%b ack=%b | t=%0t",
             addr, data, wb_ack, adc_stb, adc_cyc, adc_ack, $time);

    if (adc_stb===1'b0 && adc_cyc===1'b0)
        $display("  -> WARNING: xbar did NOT route this access to ADC (address decode mismatch?)");

    wb_stb<= 1'b0;
    wb_cyc<= 1'b0;
    wb_we <= 1'b0;
    @(posedge clk);
end
endtask

task wb_read(input [31:0] addr);
integer timeout;
reg [31:0] rdata;
begin
    @(posedge clk);
    adr   <= addr;
    wb_we <= 1'b0;
    wb_sel<= 4'hF;
    wb_stb<= 1'b1;
    wb_cyc<= 1'b1;

    timeout = 0;
    while (wb_ack !== 1'b1 && timeout < 500) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    rdata = dat_i;

    $display("[WB READ ] addr=%h data=%h ack=%b | route_to_adc: stb=%b cyc=%b ack=%b | t=%0t",
             addr, rdata, wb_ack, adc_stb, adc_cyc, adc_ack, $time);

    if (adc_stb===1'b0 && adc_cyc===1'b0)
        $display("  -> WARNING: xbar did NOT route this access to ADC (address decode mismatch?)");

    wb_stb<= 1'b0;
    wb_cyc<= 1'b0;
    @(posedge clk);
end
endtask

// TEST
initial begin
    wb_idle();

    wait(!rst);
    repeat(50) @(posedge clk);

    $display("====== START WB TEST ======");

    // enable ADC (CTRL bit0)
    wb_write(32'hFFD3_0000, 32'h0000_0001);
    wb_read (32'hFFD3_0000);

    // dummy write/read
    wb_write(32'hFFD3_0004, 32'hDEAD_BEEF);
    wb_read (32'hFFD3_0004);

    // Read ADC DATA Register
    // DATA = offset 0x8 => addr[5:2]=2
    repeat (200) begin
        #20000;               
        wb_read(32'hFFD3_0008); 
    end

    $display("====== END ======");

    #100000;
    $finish;
end

endmodule