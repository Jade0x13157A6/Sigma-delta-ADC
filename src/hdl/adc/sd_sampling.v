`timescale 1ns / 1ps

module sd_sampling #()(
    input  wire clk,
    input  wire rstn,

    // 1-bit input from comparator (vin > vfb)
    input  wire cmp_in,

    // 1-bit DAC feedback
    output wire dac_out,

    // 1-bit signed bitstream for CIC
    output reg signed [1:0] bitstream
);

    // DAC Feedback path
    assign dac_out = cmp_in;
    // Bitstream Generation | The signed representation (-1 / +1) is preferred over (0 / 1) because it removes DC bias and simplifies filtering arithmetic.
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset output to zero
            bitstream <= 0;
        end else begin
            // Convert the comparator output to the signed bitstream
            bitstream <= cmp_in ? 2'sd1 : -2'sd1;
        end
    end
endmodule
