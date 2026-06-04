# End-to-End STA Parser Construction from Ibex RTL Source

**Design:** ibex_core (32-bit RISC-V CPU)  ( https://github.com/lowRISC/ibex# )

**PDK:** sky130A  
**Tool:** OpenSTA 2.4 (in Docker) + OpenLane  
**Clock Period:** 20 ns  

## Repository Structure

ibex_sta_project/
├── README.md
├── include/
│   ├── dv_*.svh
│   └── prim_*.sv
├── rtl/
│   ├── ibex_*.sv
│   └── ibex_core.f
├── sta/
│   ├── constraints.sdc
│   ├── ibex_ss.txt
│   ├── ibex_sta_tables.md
│   ├── ibex_tt.txt
│   ├── parser_schema.md
│   ├── run_sta.tcl
│   ├── run_sta_ss.tcl
│   ├── run_sta_tt.tcl
│   ├── sta_report_parser.py
│   └── verify_sta_parser.py
└── synth/
    ├── ibex_core.v
    ├── ibex_synth.v
    └── synth.tcl

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
