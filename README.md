# STA Parser Creation, Starting from ibex rtl file, by: ** Azraf Inam Nafee  
**Design:** ibex_core (32-bit RISC-V CPU)  
**PDK:** sky130A  
**Tool:** OpenSTA 2.4 (in Docker) + OpenLane  
**Clock Period:** 20 ns  

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
