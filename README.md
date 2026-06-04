# End-to-End STA Parser Construction from Ibex RTL Source

**Design:** ibex_core (32-bit RISC-V CPU)  ( https://github.com/lowRISC/ibex# )

**PDK:** sky130A  
**Tool:** OpenSTA 2.4 (in Docker) + OpenLane  
**Clock Period:** 20 ns  

## Repository Structure

## Repository Structure

ibex_sta_project/
├── README.md                          # Project overview, results summary, and deliverables documentation
│
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
│   ├── parser_schema.md               # Function specifications: extract_summary(), parse_paths(), count_by_module(), print_summary()
│   ├── run_sta.tcl                    # Generic OpenSTA script template (read_liberty, read_verilog, link_design, read_sdc, report)
│   ├── run_sta_ss.tcl                 # OpenSTA script for Slow-Slow corner analysis with ss_100C_1v60 library
│   ├── run_sta_tt.tcl                 # OpenSTA script for Typical-Typical corner analysis with tt_025C_1v80 library
│   ├── sta_report_parser.py           # Python parser: regex-based extraction of WNS, TNS, paths, violations, module statistics from STA reports
│   └── verify_sta_parser.py           # Validation suite: 10 automated checks comparing parser output against grep baseline
│
└── synth/                             # Synthesis outputs and synthesis flow scripts (Yosys-based RTL-to-gates compilation on sky130_fd_sc_hd standard cells)
    ├── ibex_core.v                    # Gate-level netlist (ibex_core module only with sky130 standard cell instantiations)
    ├── ibex_synth.v                   # Complete flattened netlist including all hierarchical modules and standard cell definitions
    └── synth.tcl                      # Yosys synthesis automation script with design compilation, optimization, and netlisting directives

## Results Summary

| Metric | TT (tt_025C_1v80) | SS (ss_100C_1v60) |
|--------|-------------------|-------------------|
| WNS (ns) | -9.04 | -38.35 |
| TNS (ns) | -3,743.60 | -31,456.90 |
| Violations | 4,366 | 7,522 |
| Paths Analyzed | 60 | 60 |
| Timing Met | NO | NO |
| Critical Module | gen_prefetch_buffer.prefetch_buffer_i | gen_prefetch_buffer.prefetch_buffer_i |

## Parser Validation

✓ WNS extraction: PASS  
✓ TNS extraction: PASS  
✓ Violation counting: PASS  
✓ Path parsing (60 paths per corner): PASS  
✓ Module ranking: PASS  
✓ Verifier: 2/2 reports ALL PASS  

## Deliverables

- sta_report_parser.py — 4 functions (extract_summary, parse_paths, count_by_module, print_summary)
- verify_sta_parser.py — 10 automated checks
- ibex_tt.txt, ibex_ss.txt — Real STA reports (30+ paths each)
- parser_schema.md — Return type specifications
- This document

## Conclusion

The STA parser successfully extracts timing metrics from real synthesis reports of ibex_core on sky130A PDK. The design violates timing constraints at both corners, with the SS corner being the critical bottleneck (38 ns slack violation). The `gen_prefetch_buffer` module is the primary source of violations and should be optimized for faster closure.
