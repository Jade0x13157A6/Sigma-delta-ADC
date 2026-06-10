`timescale 1ns / 1ps

module lvds_comparator #(

)(
    input  wire lvds_p, //LVDS positive input (non-inverting)
    input  wire lvds_n, //LVDS negative input (inverting)
    output wire cmp_out //comparator output
);

`ifdef SIMULATION
    // idealized differential comparison, only used in simulation
    assign cmp_out = lvds_p & ~lvds_n;
`else
    //Hardware Implementation 
    IBUFDS #(
        .DIFF_TERM("FALSE"), //Disable internal termination
        .IBUF_LOW_PWR("FALSE"), //Use performance mode
        .IOSTANDARD("DEFAULT")
    ) i_lvds_ibuf (
        .I  (lvds_p), //positive differential input
        .IB (lvds_n), //negative differential input
        .O  (cmp_out) //single-ended output
    );
`endif
endmodule