# Verification — ibex_sta_project

**Project:** ibex_core STA parser (sky130A, 20 ns clock)  
**Scope:** Ibex only — `gpu_tt.txt` / `gpu_ss.txt` not in scope (N/A per assignment)  
**Reports verified:** `sta/ibex_tt.txt`, `sta/ibex_ss.txt`  
**Date:** 2026-06-04  
**Result:** Parser and verifier **ALL PASS** on both ibex reports (2/2)

---



## Prerequisites — tool and Liberty check

**Commands:**

```bash
opensta -version
ls ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
ls ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib
test -f sta/ibex_tt.txt && test -f sta/ibex_ss.txt && echo "OK: report files present"
```

**Output:**

```
3.1.0
/home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
/home/stark/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib
OK: report files present
```

---

## Day 0 — Ground truth (pre-week acceptance criteria)

**Commands:**

```bash
cd ~/ibex_sta_project/sta

for corner in tt ss; do
  f="ibex_${corner}.txt"
  echo "--- $f ---"
  echo "Setup WNS:     $(grep '^wns' "$f")"
  echo "Setup TNS:     $(grep '^tns' "$f")"
  echo "Path count:    $(grep -c 'Startpoint:' "$f")"
  echo "VIOLATED:      $(grep -c 'VIOLATED' "$f")"
  echo "Worst endpoint (first): $(grep 'Endpoint:' "$f" | head -1)"
done

echo ""
echo "Sanity check (ibex reports only):"
for f in ibex_tt.txt ibex_ss.txt; do
  echo "$f: $(grep '^wns' "$f")"
done
```

**Output:**

```
--- ibex_tt.txt ---
Setup WNS:     wns max -8.65
Setup TNS:     tns max -3846.05
Path count:    60
VIOLATED:      4486
Worst endpoint (first): Endpoint: cs_registers_i/_2265_ (recovery check against rising-edge clock clk_i)
--- ibex_ss.txt ---
Setup WNS:     wns max -37.66
Setup TNS:     tns max -31690.22
Path count:    60
VIOLATED:      7458
Worst endpoint (first): Endpoint: cs_registers_i/_2265_ (recovery check against rising-edge clock clk_i)

Sanity check (ibex reports only):
ibex_tt.txt: wns max -8.65
ibex_ss.txt: wns max -37.66
```

### Day 0 ground truth table (filled)


| Metric                 | Command                        | ibex TT                  | ibex SS                 | GPU TT | GPU SS |
| ---------------------- | ------------------------------ | ------------------------ | ----------------------- | ------ | ------ |
| Setup WNS              | `grep '^wns' <file>`           | **−8.65**                | **−37.66**              | N/A    | N/A    |
| Setup TNS              | `grep '^tns' <file>`           | **−3846.05**             | **−31690.22**           | N/A    | N/A    |
| Path count             | `grep -c 'Startpoint:' <file>` | **60**                   | **60**                  | N/A    | N/A    |
| Violated paths         | `grep -c 'VIOLATED' <file>`    | **4486**                 | **7458**                | N/A    | N/A    |
| Worst endpoint (first) | `grep 'Endpoint:' | head -1`   | `cs_registers_i/_2265_`  | `cs_registers_i/_2265_` | N/A    | N/A    |
| SS WNS worse than TT?  | manual                         | **Yes** (−37.66 < −8.65) | —                       | N/A    | N/A    |


---

## Day 1 — Format study (first complete path)

**Commands:**

```bash
cd ~/ibex_sta_project/sta

python3 -c "
text=open('ibex_tt.txt').read()
import re
m=re.search(r'(Startpoint:.*?slack.*?\n)', text, re.DOTALL)
if m: print(m.group(1))
"

grep '^wns' ibex_tt.txt
grep '^tns' ibex_tt.txt
grep 'slack' ibex_tt.txt | head -3
```

**Output (first path block — excerpt):**

```
Startpoint: rst_ni (input port clocked by clk_i)
Endpoint: cs_registers_i/_2265_ (recovery check against rising-edge clock clk_i)
Path Group: asynchronous
Path Type: max
...
                          -0.19   slack (VIOLATED)

wns max -8.65
tns max -3846.05
                          -0.19   slack (VIOLATED)
                          -0.19   slack (VIOLATED)
                          -0.19   slack (VIOLATED)
```

### Day 1 format Q&A (ibex)


| Question                                | ibex answer           | GPU answer | Same format? |
| --------------------------------------- | --------------------- | ---------- | ------------ |
| Startpoint: line starts with exactly... | `Startpoint:`         | N/A        | —            |
| Endpoint: line starts with exactly...   | `Endpoint:`           | N/A        | —            |
| Slack line contains the word...         | `slack`               | N/A        | —            |
| VIOLATED on slack line — yes/no         | yes (when violated)   | N/A        | —            |
| WNS after keyword `wns`                 | yes — `wns max -8.65` | N/A        | —            |


**Schema contract:** [sta/parser_schema.md](../sta/parser_schema.md)

---

## Day 2 — Core parsing functions (spot checks)

**Commands:**

```bash
cd ~/ibex_sta_project/sta

python3 -c "from sta_report_parser import extract_summary; print(extract_summary('ibex_tt.txt'))"
grep '^wns' ibex_tt.txt
grep -c VIOLATED ibex_tt.txt

python3 -c "from sta_report_parser import parse_paths; p=parse_paths('ibex_tt.txt'); print('Paths:', len(p)); print('First:', p[0])"
grep -c 'Startpoint:' ibex_tt.txt
```

**Output:**

```
{'setup_wns': -8.65, 'setup_tns': -3846.05, 'hold_wns': 0.0, 'hold_tns': 0.0, 'setup_violations': 4486, 'hold_violations': 0, 'timing_met': False}
wns max -8.65
4486
Paths: 60
First: {'startpoint': 'rst_ni', 'endpoint': 'cs_registers_i/_2265_', 'path_type': 'setup', 'violated': True, 'slack': -0.19}
60
```

---

## Day 3 — Full parser + module ranking

**Commands:**

```bash
cd ~/ibex_sta_project/sta

python3 -c "from sta_report_parser import parse_paths, count_by_module; p=parse_paths('ibex_tt.txt'); print(count_by_module(p))"

python3 sta_report_parser.py ibex_tt.txt ibex_ss.txt

python3 -c "
from sta_report_parser import extract_summary, parse_paths
import subprocess, re

def grep_val(pat, f):
    r=subprocess.run(['grep', pat, f], capture_output=True, text=True)
    m=re.search(r'(-?\d+\.\d+)', r.stdout)
    return float(m.group(1)) if m else None

for f in ['ibex_tt.txt','ibex_ss.txt']:
    s=extract_summary(f)
    p=parse_paths(f)
    gw=grep_val('wns', f)
    gv=int(subprocess.run(['grep','-c','VIOLATED',f],capture_output=True,text=True).stdout.strip())
    gp=int(subprocess.run(['grep','-c','Startpoint:',f],capture_output=True,text=True).stdout.strip())
    print(f'{f}: WNS match={abs(s[\"setup_wns\"]-gw)<0.001}, viol match={s[\"setup_violations\"]==gv}, paths match={len(p)==gp}')
"
```

**Output:**

```
{'gen_prefetch_buffer.prefetch_buffer_i': 30, 'mcycle_counter_i': 18, '_2265_': 1, '_2266_': 1}

== STA Report: ibex_tt ==
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

== STA Report: ibex_ss ==
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

ibex_tt.txt: WNS match=True, viol match=True, paths match=True
ibex_ss.txt: WNS match=True, viol match=True, paths match=True
```

**Additional grep proof for module ranking:**

```bash
for f in ibex_tt.txt ibex_ss.txt; do
  echo "--- $f ---"
  grep -E '^(Endpoint:|[[:space:]]*-?[0-9]+\.[0-9]+[[:space:]]+slack \(VIOLATED\))' "$f" \
    | awk '
        /^Endpoint:/ {
          ep=$0
          sub(/^Endpoint: /, "", ep)
          sub(/ \(.*/, "", ep)
        }
        /slack \(VIOLATED\)/ {
          split(ep, parts, "/")
          mod = (length(parts) >= 2 ? parts[2] : parts[1])
          c[mod]++
        }
        END {
          for (m in c) print c[m], m
        }' \
    | sort -nr \
    | head -5
done
```

**Output:**

```
--- ibex_tt.txt ---
30 gen_prefetch_buffer.prefetch_buffer_i
18 mcycle_counter_i
1 _2266_
1 _2265_
--- ibex_ss.txt ---
20 gen_prefetch_buffer.prefetch_buffer_i
18 mcycle_counter_i
1 _2266_
1 _2265_
```

### Day 3 parser vs. grep table


| Metric               | ibex TT (parser)                             | ibex TT (grep) | Match? | ibex SS (parser) | ibex SS (grep) | Match? |
| -------------------- | -------------------------------------------- | -------------- | ------ | ---------------- | -------------- | ------ |
| setup_wns            | −8.650                                       | −8.65          | yes    | −37.660          | −37.66         | yes    |
| setup_violations     | 4486                                         | 4486           | yes    | 7458             | 7458           | yes    |
| path count           | 60                                           | 60             | yes    | 60               | 60             | yes    |
| Top violation module | `gen_prefetch_buffer.prefetch_buffer_i` (30) | same (30)      | yes    | same (20)        | same (20)      | yes    |


---

## Day 4 — Automated verifier

**Commands:**

```bash
cd ~/ibex_sta_project/sta
python3 verify_sta_parser.py ibex_tt.txt ibex_ss.txt
echo "Exit code: $?"
```

**Output:**

```
-- Verifying: ibex_tt.txt ---------
  [PASS] setup_wns is float
  [PASS] setup_wns matches grep
  [PASS] path count matches
  [PASS] VIOLATED count matches
  [PASS] all paths have fields
  [PASS] slack values valid
  [PASS] timing_met is bool
  [PASS] module counts match raw report

  RESULT: ALL PASS

-- Verifying: ibex_ss.txt ---------
  [PASS] setup_wns is float
  [PASS] setup_wns matches grep
  [PASS] path count matches
  [PASS] VIOLATED count matches
  [PASS] all paths have fields
  [PASS] slack values valid
  [PASS] timing_met is bool
  [PASS] module counts match raw report

  RESULT: ALL PASS

FINAL: 2/2 passed
Exit code: 0
```

### Verifier checks implemented (8 of 10)


| #   | Check                            | ibex_tt | ibex_ss |
| --- | -------------------------------- | ------- | ------- |
| 1   | setup_wns is float               | PASS    | PASS    |
| 2   | setup_wns matches grep           | PASS    | PASS    |
| 3   | path count matches Startpoint:   | PASS    | PASS    |
| 4   | VIOLATED count matches           | PASS    | PASS    |
| 5   | all paths have 5 required fields | PASS    | PASS    |
| 6   | slack values are float           | PASS    | PASS    |
| 7   | timing_met is bool               | PASS    | PASS    |
| 8   | module counts match raw report   | PASS    | PASS    |


*For details and timing_met False, setup_tns — check sta_findings.md*

---

## Day 5 — Submission proof

**Commands:**

```bash
cd ~/ibex_sta_project/sta
python3 verify_sta_parser.py ibex_tt.txt ibex_ss.txt
ls -lh ibex_tt.txt ibex_ss.txt
test -f ../reports/sta_findings.md && echo "OK: sta_findings.md present"
```

**Output:**

```
FINAL: 2/2 passed
-rw-rw-r-- 1 stark stark 729K ... ibex_tt.txt
-rw-rw-r-- 1 stark stark 969K ... ibex_ss.txt
OK: sta_findings.md present
```

**Team Submission target:**  `4/4 reports ALL PASS` → this project `**2/2 reports ALL PASS`** (ibex only).

Findings table: [sta_findings.md](sta_findings.md)

---

## Re-run all checks (one script)

```bash
cd ~/ibex_sta_project
bash reproduce/run_curriculum_checks.sh
```

---

## Sign-off


| Deliverable                | Status                           |
| -------------------------- | -------------------------------- |
| `sta/ibex_tt.txt`          | Present, WNS/TNS/paths valid     |
| `sta/ibex_ss.txt`          | Present, WNS/TNS/paths valid     |
| `sta/parser_schema.md`     | Present                          |
| `sta/sta_report_parser.py` | All 4 functions, runs clean      |
| `sta/verify_sta_parser.py` | 2/2 ALL PASS                     |
| `reports/sta_findings.md`  | 10 points filled (ibex; GPU N/A) |
| Parser matches Day 0 grep  | **Yes** for both corners         |
