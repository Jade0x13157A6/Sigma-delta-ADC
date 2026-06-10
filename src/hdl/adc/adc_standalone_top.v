`timescale 1ns / 1ps

module sd_adc_standalone_top #( 
    parameter OSR_BITS   = 8, //log2(decimation factor), R = 2^OSR_BITS
    parameter ADC_WIDTH  = 16 //Output resolution of the ADC
)( 
    input  wire clk, 
    input  wire rstn, 

    // LVDS Analog Interface
    input  wire ADC_P, 
    input  wire ADC_N, 
    output wire dac_out,
    // Debug Interface
    output reg  [7:0] led  // LED output (simple amplitude visualization)
    
      
); 

    // Internal signals
    wire signed [1:0] bitstream; 
    wire signed [ADC_WIDTH-1:0] adc_data; 
    wire adc_valid; 
    wire cmp_int; 
    
    
    

    // 1. LVDS Input Buffer (Comparator)
    lvds_comparator u_cmp ( 
        .lvds_p (ADC_P), 
        .lvds_n (ADC_N),
        .cmp_out(cmp_int) 
    ); 

    // 2. Sigma-Delta Modulator 
    sd_sampling u_samp ( 
        .clk(clk), 
        .rstn(rstn), 
        .cmp_in(cmp_int), 
        .dac_out(dac_out), 
        .bitstream(bitstream)
        
    ); 

    // 3. CIC Decimator 
    cic_decimator #( 
        .OSR_BITS(OSR_BITS), 
        .ADC_WIDTH(ADC_WIDTH) 
    ) u_cic ( 
        .clk(clk), 
        .rstn(rstn), 
        .data_in(bitstream), 
        .data_out(adc_data), 
        .out_valid(adc_valid) 
    ); 

    // LED Logic
    // LEDS are lit progressively depending on adc_data
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            led <= 8'b0;
        end else begin
            case (adc_data) 
                4'b0000: led <= 8'b00000001; // LED0
                4'b0010: led <= 8'b00000011; // LED0+LED1
                4'b0100: led <= 8'b00000111; // LED0-LED2
                4'b0110: led <= 8'b00001111; // LED0-LED3
                4'b1000: led <= 8'b00011111; // LED0-LED4
                4'b1010: led <= 8'b00111111; // LED0-LED5
                4'b1100: led <= 8'b01111111; // LED0-LED6
                4'b1110: led <= 8'b11111111; // alle LEDs
                default: led <= 8'b0;
            endcase
        end
    end


 
endmodule