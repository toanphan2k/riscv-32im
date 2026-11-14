set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module radix4_res_divider
set benchmark_top radix4_res_divider_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core m_ext radix4_res_divider.sv] \
]
set top_file [file join $repo_root benchmarks radix4_res_divider_top.sv]
set constraints_file [file join $repo_root benchmarks constraints radix4_res_divider.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
