create_clock -name benchmark_vclk -period 10.000
set_input_delay -clock benchmark_vclk -max 0.000 [all_inputs]
set_output_delay -clock benchmark_vclk -max 0.000 [all_outputs]
