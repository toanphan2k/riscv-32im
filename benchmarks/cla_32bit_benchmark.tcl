set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module cla_32bit
set benchmark_top cla_32bit_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core alu cla cla_4bit.sv] \
    [file join $repo_root rtl core alu cla cla_32bit_lau.sv] \
    [file join $repo_root rtl core alu cla cla_32bit.sv] \
]
set top_file [file join $repo_root benchmarks cla_32bit_top.sv]
set constraints_file [file join $repo_root benchmarks constraints cla_32bit.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
