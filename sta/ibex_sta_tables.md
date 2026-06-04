# Static Timing Analysis (STA) Parser — Timing Tables

This document contains the ground truth tables, annotated timing paths, format study Q&As, and parser validation comparisons for the **ibex_core** design. As requested, tiny-GPU data is omitted.

---

## Day 0 — Ground Truth Table

Below is the baseline ground truth metrics obtained by executing direct `grep` and system utility commands on the raw OpenSTA reports (`ibex_tt.txt` and `ibex_ss.txt`).

| Metric | Command | ibex TT (Typical-Typical) | ibex SS (Slow-Slow) |
| :--- | :--- | :--- | :--- |
| **Setup WNS** | `grep 'wns' <file>` | `wns max -9.04` | `wns max -38.35` |
| **Setup TNS** | `grep 'tns' <file>` | `tns max -3743.60` | `tns max -31456.90` |
| **Path Count** | `grep -c 'Startpoint:' <file>` | `60` | `60` |
| **Violated Paths** | `grep -c 'VIOLATED' <file>` | `4366` | `7522` |
| **Worst Endpoint** | `grep 'Endpoint:' <file> \| head -1` | `Endpoint: cs_registers_i/_2333_ (recovery check against rising-edge clock clk_i)` | `Endpoint: cs_registers_i/_2333_ (recovery check against rising-edge clock clk_i)` |
| **SS WNS worse than TT?** | *Manual comparison* | **Yes** (`-38.35 ns` < `-9.04 ns`) | **Yes** (`-38.35 ns` < `-9.04 ns`) |

---

## Day 1 — Study Report Format

### 1. Print and Annotate First Timing Path (from `ibex_tt.txt`)

Here is the first complete path block extracted from `ibex_tt.txt`, annotated line-by-line:

```text
Startpoint: rst_ni (input port clocked by clk_i)
  --> [Startpoint line]: Identifies the launching element (input port rst_ni) and its clock reference.
  
Endpoint: cs_registers_i/_2333_ (recovery check against rising-edge clock clk_i)
  --> [Endpoint line]: Identifies the capturing register pin and check type (asynchronous recovery).
  
Path Group: asynchronous
  --> [Path Group line]: Indicates the timing path group classification.
  
Path Type: max
  --> [Path Type line]: Specifies that this is a setup/max delay timing check.
  
    Cap    Slew   Delay    Time   Description
  --> [Header line]: Table columns showing capacitance (pF), transition slew (ns), incremental delay, cumulative time, and item description.
  
-----------------------------------------------------------------------
           0.00    0.00    0.00   clock clk_i (rise edge)
  --> [Launch clock edge]: The source clock trigger edge.
  
                   0.00    0.00   clock network delay (ideal)
  --> [Clock network delay]: Delay through the clock tree network (currently ideal/zero).
  
                   0.00    0.00 ^ input external delay
  --> [Input external delay]: The constraint delay outside the chip boundary.
  
   2.58   20.72   14.56   14.56 ^ rst_ni (in)
  --> [Input Port line]: Shows external capacitance (2.58 pF), transition slew (20.72 ns), external propagation delay (14.56 ns), and cumulative launch time (14.56 ns).
  
          20.72    0.00   14.56 ^ cs_registers_i/_2333_/RESET_B (sky130_fd_sc_hd__dfrtp_1)
  --> [Cell Pin line]: Connection to the destination register's RESET_B pin. Cumulative delay is 14.56 ns.
  
                          14.56   data arrival time
  --> [Data Arrival Time line]: The total calculated delay for the signal path to arrive.
  
           0.00   20.00   20.00   clock clk_i (rise edge)
  --> [Capture clock edge]: The target clock trigger edge (one clock period later at 20.00 ns).
  
                   0.00   20.00   clock network delay (ideal)
  --> [Capture clock network delay]: Ideal network delay for the capture clock path.
  
                  -0.25   19.75   clock uncertainty
  --> [Clock Uncertainty line]: Margin for clock jitter/skew, subtracted from capture clock path.
  
                   0.00   19.75   clock reconvergence pessimism
  --> [Clock Reconvergence Pessimism (CRPR)]: Reconvergence credit adjustment.
  
                          19.75 ^ cs_registers_i/_2333_/CLK (sky130_fd_sc_hd__dfrtp_1)
  --> [Capture Clock pin line]: Clock arriving at the capture register's CLK pin.
  
                  -5.38   14.37   library recovery time
  --> [Library Recovery Time line]: Cell physical constraint for recovery check, subtracted to get data required time.
  
                          14.37   data required time
  --> [Data Required Time line]: The latest time by which the data signal must arrive.
  
-----------------------------------------------------------------------
                          14.37   data required time
                         -14.56   data arrival time
-----------------------------------------------------------------------
                          -0.19   slack (VIOLATED)
  --> [Slack line]: Calculated slack (Required Time - Arrival Time = 14.37 - 14.56 = -0.19 ns). Since it is negative, it is flagged as (VIOLATED).
```

### 2. Format Study Q&A Table

| Question | ibex answer |
| :--- | :--- |
| **Startpoint: line starts with exactly...** | `Startpoint:` |
| **Endpoint: line starts with exactly...** | `Endpoint:` |
| **Slack line contains the word...** | `slack` (e.g. `slack (VIOLATED)` or `slack (MET)`) |
| **VIOLATED appears on the slack line — yes/no** | `yes` (if timing is violated) |
| **WNS value appears after the keyword 'wns'** | `yes` (e.g. `wns max -9.04`) |

---

## Day 3 — Parser Validation Comparison Table

This table verifies that the output generated by the timing parser script (`sta_report_parser.py`) matches the baseline `grep` calculations on the generated reports.

| Metric | ibex TT | ibex SS | Match? (yes/no) |
| :--- | :---: | :---: | :---: |
| **setup_wns (from parser)** | `-9.040` | `-38.350` | **yes** |
| **setup_wns (from grep)** | `-9.04` | `-38.35` | **yes** |
| **setup_violations (from parser)** | `4366` | `7522` | **yes** |
| **VIOLATED count (from grep)** | `4366` | `7522` | **yes** |
| **Path count (from parser)** | `60` | `60` | **yes** |
| **Startpoint: count (from grep)** | `60` | `60` | **yes** |
| **Top violation module** | `gen_prefetch_buffer.prefetch_buffer_i` | `gen_prefetch_buffer.prefetch_buffer_i` | **yes** |
