// Date: 02.22.2026
// Author: Group 5 (Immanuel Kral, Julian Dorner, Ruijue Luo)
// Description: This module implements the Wishbone register interface for the Sigma-Delta ADC system.

module adc_wb_regfile #(
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst,

    // Wishbone interface
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [5:2]  wb_addr_i,
    input  wire [31:0] wb_data_i,
    output reg  [31:0] wb_data_o,
    output reg         wb_ack_o,
    output wire        wb_stall_o,
    
    // ADC core interface
    input  wire [DATA_WIDTH-1:0] adc_data_i,
    input  wire                  adc_valid_i,
    input  wire                  adc_busy_i,

    output reg                   adc_enable_o,
    output reg                   adc_soft_rst_o,
    output reg                   continuous_mode_o,
    output reg  [15:0]           decimation_rate_o,
    
    output reg [31:0] dummy4, dummy5, dummy6
);

    assign wb_stall_o = 1'b0;

    wire wb_xfer = wb_cyc_i && wb_stb_i;

    // Internal registers
    reg [DATA_WIDTH-1:0] data_latched;
    reg                  data_ready;

    // ADC data latch logic
    always @(posedge clk) begin
        if (rst) begin
            data_latched <= 0;
            data_ready   <= 0;
        end else begin
            if (adc_valid_i) begin
                data_latched <= adc_data_i;
                data_ready   <= 1'b1;
            end

            // clear on read DATA register
            if (wb_xfer && !wb_we_i && wb_addr_i == 4'h2)
                data_ready <= 1'b0;
        end
    end

    // WRITE logic
    always @(posedge clk) begin
        if (rst) begin
        
        dummy4 <= 32'h0000_0000;
        dummy5 <= 32'h0000_0000;
        dummy6 <= 32'h0000_0000;
            adc_enable_o       <= 0;
            adc_soft_rst_o     <= 0;
            continuous_mode_o  <= 0;
            decimation_rate_o  <= 16'd256;
        end else begin
            adc_soft_rst_o <= 1'b0; // one-cycle pulse

            if (wb_xfer && wb_we_i) begin
                case (wb_addr_i)
                
                4'h4: dummy4 <= wb_data_i;   // optional: writable dummy
                4'h5: dummy5 <= wb_data_i;
                4'h6: dummy6 <= wb_data_i;

                    // CTRL
                    4'h0: begin
                        adc_enable_o      <= wb_data_i[0];
                        continuous_mode_o <= wb_data_i[1];
                        if (wb_data_i[2])
                            adc_soft_rst_o <= 1'b1;
                    end

                    // CONFIG
                    4'h3: begin
                        decimation_rate_o <= wb_data_i[15:0];
                    end

                endcase
            end
        end
    end

    // READ logic
    always @(posedge clk) begin
        if (rst) begin
            wb_data_o <= 32'd0;
        end else if (wb_xfer && !wb_we_i) begin
            case (wb_addr_i)

                // CTRL
                4'h0:
                    wb_data_o <= {29'd0,
                                  1'b0,
                                  continuous_mode_o,
                                  adc_enable_o};

                // STATUS
                4'h1:
                    wb_data_o <= {30'd0,
                                  adc_busy_i,
                                  data_ready};

                // DATA
                4'h2:
                    wb_data_o <= {{(32-DATA_WIDTH){1'b0}},
                                   data_latched};

                // CONFIG
                4'h3:
                    wb_data_o <= {16'd0, decimation_rate_o};
                    
                4'h4: wb_data_o <= dummy4;
                
                4'h5: wb_data_o <= dummy5;
                4'h6: wb_data_o <= dummy6;


                default:
                    wb_data_o <= 32'hDEAD_BEEF;
            endcase
        end
    end

    // ACK generation
always @(posedge clk) begin
    if (rst)
        wb_ack_o <= 1'b0;
    else begin
        wb_ack_o <= wb_xfer;
        if (wb_xfer)
            $display("REGFILE HIT! time=%t addr=%h", $time, wb_addr_i);
    end
end

endmodule