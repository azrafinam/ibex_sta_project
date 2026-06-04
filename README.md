# End-to-End STA Parser Construction from Ibex RTL Source

**Design:** ibex_core (32-bit RISC-V CPU) — [lowRISC Ibex](https://github.com/lowRISC/ibex)  
**PDK:** sky130A (`sky130_fd_sc_hd`)  
**Tools:** sv2v v0.0.13 · Yosys 0.33 · OpenSTA 3.1.0 · Python 3.13  
**Clock period:** 20 ns  


## Repository structure

```
ibex_sta_project/
├── rtl/                              # Ibex SystemVerilog (from ~/Desktop/ibex-master/rtl)
│   ├── ibex_core.sv                  # Top-level core module
│   ├── ibex_*.sv                     # Pipeline, ALU, LSU, CSRs, fetch, etc.
│   └── ibex_core.f                   # Synthesis file list (subset for STA)
│
├── include/                          # LowRISC prim + DV headers (from ibex-master vendor)
│   ├── prim_*.sv / prim_*.svh        # Primitive cells, packages, assert macros
│   └── dv_*.svh                      # DV / coverage macro headers
│
├── synth/                            # sv2v + Yosys — all netlists live here (no netlist/)
│   ├── ibex_core.v                   # Verilog-2005 RTL after sv2v (-D SYNTHESIS)
│   ├── ibex_synth.v                  # SKY130 HD gate-level netlist (OpenSTA input)
│   └── synth.tcl                     # Yosys: proc → techmap → dfflibmap → abc
│
├── sta/                              # OpenSTA reports, constraints, parser tools
│   ├── ibex_tt.txt                   # TT corner report (tt_025C_1v80)
│   ├── ibex_ss.txt                   # SS corner report (ss_100C_1v60)
│   ├── constraints.sdc               # 20 ns clock, uncertainty, I/O delays
│   ├── run_sta_tt.tcl                # OpenSTA script — TT Liberty + ibex_synth.v
│   ├── run_sta_ss.tcl                # OpenSTA script — SS Liberty + ibex_synth.v
│   ├── run_sta.tcl                   # Generic template (edit LIB/NETLIST/TOP)
│   ├── sta_report_parser.py          # extract_summary, parse_paths, count_by_module
│   ├── verify_sta_parser.py          # Automated grep cross-check (7 checks)
│   └── parser_schema.md              # Return-type contract for parser functions
│
├── reports/                          # Markdown analysis and curriculum proof
│   ├── sta_findings.md               # Day 5 — 10-point submission table (ibex; GPU N/A)
│   ├── ibex_sta_tables.md            # Day 0/1/3 — ground truth, path annotation, validation
│   └── verification.md               # Day 0–5 check commands + captured outputs
│
├── logs/                             # Flow documentation and issue log
│   └── RTL_TO_STA_FLOW.md            # sv2v → Yosys → OpenSTA pipeline + fixes table
│
├── reproduce/                        # Rebuild flow from ~/Desktop/ibex-master
│   ├── REPRODUCE.md                  # Canonical step-by-step terminal commands
│   ├── setup_from_ibex.sh            # Auto-copy rtl, include, write Tcl/lists
│   ├── run_flow.sh                   # sv2v → Yosys → OpenSTA → .txt reports
│   ├── run_curriculum_checks.sh      # Re-run Day 0/3/4 acceptance checks
│   ├── sync_to_main.sh               # Copy artifacts from ~/Project_STA
│   ├── pkg_list.txt                  # sv2v package compile order
│   ├── rtl_list.txt                  # sv2v module list (no tracer/lockstep)
│   └── scripts/                      # Template synth.tcl + SDC + run_sta_*.tcl
│
└── README.md                         # This file — overview and quick reference
```

---

## RTL-to-STA Flow Overview

The complete end-to-end flow transforms SystemVerilog RTL into synthesized gate-level timing analysis reports:

1. **sv2v Conversion** — SystemVerilog sources (`rtl/*.sv`) are converted to Verilog-2005 with packages ordered and headers flattened into `include/`
2. **Yosys Synthesis** — Verilog RTL is elaborated and synthesized to SKY130 HD standard cells, producing gate-level netlist (`synth/ibex_synth.v`)
3. **Timing Constraints** — SDC file (`sta/constraints.sdc`) defines 20 ns clock, uncertainty, input/output delays, and driving cell characteristics
4. **OpenSTA Analysis** — Gate netlist analyzed at both TT (25°C, 1.80V) and SS (100°C, 1.60V) process corners
5. **Report Parsing** — Python parser (`sta/sta_report_parser.py`) extracts WNS, TNS, violations, and critical paths for structured analysis

**Key milestones encountered and resolved:** 10 issues spanning sv2v package ordering, DPI-C exports, synthesis flags, clock constraints, and library paths. See [logs/RTL_TO_STA_FLOW.md](logs/RTL_TO_STA_FLOW.md) for detailed methodology, phase-by-phase breakdowns, and the complete issues resolution table.

---

## Results summary

| Metric | TT (tt_025C_1v80) | SS (ss_100C_1v60) |
|:---|:---:|:---:|
| WNS (ns) | −8.65 | −37.66 |
| TNS (ns) | −3,846.05 | −31,690.22 |
| Violations | 4,486 | 7,458 |
| Paths parsed | 60 | 60 |
| Timing met | No | No |
| Critical module | gen_prefetch_buffer.prefetch_buffer_i | gen_prefetch_buffer.prefetch_buffer_i |
| WNS delta (SS − TT) | −29.01 ns | |

## Quick verification (curriculum checks)

```bash
cd ~/ibex_sta_project
bash reproduce/run_curriculum_checks.sh
```

Full command transcript and outputs: [reports/verification.md](reports/verification.md)

```bash
cd sta
python3 sta_report_parser.py ibex_tt.txt ibex_ss.txt
python3 verify_sta_parser.py ibex_tt.txt ibex_ss.txt   # expect: FINAL: 2/2 passed
```


## Reproduce STA reports from ibex-master

```bash
cd ~/ibex_sta_project
bash reproduce/setup_from_ibex.sh
bash reproduce/run_flow.sh
```

Details: [reproduce/REPRODUCE.md](reproduce/REPRODUCE.md)


## Documentation index

| Document | Purpose |
|:---|:---|
| [reports/sta_findings.md](reports/sta_findings.md) | Submission table (10 points) |
| [reports/ibex_sta_tables.md](reports/ibex_sta_tables.md) | Ground truth + format study + parser validation |
| [reports/verification.md](reports/verification.md) | Instruction checklist with proof outputs |
| [logs/RTL_TO_STA_FLOW.md](logs/RTL_TO_STA_FLOW.md) | RTL-to-STA methodology, pipeline phases, and resolved issues |
| [sta/parser_schema.md](sta/parser_schema.md) | Parser API contract |
| [reproduce/REPRODUCE.md](reproduce/REPRODUCE.md) | Exact reproduction commands |


## Deliverables

| File | Acceptance |
|:---|:---|
| `sta/ibex_tt.txt`, `sta/ibex_ss.txt` | Non-empty; WNS, TNS, Startpoint: lines |
| `sta/sta_report_parser.py` | 4 functions; matches grep ground truth |
| `sta/verify_sta_parser.py` | **2/2 ALL PASS** on ibex reports |
| `reports/sta_findings.md` | All 10 points (GPU columns N/A) |
| `reports/verification.md` | Check commands + outputs |


## Conclusion

The STA parser extracts and validates ibex_core timing from real sky130A synthesis reports. Both corners fail timing; the prefetch buffer dominates violations. SS WNS is 29.01 ns worse than TT. Standard cells and placement strategies are the primary levers for meeting timing in future iterations.
