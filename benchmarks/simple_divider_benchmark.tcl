set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module simple_divider
set benchmark_top simple_divider_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core m_ext simple_divider.sv] \
]
set top_file [file join $repo_root benchmarks simple_divider_top.sv]
set constraints_file [file join $repo_root benchmarks constraints simple_divider.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
