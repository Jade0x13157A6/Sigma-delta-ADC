// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
//Description: Top-Level Sigma-Delta ADC system block

module sd_adc_top #(
    parameter OSR_BITS   = 8,
    parameter ADC_WIDTH  = 16,
    parameter FIFO_LEN_BITS = 8 
)(
    input  wire clk,
    input  wire rst,

    input  wire ADC_P,
    input  wire ADC_N,
    output wire dac_out,

    output wire i2s_mclk,
    output wire i2s_sclk,
    output wire i2s_lrclk,
    output wire i2s_sdata,
    
    // Wishbone 
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output wire [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output wire        wb_ack_o,
    output wire        wb_stall_o,
    
    
    output wire        fifo_low
);

    wire signed [1:0] bitstream; 
    wire signed [ADC_WIDTH-1:0] adc_data; 
    wire adc_valid; 
    wire cmp_int; 

    lvds_comparator u_cmp ( 
        .lvds_p (ADC_P), 
        .lvds_n (ADC_N),
        .cmp_out(cmp_int) 
    ); 

    sd_sampling u_samp ( 
        .clk(clk), 
        .rstn(~rst), 
        .cmp_in(cmp_int), 
        .dac_out(dac_out), 
        .bitstream(bitstream)
    ); 

    cic_decimator #(
        .OSR_BITS(OSR_BITS), 
        .ADC_WIDTH(ADC_WIDTH) 
    ) u_cic ( 
        .clk(clk), 
        .rstn(~rst), 
        .data_in(bitstream), 
        .data_out(adc_data), 
        .out_valid(adc_valid) 
    ); 
    
    // Regfile controls 
    wire software_rst;
    wire audio_enable; // optional gating
    wire i2s_enable;
    wire dac_enable;   // unused here, kept for compatibility
    wire dac_mode;     // unused here, kept for compatibility
    wire [31:0] freq_setting; // unused
    wire [FIFO_LEN_BITS:0] fifo_threshold;

    wire device_reset = rst | software_rst;
    
    // Clock generator 
    wire clk_en_4, clk_en_16;

    clock_generator clk_gen(
        .clk(clk),
        .rst(software_rst),
        .clk_en_2(),
        .clk_en_4(clk_en_4),
        .clk_en_8(),
        .clk_en_16(clk_en_16)
    );
   
    // FIFO 
    wire [47:0] fifo_data_in, fifo_data_out;
    wire        fifo_full, fifo_empty;
    wire [FIFO_LEN_BITS:0] fifo_level;

    // ADC -> 24-bit sign-extend, pack mono to stereo
    wire signed [23:0] adc_s24 = {{(24-ADC_WIDTH){adc_data[ADC_WIDTH-1]}}, adc_data};
    assign fifo_data_in = {adc_s24, adc_s24}; // {L,R}

    // write when valid and not full; 
    wire fifo_write = adc_valid & ~fifo_full; //& audio_enable;

    // I2S-driven read (synchronous like psoc_audio)
    wire fifo_ready_i2s;
    reg  fifo_read_sync;

    always @(posedge clk or posedge device_reset) begin
        if (device_reset)
            fifo_read_sync <= 1'b0;
        else
            fifo_read_sync <= fifo_ready_i2s;
    end
    
     sfifo #(.BW(48), .LGFLEN(FIFO_LEN_BITS)) fifo_inst (
        .i_clk  (clk),
        .i_rst  (device_reset),

        .i_wr   (fifo_write),
        .i_data (fifo_data_in),
        .o_ready(),          // not used
        .o_full (fifo_full),
        .o_fill (fifo_level),

        .i_rd   (fifo_read_sync),
        .o_data (fifo_data_out),
        .o_empty(fifo_empty)
    );

    wire fifo_write_ready = ~fifo_full;
    wire fifo_has_data    = ~fifo_empty;

    // fifo_low like psoc_audio
    assign fifo_low = (fifo_level < fifo_threshold);
    
    // I2S 
    i2s_master i2s_inst(
        .clk(clk),
        .rst(device_reset),
        .clk_en(i2s_enable),
        .mclk_en(clk_en_4),
        .sclk_en(clk_en_16),

        .fifo_data (fifo_data_out),
        .fifo_valid(!fifo_empty),
        .fifo_ready(fifo_ready_i2s),

        .mclk (i2s_mclk),
        .sclk (i2s_sclk),
        .lrclk(i2s_lrclk),
        .sdata(i2s_sdata)
    );
    

    
adc_wb_regfile adc_regs (
    .clk       (clk),
    .rst       (rst),
    
    .wb_cyc_i  (wb_cyc_i),
    .wb_stb_i  (wb_stb_i),
    .wb_we_i   (wb_we_i),

    .wb_addr_i (wb_adr_i[5:2]),

    .wb_data_i (wb_dat_i),
    .wb_data_o (wb_dat_o),
    .wb_ack_o  (wb_ack_o),
    .wb_stall_o(wb_stall_o),

    .adc_data_i (adc_data),
    .adc_valid_i(adc_valid),
    .adc_busy_i (1'b0),

    .adc_enable_o(audio_enable),
    .adc_soft_rst_o(),
    .continuous_mode_o(),
    .decimation_rate_o()
);

endmodule
