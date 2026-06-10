`timescale 1ns / 1ps
//Behavioral testbench for the standalone SIgma-Delta ADC design

module tb_sd_adc;

    //Simulation Parameters
    localparam OSR_BITS   = 8;
    localparam ACC_WIDTH  = 24;
    localparam ADC_WIDTH  = 16;
    localparam CLK_PERIOD = 10;   // 100 MHz


    reg clk;
    reg rstn;
    // Clock & Reset Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    initial begin
        rstn = 0;
        #(10*CLK_PERIOD);
        rstn = 1;
    end

    //DUT connections
    reg  cmp_in;
    wire dac_out;
    
    // LVDS
    reg ADC_P;
    reg ADC_N;
    
    //DUT
    sd_adc_standalone_top #(
        .OSR_BITS (OSR_BITS),
        .ACC_WIDTH(ACC_WIDTH),
        .ADC_WIDTH(ADC_WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),

        
        .ADC_P(ADC_P),
        .ADC_N(ADC_N),
        .dac_out(dac_out)

    );

    // Analog input 
    real vin;       //input signal
    real vout;      //RC filtered feedback signal
    real vin_rc;    //DAC voltage before RC filtering
    
    real VDD=3.3;   
    real VREF  = 3.3;
    
    //RC network parameters
    real R     = 1000.0;
    real C     = 1e-9;
    real Ts    = 10e-9;
    real alpha;
    
    
    initial begin
        vout  = 0.0;
        vin   = 0.0;
        alpha = Ts/(R*C); // RC approximation factor
    end
    
    //1-bit DAC + RC Feedback Model
    always @(posedge clk) begin
        if (!rstn)
            vout <= 0.0;
        else begin
            vin_rc = dac_out ? VREF : 0.0;
            vout   = vout + alpha * (vin_rc - vout);
        end
    end
 
    // Comparator Modeling (Differential LVDS)
    always @(posedge clk) begin
        if (!rstn) begin
            ADC_P <= 1'b0;
            ADC_N <= 1'b1;
        end else begin
            ADC_P <= (vin > vout);
            ADC_N <= ~(vin > vout);
        end
    end

    //ANalog Sine Wave generation for input 
    initial begin
        wait (rstn == 1'b1);
        forever begin
            vin = VDD/2 + 0.8 * $sin($time * 1e-9 * 2.0 * 3.141592 * 20000.0);
            #(CLK_PERIOD);
        end
    end

    //Simulation Stop
    initial begin
        #500_000_000;
        $display("Simulation finished.");
        $stop;
    end

endmodule
