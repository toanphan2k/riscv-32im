# Arithmetic PPA Statistics

Post-route results for the active implementation in each category:

- **Adder:** `cla_32bit`
- **Multiplier:** `verdic_32bit_multiplier_seq`
- **Divider:** `radix2_res_divider`

| Parameter | Adder (`cla_32bit`) | Multiplier (`verdic_32bit_multiplier_seq`) | Divider (`radix2_res_divider`) |
|---|---:|---:|---:|
| Slice LUTs | 103 | 287 | 375 |
| Slice registers (FF) | 0 | 105 | 139 |
| DSPs | 0 | 4 | 0 |
| Critical data path (ns) | 6.073 | 6.001 | 6.642 |
| Estimated Fmax (MHz) | 163.99 | 165.54 | 149.63 |
| Latency | Combinational (1-cycle budget) | 1 cycle | 32 iteration cycles |
| Throughput | 1 operation/cycle | 1 operation/2 cycles | 1 operation/34 cycles |
| Estimated dynamic power (mW) | 1 | 11 | 2 |
| Estimated device static power (mW) | 84 | 84 | 84 |

The divider's 34-cycle throughput interval includes the 32 divide iterations and the FSM's start/complete transitions. Latency counts from an accepted `start` to `done`.

## Results by implementation

These are the reported post-route resource and timing results for every module with completed reports. Power is Vivado's vectorless estimate; see the caveats below.

### Adders

| Module | LUTs | FFs | DSPs | Critical path (ns) | Estimated Fmax (MHz) | Latency | Throughput | Dynamic power (mW) | Static power (mW) |
|---|---:|---:|---:|---:|---:|---|---|---:|---:|
| `cla_32bit` | 103 | 0 | 0 | 6.073 | 163.99 | Combinational | 1 operation/cycle | 1 | 84 |
| `rca_32bit` | 56 | 0 | 0 | 9.639 | 103.48 | Combinational | 1 operation/cycle | 0 | 84 |
| `simple_32bit_adder` | 40 | 0 | 0 | 4.937 | 201.53 | Combinational | 1 operation/cycle | 0 | 84 |

### Multipliers

| Module | LUTs | FFs | DSPs | Critical path (ns) | Estimated Fmax (MHz) | Latency | Throughput | Dynamic power (mW) | Static power (mW) |
|---|---:|---:|---:|---:|---:|---|---|---:|---:|
| `simple_multiplier` | 112 | 0 | 4 | 8.918 | 111.82 | Combinational | 1 operation/cycle | 5 | 84 |
| `verdic_32bit_multiplier` | 231 | 0 | 4 | 8.787 | 113.48 | Combinational | 1 operation/cycle | 10 | 84 |
| `verdic_32bit_multiplier_seq` | 287 | 105 | 4 | 6.001 | 165.54 | 1 cycle | 1 operation/2 cycles | 11 | 84 |

### Dividers

| Module | LUTs | FFs | DSPs | Critical path (ns) | Estimated Fmax (MHz) | Latency | Throughput | Dynamic power (mW) | Static power (mW) |
|---|---:|---:|---:|---:|---:|---|---|---:|---:|
| `radix2_nonres_divider` | 360 | 140 | 0 | 7.336 | 135.63 | 32 iterations | 1 operation/34 cycles | 3 | 84 |
| `radix2_res_divider` | 375 | 139 | 0 | 6.642 | 149.63 | 32 iterations | 1 operation/34 cycles | 2 | 84 |
| `radix4_divider_comb` | 3774 | 0 | 0 | 65.717 | 15.21 | Combinational (unrolled) | 1 operation/cycle | 84 | 84 |
| `radix4_res_divider` | 521 | 138 | 0 | 8.250 | 120.66 | 16 iterations | 1 operation/18 cycles | 4 | 84 |
| `radix4_srt_divider` | 1007 | 184 | 0 | 12.403 | 80.38 | 16-32 iterations | 1 operation/18-34 cycles | 11 | 84 |
| `simple_divider` | 4753 | 0 | 0 | 75.227 | 13.29 | Combinational | 1 operation/cycle | 104 | 84 |

## Method and caveats

- Device: `xc7a100tcsg324-3`; Vivado 2022.2; post-route reports.
- The critical data path is the setup path's reported `Data Path Delay`. Fmax is copied from each module's `fmax.rpt` and is an estimate based on the 10 ns benchmark constraint and timing slack.
- The adder is combinational, so its latency is not inherently one clock cycle; the table's one-cycle budget assumes the logic fits within a system clock period. Its Fmax is based on the benchmark's virtual clock.
- Combinational multiplier/divider throughput is one operation per cycle if the surrounding system meets the reported Fmax; these blocks have no internal pipeline registers. Sequential multiplier/divider throughput reflects the current start/iterate/complete FSMs.
- Divider iteration and throughput figures assume ordinary nonzero divisors; divide-by-zero and signed-overflow cases can complete early. The radix-4 SRT iteration count varies with divisor normalization.
- Power is Vivado's vectorless estimate with medium confidence and no simulation activity file. Dynamic power depends on switching activity and should not be treated as measured workload power. Device static power is the same 84 mW baseline in these reports.
- Per-module reports are in [`./benchmarks/results/`](./benchmarks/results/), including `utilization_post_route.rpt`, `timing_post_route.rpt`, `fmax.rpt`, and `power.rpt`.
