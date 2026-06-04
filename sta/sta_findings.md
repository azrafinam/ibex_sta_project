# STA Findings — ibex_core

**Design:** ibex_core (sky130A, 20 ns clock)  
**Source:** `sta_report_parser.py` output on `ibex_tt.txt` and `ibex_ss.txt`  
**Scope:** ibex only — tiny-GPU not analyzed in this project.

---

## Submission Table


| #   | Topic                                                       | Answer                                                                                                                                                                                                                                                                                                                                                                                                          |
| --- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **ibex_core TT corner — setup WNS and TNS**                 | WNS **-9.040 ns**, TNS **-3743.600 ns**                                                                                                                                                                                                                                                                                                                                                                         |
| 2   | **ibex_core SS corner — setup WNS and TNS**                 | WNS **-38.350 ns**, TNS **-31456.900 ns**                                                                                                                                                                                                                                                                                                                                                                       |
| 3   | **tiny-GPU TT corner — setup WNS and TNS**                  | **N/A** — tiny-GPU reports not in scope (ibex-only project)                                                                                                                                                                                                                                                                                                                                                     |
| 4   | **tiny-GPU SS corner — setup WNS and TNS**                  | **N/A** — tiny-GPU reports not in scope (ibex-only project)                                                                                                                                                                                                                                                                                                                                                     |
| 5   | **Which design has more violations — ibex or tiny-GPU?**    | **N/A (comparison)** — ibex per-corner counts: TT **4366**, SS **7522**. tiny-GPU not analyzed.                                                                                                                                                                                                                                                                                                                 |
| 6   | **How much worse is SS vs TT for each design?**             | **ibex:** WNS delta **-29.310 ns** (SS WNS − TT WNS: −38.350 − (−9.040)). **tiny-GPU:** **N/A**                                                                                                                                                                                                                                                                                                                 |
| 7   | **Which module has the most violations in ibex?**           | `**gen_prefetch_buffer.prefetch_buffer_i**` — **27** violations (`count_by_module` on `ibex_tt.txt` parsed paths)                                                                                                                                                                                                                                                                                               |
| 8   | **Which module has the most violations in tiny-GPU?**       | **N/A** — `gpu_tt.txt` not in scope (ibex-only project)                                                                                                                                                                                                                                                                                                                                                         |
| 9   | **Is either design timing-met at TT corner? At SS corner?** | **ibex @ TT:** **No** (WNS −9.040 ns). **ibex @ SS:** **No** (WNS −38.350 ns). **tiny-GPU @ TT:** **N/A**. **tiny-GPU @ SS:** **N/A**.                                                                                                                                                                                                                                                                          |
| 10  | **One difference between ibex and GPU timing profiles**     | **ibex-only observation:** Violations cluster in the instruction-fetch prefetch path (`gen_prefetch_buffer.prefetch_buffer_i` is the top module at TT with 27 of 60 reported paths; worst endpoint is `fifo_i/_1039`_ at both corners). SS degrades WNS by 29.31 ns and adds 3,156 violations (4366 → 7522) vs TT, indicating strong PVT sensitivity in the fetch front-end rather than a single isolated path. |


---

## Parser Output

```
== STA Report: ibex_tt ==
  Setup WNS:            -9.040 ns
  Setup TNS:          -3743.600 ns
  Setup violations:       4366
  Timing met:         False
  Total paths parsed:       60
  Worst endpoint:     if_stage_i/gen_prefetch_buffer.prefetch_buffer_i/fifo_i/_1039_
  Worst slack:          -9.040 ns
  Violations by module (top 5):
      27  gen_prefetch_buffer.prefetch_buffer_i
      18  mcycle_counter_i
       2  controller_i
       1  _2333_
       1  _2334_


== STA Report: ibex_ss ==
  Setup WNS:           -38.350 ns
  Setup TNS:          -31456.900 ns
  Setup violations:       7522
  Timing met:         False
  Total paths parsed:       60
  Worst endpoint:     if_stage_i/gen_prefetch_buffer.prefetch_buffer_i/fifo_i/_1039_
  Worst slack:         -38.350 ns
  Violations by module (top 5):
      20  gen_prefetch_buffer.prefetch_buffer_i
      18  mcycle_counter_i
       1  _2333_
       1  _2334_

```

