

# ------------------------------------------------------------
# 1. System Clock
# ------------------------------------------------------------
# Zedboard 100 MHz Clock
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk [get_ports clk]

# ------------------------------------------------------------
# 2. Reset
# ------------------------------------------------------------
# Reset Button / GPIO Reset
set_property PACKAGE_PIN F22 [get_ports rstn]
set_property IOSTANDARD LVCMOS18 [get_ports rstn]
set_false_path -from [get_ports rstn]
set_input_delay  -clock sys_clk 1.0 [get_ports rstn]

# ------------------------------------------------------------
# 3. LVDS Input (Comparator Input)

set_property PACKAGE_PIN V7 [get_ports ADC_P]
set_property IOSTANDARD LVDS_25 [get_ports ADC_P]

set_property PACKAGE_PIN W7 [get_ports ADC_N]
set_property IOSTANDARD LVDS_25 [get_ports ADC_N]


# ------------------------------------------------------------
# 5. Debug LED (optional)
# LED LD0
# ------------------------------------------------------------
set_property PACKAGE_PIN Y11 [get_ports dac_out]
set_property IOSTANDARD LVCMOS33 [get_ports dac_out]



set_property PACKAGE_PIN Y10 [get_ports gpio_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports gpio_rstn]

## LEDs 
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0] led[1] led[2] led[3] led[4] led[5] led[6] led[7]}]

