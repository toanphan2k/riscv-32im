if {[current_project -quiet] ne ""} {
    error "Run this benchmark from a fresh Vivado Tcl session without an open project."
}

set output_dir [file join $repo_root benchmarks results $benchmark_module]
file mkdir $output_dir

read_verilog -sv $rtl_sources
read_verilog -sv $top_file
read_xdc $constraints_file

synth_design \
    -top $benchmark_top \
    -part xc7a100tcsg324-3 \
    -mode out_of_context

report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary -file [file join $output_dir timing.rpt]

opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $output_dir utilization_post_route.rpt]
report_timing_summary -file [file join $output_dir timing_post_route.rpt]
report_timing \
    -delay_type max \
    -max_paths 1 \
    -nworst 1 \
    -file [file join $output_dir critical_path.rpt]
report_power -file [file join $output_dir power.rpt]

set critical_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set fmax_file [open [file join $output_dir fmax.rpt] w]
if {[llength $critical_path] == 0} {
    puts $fmax_file "Estimated FMAX: unavailable (no constrained timing paths)."
} else {
    set slack_ns [get_property SLACK $critical_path]
    set critical_period_ns [expr {10.0 - $slack_ns}]
    if {$critical_period_ns > 0.0} {
        set fmax_mhz [expr {1000.0 / $critical_period_ns}]
        puts $fmax_file [format "Estimated FMAX: %.2f MHz" $fmax_mhz]
        puts $fmax_file [format "Critical period: %.3f ns" $critical_period_ns]
    } else {
        puts $fmax_file "Estimated FMAX: unavailable (invalid critical period)."
    }
}
close $fmax_file
