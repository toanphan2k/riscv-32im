set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module radix4_divider_comb
set benchmark_top radix4_divider_comb_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core m_ext radix4_divider_comb.sv] \
]
set top_file [file join $repo_root benchmarks radix4_divider_comb_top.sv]
set constraints_file [file join $repo_root benchmarks constraints radix4_divider_comb.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
