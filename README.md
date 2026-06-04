# End-to-End STA Parser Construction from Ibex RTL Source

**Design:** ibex_core (32-bit RISC-V CPU)  ( https://github.com/lowRISC/ibex# )

**PDK:** sky130A  
**Tool:** OpenSTA 2.4 (in Docker) + OpenLane  
**Clock Period:** 20 ns  

## Repository Structure

```
# ibex_sta_project

ibex_sta_project/
├── include/                           # Primitive library headers and utility includes (150+ files covering DV macros, CDC logic, cryptographic primitives, FIFOs, clocking, synchronization, memory models, and verification utilities used across the Ibex design)
│   ├── dv_*.svh                       # Design verification macros and functional coverage utilities
│   └── prim_*.sv                      # Low-level primitive cells, cryptographic cores, synchronizers, and system modules
│
├── rtl/                               # SystemVerilog RTL source files for ibex_core (30+ files implementing the 5-stage pipeline, ALU, CSRs, register files, instruction decoder, and system protection features)
│   ├── ibex_*.sv                      # Core processor modules: pipeline stages, ALU, LSU, controller, register files, caches, multiplier/divider
│   └── ibex_core.f                    # File manifest listing all RTL sources in compilation order
│
├── sta/                               # STA flow scripts, reports, parser tools, and validation (OpenSTA-based timing analysis on sky130A PDK)
│   ├── constraints.sdc                # Timing constraints: clock period (20ns), uncertainty (0.25ns), input/output delays, slew rates, and loads
│   ├── ibex_ss.txt                    # Slow-Slow STA report (ss_100C_1v60 corner: WNS = -38.35 ns, TNS = -31456.90 ns, 7522 violations)
│   ├── ibex_tt.txt                    # Typical-Typical STA report (tt_025C_1v80 corner: WNS = -9.04 ns, TNS = -3743.60 ns, 4366 violations)
│   ├── ibex_sta_tables.md             # Annotated timing path analysis with format documentation and parser validation tables
│   ├── sta_findings.md                # Comprehensive STA findings, critical path analysis, and remediation recommendations
│   ├── parser_schema.md               # Function specifications: extract_summary(), parse_paths(), count_by_module(), print_summary()
│   ├── run_sta.tcl                    # Generic OpenSTA script template
│   ├── run_sta_ss.tcl                 # OpenSTA script for Slow-Slow corner analysis
│   ├── run_sta_tt.tcl                 # OpenSTA script for Typical-Typical corner analysis
│   ├── sta_report_parser.py           # Python parser: regex-based extraction of STA metrics
│   └── verify_sta_parser.py           # Validation suite: compares parser output with reference grep results
│
├── synth/                             # Synthesis outputs and synthesis flow scripts (Yosys-based RTL-to-gates compilation on sky130_fd_sc_hd standard cells)
│   ├── ibex_core.v                    # Gate-level netlist (core only)
│   ├── ibex_synth.v                   # Full flattened netlist
│   └── synth.tcl                      # Yosys synthesis automation script
│
└── README.md                          # Project overview, results summary, and documentation entry point for the entire STA flow project
```
    
## Results Summary

| Metric | TT (tt_025C_1v80) | SS (ss_100C_1v60) |
|--------|-------------------|-------------------|
| WNS (ns) | -9.04 | -38.35 |
| TNS (ns) | -3,743.60 | -31,456.90 |
| Violations | 4,366 | 7,522 |
| Paths Analyzed | 60 | 60 |
| Timing Met | NO | NO |
| Critical Module | gen_prefetch_buffer.prefetch_buffer_i | gen_prefetch_buffer.prefetch_buffer_i |

## STA Findings & Analysis

### Timing Violations Overview

The ibex_core design exhibits significant timing violations across all process corners analyzed:

#### Slow-Slow (SS) Corner (ss_100C_1v60)
- **Worst Negative Slack (WNS):** -38.35 ns
- **Total Negative Slack (TNS):** -31,456.90 ns
- **Total Violations:** 7,522 paths
- **Severity:** Critical — design fails to meet 20 ns clock period by significant margin

#### Typical-Typical (TT) Corner (tt_025C_1v80)
- **Worst Negative Slack (WNS):** -9.04 ns
- **Total Negative Slack (TNS):** -3,743.60 ns
- **Total Violations:** 4,366 paths
- **Severity:** High — approximately 45% fewer violations than SS corner but still substantial

### Critical Path Analysis

Both process corners identify the **gen_prefetch_buffer.prefetch_buffer_i** module as the critical region:
- This submodule contributes the largest share of timing violations
- Paths through the prefetch buffer logic are on the critical path
- Potential root causes: deep combinational logic, high fan-out signals, or suboptimal placement/routing in synthesis

### Key Observations

1. **PVT Variation Impact:** The 29.31 ns difference in WNS between corners demonstrates significant process-voltage-temperature (PVT) sensitivity
2. **Systematic Violations:** 4,366+ violations at TT (mild corner) suggest fundamental design/implementation issues rather than marginal timing failures
3. **Clock Period Feasibility:** The 20 ns clock period may be too aggressive for the current sky130A technology node given the design complexity of ibex_core

### Parser Validation

The STA report parser successfully validates all findings:
- ✓ WNS extraction: PASS (verified against raw STA output)
- ✓ TNS extraction: PASS
- ✓ Violation counting: PASS
- ✓ Path parsing (60 paths per corner): PASS
- ✓ Module ranking: PASS
- ✓ Verifier: 2/2 reports ALL PASS

## Documentation

Comprehensive documentation is provided through the following markdown files:

- **[sta_findings.md](sta/sta_findings.md)** — Detailed STA findings, critical path analysis, bottleneck identification, and remediation strategies
- **[ibex_sta_tables.md](sta/ibex_sta_tables.md)** — Annotated timing path tables with raw STA metrics, path endpoint analysis, and parser validation reference data
- **[parser_schema.md](sta/parser_schema.md)** — API documentation for STA report parser functions with return types and usage examples
- **README.md** — This file; project overview and results summary

## Deliverables

- **sta_report_parser.py** — 4 functions (extract_summary, parse_paths, count_by_module, print_summary)
- **verify_sta_parser.py** — 10 automated checks
- **ibex_tt.txt, ibex_ss.txt** — Real STA reports (30+ paths each)
- **ibex_sta_tables.md** — Detailed path analysis and timing metrics
- **sta_findings.md** — Comprehensive STA analysis and recommendations
- **parser_schema.md** — Return type specifications and function documentation
- **constraints.sdc** — Timing constraints used for analysis
- Complete RTL and synthesis deliverables

## Conclusion

The STA parser successfully extracts and validates timing metrics from real synthesis reports of ibex_core on sky130A PDK. The design exhibits critical timing violations at both process corners, with the Slow-Slow corner being the most constrained. The prefetch_buffer submodule is identified as the primary bottleneck. Remediation strategies may include pipeline restructuring, critical path optimization, increased frequency margin (clock period relaxation), or cell-level optimizations in high-violation modules. Refer to [sta_findings.md](sta/sta_findings.md) for detailed analysis and recommendations.
