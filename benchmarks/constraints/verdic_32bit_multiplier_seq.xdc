create_clock -name benchmark_clk -period 10.000 [get_ports {clk}]
set_input_delay -clock benchmark_clk -max 0.000 [get_ports {start operand_a[*] operand_b[*] m_opcode[*]}]
set_output_delay -clock benchmark_clk -max 0.000 [all_outputs]
set_false_path -from [get_ports {rst_n}]
