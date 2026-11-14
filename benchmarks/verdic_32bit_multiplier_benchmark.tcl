set repo_root [file normalize [file join [file dirname [info script]] ..]]
set benchmark_module verdic_32bit_multiplier
set benchmark_top verdic_32bit_multiplier_benchmark_top
set rtl_sources [list \
    [file join $repo_root rtl pkg rv32im_pkg.sv] \
    [file join $repo_root rtl core m_ext verdic_32bit_multiplier.sv] \
]
set top_file [file join $repo_root benchmarks verdic_32bit_multiplier_top.sv]
set constraints_file [file join $repo_root benchmarks constraints verdic_32bit_multiplier.xdc]
source [file join $repo_root benchmarks benchmark_flow.tcl]
