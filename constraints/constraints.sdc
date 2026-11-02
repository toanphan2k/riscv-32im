# Illustrative ASIC constraints for fpga_top.
# Replace these assumptions with the actual clock, interface timing, and loads.

# 100 MHz example clock. Adjust to the target frequency.
create_clock -name sys_clk -period 10.000 [get_ports {sys_clk}]

# Example clock quality assumptions; replace with clock-source and CTS budgets.
set_clock_uncertainty -setup 0.100 [get_clocks {sys_clk}]
set_clock_uncertainty -hold 0.050 [get_clocks {sys_clk}]
set_clock_transition 0.050 [get_clocks {sys_clk}]

# sys_rst_n is asynchronously asserted and synchronously deasserted internally.
# Exclude only paths launched directly by the asynchronous reset port.
set_false_path -from [get_ports {sys_rst_n}]

# Example output interface budget and capacitive load.
# Replace with the receiving device's timing and actual pin/load estimates.
set_output_delay -clock [get_clocks {sys_clk}] -max 1.000 [all_outputs]
set_output_delay -clock [get_clocks {sys_clk}] -min 0.000 [all_outputs]
set_load 5.0 [all_outputs]

# There are no synchronous data inputs in this top-level interface.
# If ports are added, constrain them with set_input_delay relative to their
# launching clock, including both -max and -min values.

# After clock-tree synthesis, use the flow's propagated-clock setup if needed:
# set_propagated_clock [get_clocks {sys_clk}]
