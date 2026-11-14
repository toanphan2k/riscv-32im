set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module simple_32bit_adder
set benchmark_top simple_32bit_adder_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core alu simple_adder simple_32bit_adder.sv] \
]
set top_file [file join $repo_root benchmarks simple_32bit_adder_top.sv]
set constraints_file [file join $repo_root benchmarks constraints simple_32bit_adder.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
