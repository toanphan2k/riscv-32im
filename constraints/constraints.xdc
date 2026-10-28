# Example: 100 MHz input clock (10 ns period).
# create_clock -name sys_clk -period 10.00 [get_ports clk]


# Set I/O standards and package pins using your board's master XDC.
# Do not use guessed pin assignments; incorrect pins can prevent implementation
# or cause electrical conflicts on the board.
#
# Example syntax:
# set_property -dict { PACKAGE_PIN <clock_pin> IOSTANDARD <io_standard> } [get_ports clk]
# set_property -dict { PACKAGE_PIN <reset_pin> IOSTANDARD <io_standard> } [get_ports rst_n]
# set_property -dict { PACKAGE_PIN <start_pin> IOSTANDARD <io_standard> } [get_ports start]
# set_property -dict { PACKAGE_PIN <write_enable_pin> IOSTANDARD <io_standard> } [get_ports ram_we]
# set_property -dict { PACKAGE_PIN <done_pin> IOSTANDARD <io_standard> } [get_ports done]
# set_property -dict { PACKAGE_PIN <write_address_bit_0_pin> IOSTANDARD <io_standard> } [get_ports {ram_waddr[0]}]
# Repeat for ram_waddr[1] through ram_waddr[6].
# set_property -dict { PACKAGE_PIN <write_data_bit_0_pin> IOSTANDARD <io_standard> } [get_ports {ram_wdata[0]}]
# Repeat for ram_wdata[1] through ram_wdata[7].
# set_property -dict { PACKAGE_PIN <min_bit_0_pin> IOSTANDARD <io_standard> } [get_ports {min_value[0]}]
# set_property -dict { PACKAGE_PIN <min_bit_1_pin> IOSTANDARD <io_standard> } [get_ports {min_value[1]}]
# set_property -dict { PACKAGE_PIN <min_bit_2_pin> IOSTANDARD <io_standard> } [get_ports {min_value[2]}]
# set_property -dict { PACKAGE_PIN <min_bit_3_pin> IOSTANDARD <io_standard> } [get_ports {min_value[3]}]
# set_property -dict { PACKAGE_PIN <min_bit_4_pin> IOSTANDARD <io_standard> } [get_ports {min_value[4]}]
# set_property -dict { PACKAGE_PIN <min_bit_5_pin> IOSTANDARD <io_standard> } [get_ports {min_value[5]}]
# set_property -dict { PACKAGE_PIN <min_bit_6_pin> IOSTANDARD <io_standard> } [get_ports {min_value[6]}]
# set_property -dict { PACKAGE_PIN <min_bit_7_pin> IOSTANDARD <io_standard> } [get_ports {min_value[7]}]
#
# address is an output on this design, typically useful for debug. If you
# keep it as a top-level port, constrain each bit as well:
# set_property -dict { PACKAGE_PIN <address_bit_pin> IOSTANDARD <io_standard> } [get_ports {address[0]}]
# Repeat for address[1] through address[6].

## Nexys A7-100T pin constraints for fpga_top.

## Timing-analysis target: 12.5 MHz
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports {sys_clk}]
create_clock -name sys_clk -period 10.000 -waveform {0 5} [get_ports {sys_clk}]

## Active-low CPU reset button
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports {sys_rst_n}]
set_false_path -from [get_ports {sys_rst_n}]

## 7-segment anodes (active-low)
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {anode[0]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {anode[1]}]
set_property -dict { PACKAGE_PIN T9 IOSTANDARD LVCMOS33 } [get_ports {anode[2]}]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {anode[3]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {anode[4]}]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {anode[5]}]
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports {anode[6]}]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {anode[7]}]

## Seven-segment outputs, seg_out[6:0] = {CA, CB, CC, CD, CE, CF, CG}
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {seg_out[6]}]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports {seg_out[5]}]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {seg_out[4]}]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {seg_out[3]}]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {seg_out[2]}]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {seg_out[1]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {seg_out[0]}]

