# STA Findings — ibex_core

**Design:** ibex_core (sky130A, 20 ns clock)  
**Source:** `sta_report_parser.py` output on `ibex_tt.txt` and `ibex_ss.txt`  
**Scope:** ibex only — tiny-GPU not analyzed in this project.

---

## Submission Table

| # | Topic | Answer |
|:-:|:---|:---|
| 1 | **ibex_core TT corner — setup WNS and TNS** | WNS **-8.650 ns**, TNS **-3846.050 ns** |
| 2 | **ibex_core SS corner — setup WNS and TNS** | WNS **-37.660 ns**, TNS **-31690.220 ns** |
| 3 | **tiny-GPU TT corner — setup WNS and TNS** | **N/A** — tiny-GPU reports not in scope (ibex-only project) |
| 4 | **tiny-GPU SS corner — setup WNS and TNS** | **N/A** — tiny-GPU reports not in scope (ibex-only project) |
| 5 | **Which design has more violations — ibex or tiny-GPU?** | **N/A (comparison)** — ibex per-corner counts: TT **4486**, SS **7458**. tiny-GPU not analyzed. |
| 6 | **How much worse is SS vs TT for each design?** | **ibex:** WNS delta **-29.010 ns** (SS WNS − TT WNS: −37.660 − (−8.650)). **tiny-GPU:** **N/A** |
| 7 | **Which module has the most violations in ibex?** | **`gen_prefetch_buffer.prefetch_buffer_i`** — **30** violations (`count_by_module` on `ibex_tt.txt` parsed paths) |
| 8 | **Which module has the most violations in tiny-GPU?** | **N/A** — `gpu_tt.txt` not in scope (ibex-only project) |
| 9 | **Is either design timing-met at TT corner? At SS corner?** | **ibex @ TT:** **No** (WNS −8.650 ns). **ibex @ SS:** **No** (WNS −37.660 ns). **tiny-GPU @ TT:** **N/A**. **tiny-GPU @ SS:** **N/A**. |
| 10 | **One difference between ibex and GPU timing profiles** | **ibex-only observation:** Violations cluster in the instruction-fetch prefetch path (`gen_prefetch_buffer.prefetch_buffer_i` is the top module at TT with 30 of 60 reported paths; worst endpoint is `fifo_i/_1039_` at both corners). SS degrades WNS by 29.01 ns and adds 2,972 violations (4486 → 7458) vs TT, indicating strong PVT sensitivity in the fetch front-end rather than a single isolated path. |

---

## Parser Output

```
STA Report: ibex_tt
  Setup WNS:            -8.650 ns
  Setup TNS:          -3846.050 ns
  Setup violations:       4486
  Timing met:         False
  Total paths parsed:       60
  Worst endpoint:     if_stage_i/gen_prefetch_buffer.prefetch_buffer_i/fifo_i/_1039_
  Worst slack:          -8.650 ns
  Violations by module (top 5):
      30  gen_prefetch_buffer.prefetch_buffer_i
      18  mcycle_counter_i
       1  _2265_
       1  _2266_

STA Report: ibex_ss
  Setup WNS:           -37.660 ns
  Setup TNS:          -31690.220 ns
  Setup violations:       7458
  Timing met:         False
  Total paths parsed:       60
  Worst endpoint:     if_stage_i/gen_prefetch_buffer.prefetch_buffer_i/fifo_i/_1039_
  Worst slack:         -37.660 ns
  Violations by module (top 5):
      20  gen_prefetch_buffer.prefetch_buffer_i
      18  mcycle_counter_i
       1  _2265_
       1  _2266_
```
