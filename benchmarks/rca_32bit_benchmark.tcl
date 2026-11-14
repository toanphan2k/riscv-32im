set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module rca_32bit
set benchmark_top rca_32bit_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core alu rca full_adder.sv] \
    [file join $repo_root rtl core alu rca rca_4bit.sv] \
    [file join $repo_root rtl core alu rca rca_32bit.sv] \
]
set top_file [file join $repo_root benchmarks rca_32bit_top.sv]
set constraints_file [file join $repo_root benchmarks constraints rca_32bit.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
