`timescale 1ns / 1ps

module cic_decimator #(
    parameter OSR_BITS  = 8,   // log2(R) | R = 256 
    parameter ADC_WIDTH = 16   // Desired output width
)(
    input  wire clk,
    input  wire rstn,
    input  wire signed [1:0] data_in, // +1 / -1
    
    output reg signed [ADC_WIDTH-1:0] data_out, //Decimated output sample 
    output reg out_valid // Output valid strobe
);


    localparam INTERNAL_WIDTH = 32; // at least 24+2 are required, for safety 32 bits are used

    
    //Integrator Section
    
    reg signed [INTERNAL_WIDTH-1:0] int1, int2, int3;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int1 <= 0; int2 <= 0; int3 <= 0;
        end else begin
            // Wrap-around Arithmetik ist hier beabsichtigt und korrekt!
            int1 <= int1 + data_in;
            int2 <= int2 + int1;
            int3 <= int3 + int2;
        end
    end

 
 // Decimation Control
 // Generates clock enable pulse every 256 cycles 
  
    reg [OSR_BITS-1:0] cnt;
    reg ce_dec; // Decimation Clock Enable

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt <= 0; ce_dec <= 0;
        end else begin
            cnt <= cnt + 1;
            ce_dec <= (cnt == 0); // Pulse once every R clocks
        end
    end


// Comb Section (runs only at decimated rate)
    reg signed [INTERNAL_WIDTH-1:0] int3_d;
    reg signed [INTERNAL_WIDTH-1:0] comb1, comb2, comb3;
    reg signed [INTERNAL_WIDTH-1:0] comb1_d, comb2_d, comb3_d;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            comb1_d <= 0; comb2_d <= 0; comb3_d <= 0;
            data_out <= 0; out_valid <= 0;
        end else if (ce_dec) begin
           
            comb1 <= int3  - comb1_d;  comb1_d <= int3; // First comb stage
            comb2 <= comb1 - comb2_d;  comb2_d <= comb1; // Second comb stage
            comb3 <= comb2 - comb3_d;  comb3_d <= comb2; // Third comb stage 

            data_out <= comb3[INTERNAL_WIDTH-1 -: ADC_WIDTH];  // Take the MSBs of comb3 as final ADC output
            
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0; 
        end
    end

endmodule