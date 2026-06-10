// ============================================================
// File: tb_sd_adc.v
// Full testbench: sigma-delta ADC + analog model + Wishbone
// ============================================================

`timescale 1ns / 1ps

module tb_sd_adc;

    // -------------------------------------------------
    // Parameters (MUST match sd_adc_top)
    // -------------------------------------------------
    localparam OSR_BITS   = 8;
    localparam ACC_WIDTH  = 24;
    localparam ADC_WIDTH  = 16;
    localparam CLK_PERIOD = 10;   // 100 MHz

    // -------------------------------------------------
    // Clock / Reset
    // -------------------------------------------------
    reg clk;
    reg rstn;

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        rstn = 0;
        #(10*CLK_PERIOD);
        rstn = 1;
    end

    // -------------------------------------------------
    // ADC analog interface
    // -------------------------------------------------
    reg  cmp_in;
    wire dac_out;
    
    // LVDS
    reg ADC_P;
    reg ADC_N;

    // -------------------------------------------------
    // Wishbone signals (fake CPU)
    // -------------------------------------------------
    reg         wb_cyc_i;
    reg         wb_stb_i;
    reg         wb_we_i;
    reg [31:0]  wb_adr_i;
    reg [31:0]  wb_dat_i;
    wire [31:0] wb_dat_o;
    wire        wb_ack_o;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    sd_adc_top #(
        .OSR_BITS (OSR_BITS),
        .ACC_WIDTH(ACC_WIDTH),
        .ADC_WIDTH(ADC_WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
       // .cmp_in(cmp_in),
        
        .ADC_P(ADC_P),
        .ADC_N(ADC_N),
      //  .cmp_out(cmp_out),
        .dac_out(dac_out),

        // Wishbone
        .wb_cyc_i(wb_cyc_i),
        .wb_stb_i(wb_stb_i),
        .wb_we_i (wb_we_i),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_ack_o(wb_ack_o)
    );

    // -------------------------------------------------
    // Analog feedback model (RC + comparator)
    // -------------------------------------------------
    real vin;
    real vout;
    real vin_rc;
    real VDD=3.3;
    
    
    real VREF  = 3.3;
    real R     = 1000.0;
    real C     = 1e-9;
    real Ts    = 10e-9;
    real alpha;

    initial begin
        vout  = 0.0;
        vin   = 0.0;
        alpha = Ts/(R*C);
    end

    always @(posedge clk) begin
        if (!rstn)
            vout <= 0.0;
        else begin
            //vin_rc = dac_out ? VREF : -VREF;  // 1-Bit DAC: if dac_out=1-> +VREF; if dac_out=0->-VREF
            vin_rc = dac_out ? VREF : 0.0;
            vout   = vout + alpha * (vin_rc - vout);
            //vout = vout + alpha * ((vin_rc - VDD/2) - vout);

        end
    end
 
    /*always @(posedge clk) begin
        if (!rstn)
            cmp_in <= 1'b0;
        else
            cmp_in <= (vin > vout);
    end */
    
    always @(posedge clk) begin
        if (!rstn) begin
            ADC_P <= 1'b0;
            ADC_N <= 1'b1;
        end else begin
            ADC_P <= (vin > vout);
            ADC_N <= ~(vin > vout);
        end
    end

    initial begin
        wait (rstn == 1'b1);
        forever begin
            vin = VDD/2 + 0.8 * $sin($time * 1e-9 * 2.0 * 3.141592 * 20000.0);
            #(CLK_PERIOD);
        end
    end

    // -------------------------------------------------
    // File output (ABSOLUTE PATH + CHECK)
    // -------------------------------------------------
    integer vin_file;
    integer vout_file;
    integer dac_file;

   /* initial begin
        vin_file  = $fopen("/home/uzepk/Dokumente/julian/soc-adc/sim/vin_values.txt", "w");
        if (vin_file == 0) begin $display("ERROR: open vin_values.txt failed"); $finish; end

        vout_file = $fopen("/home/uzepk/Dokumente/julian/soc-adc/sim/vout_values.txt", "w");
        if (vout_file == 0) begin $display("ERROR: open vout_values.txt failed"); $finish; end

        dac_file  = $fopen("/home/uzepk/Dokumente/julian/soc-adc/sim/dac_out_values.txt", "w");
        if (dac_file == 0) begin $display("ERROR: open dac_out_values.txt failed"); $finish; end
    end 

    always @(posedge clk) if (rstn) begin
        $fwrite(vin_file,  "%e %e\n", $time*1e-9, vin);
        $fwrite(vout_file, "%e %e\n", $time*1e-9, vout);
        $fwrite(dac_file,  "%e %e\n", $time*1e-9, dac_out);
    end
*/
    // -------------------------------------------------
    // Wishbone read helper (WAIT ACK + TIMEOUT)
    // -------------------------------------------------
    task wb_read32;
        input  [31:0] addr;
        output [31:0] data;
        integer k;
        begin
            // drive request
            @(posedge clk);
            wb_adr_i <= addr;
            wb_we_i  <= 1'b0;
            wb_dat_i <= 32'd0;
            wb_cyc_i <= 1'b1;
            wb_stb_i <= 1'b1;

            // wait for ack with timeout
            k = 0;
            while (!wb_ack_o && k < 200) begin
                @(posedge clk);
                k = k + 1;
            end

            if (!wb_ack_o) begin
                $display("[WB] TIMEOUT addr=%h at t=%0t", addr, $time);
                $fatal;
            end

            data = wb_dat_o;

            // deassert
            @(posedge clk);
            wb_cyc_i <= 1'b0;
            wb_stb_i <= 1'b0;
        end
    endtask

    // -------------------------------------------------
    // Fake CPU: poll STATUS then read DATA
    // -------------------------------------------------
    integer i;
    reg [31:0] status;
    reg [31:0] data;

    initial begin
        // init WB
        wb_cyc_i = 0;
        wb_stb_i = 0;
        wb_we_i  = 0;
        wb_adr_i = 0;
        wb_dat_i = 0;

        wait (rstn == 1'b1);
        #2000; // let ADC settle (2us)

        for (i = 0; i < 50; i = i + 1) begin
            wb_read32(32'h0000_0004, status); // STATUS
            if (status[0]) begin
                wb_read32(32'h0000_0000, data); // DATA
                $display("[WB] t=%0t status=%h data=%0d", $time, status, $signed(data));
            end
            #2000;
        end
    end

    // -------------------------------------------------
    // Stop simulation
    // -------------------------------------------------
    initial begin
        #500_000_000;
        $fclose(vin_file);
        $fclose(vout_file);
        $fclose(dac_file);
        $display("Simulation finished.");
        $stop;
    end

endmodule
