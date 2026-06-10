// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
//Description: Top-Level Verilog integrating the PSoC audio IP with neorv32 CPU

module fpga_soc_top(
        inout[31:0] pads,

        output xip_q2,
        output xip_q3,
        
        input  wire ADC_P,
        input  wire ADC_N,
        output wire dac_out
    );

    soc_top #(
        .sysinfo(16'h0000)
    ) soc (
        .pads(pads),

        .ADC_P(ADC_P),
        .ADC_N(ADC_N),
        .dac_out(dac_out)
       
    );

    // NeoRV32 does not support QSPI yet.
    // In normal SPI mode, xip_q2 is nWP and xip_q3 is nRESET
    assign xip_q2 = 1'b1;
    assign xip_q3 = 1'b1;

endmodule