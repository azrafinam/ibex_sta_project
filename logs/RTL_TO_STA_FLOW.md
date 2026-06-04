# Ibex Core — RTL to STA Flow Report

**Design:** ibex_core (RV32IMC RISC-V CPU)  
**PDK:** sky130A — `sky130_fd_sc_hd` standard cells  
**Tools:** sv2v v0.0.13 · Yosys 0.33 · OpenSTA 3.1.0 · Python 3.13  
**Clock target:** 20 ns (50 MHz)


## 1. Objective

Prepare the lowRISC Ibex core for Static Timing Analysis by:

1. Converting SystemVerilog RTL to synthesizable Verilog-2005
2. Synthesizing to a SKY130 HD gate-level netlist with Yosys
3. Running OpenSTA at TT and SS corners to produce parser-ready report files


## 2. End-to-End Pipeline
This document details the automated synthesis and Static Timing Analysis (STA) pipeline for the Ibex RISC-V core. It tracks the transformation of SystemVerilog design sources into a gate-level netlist, culminating in a multi-corner timing validation using the SkyWater 130nm HD (High Density) standard cell library.
```
        +-----------------------------------------+
        |        SystemVerilog Source RTL         |
        |  (rtl/*.sv  +  include/ primitive cores)|
        +-----------------------------------------+
                             |
                             |  sv2v (v0.0.13)
                             v
        +-----------------------------------------+
        |           synth/ibex_core.v             |  <--- Verilog-2005 Format
        |         (381 KB, 25 modules)            |
        +-----------------------------------------+
                             |
                             |  Yosys (v0.33) -> synth.tcl
                             v
        +-----------------------------------------+
        |          synth/ibex_synth.v             |  <--- Gate-Level Netlist
        |       (1.5 MB, Sky130 HD cells)         |
        +-----------------------------------------+
                             |
              +--------------+--------------+
              |                             |
              v (OpenSTA v3.1.0)            v (OpenSTA v3.1.0)
      Typical-Typical Corner         Slow-Slow Corner
       [ tt_025C_1v80 .lib ]         [ ss_100C_1v60 .lib ]
      Constraints: SDC (20ns)       Constraints: SDC (20ns)
              |                             |
              v                             v
        +-------------------+         +-------------------+
        |  sta/ibex_tt.txt  |         |  sta/ibex_ss.txt  |
        +-------------------+         +-------------------+
              |                             |
              +--------------+--------------+
                             |
                             |  sta_report_parser.py
                             v
        +-----------------------------------------+
        |      Structured Metrics Dashboard       |
        |   (WNS, TNS, Violations by Module)      |
        +-----------------------------------------+
```


## 3. Phase 1 — Project Layout and RTL Collection

### 3.1 Directory structure

```
ibex_sta_project/
├── rtl/          Ibex SystemVerilog sources (30 .sv files)
├── include/      Flattened LowRISC primitive + DV headers (~199 files)
├── synth/        Converted Verilog + Yosys script + gate netlist
└── sta/          SDC, OpenSTA Tcl scripts, timing reports, parser
```

### 3.2 RTL sources (`rtl/`)

Ibex core modules were copied from the upstream Ibex repository. The synthesis-relevant subset is listed in `rtl/ibex_core.f` (17 modules ending at `ibex_core.sv`). Additional wrapper and debug files remain in `rtl/` but are excluded from conversion:

| Excluded file | Reason |
|:---|:---|
| `ibex_tracer.sv` | Simulation trace module; parse errors in sv2v |
| `ibex_top_tracing.sv` | RVFI formal/debug wrapper |
| `ibex_lockstep.sv` | Lockstep verification wrapper |

### 3.3 Include dependency setup (`include/`)

Ibex depends on LowRISC `prim_*` packages and verification macros not present in `rtl/` alone. All required headers were flattened into `include/`:

```bash
find <ibex-repo>/vendor/lowrisc_ip/ip/prim/rtl         -name "*.sv"  -exec cp {} include/ \;
find <ibex-repo>/vendor/lowrisc_ip/ip/prim/rtl         -name "*.svh" -exec cp {} include/ \;
find <ibex-repo>/vendor/lowrisc_ip/ip/prim_generic/rtl  -name "*.sv"  -exec cp {} include/ \;
find <ibex-repo>/vendor/lowrisc_ip/ip/prim_generic/rtl  -name "*.svh" -exec cp {} include/ \;
find <ibex-repo>/vendor/lowrisc_ip/dv/sv/dv_utils      -name "*.svh" -exec cp {} include/ \;
```

Key dependencies resolved: `prim_assert*.svh`, `dv_fcov_macros.svh`, and all `prim_*` package sources.


## 4. Phase 2 — SystemVerilog to Verilog (sv2v)

### 4.1 Tool

```bash
~/sta_ibex_work/sv2v-Linux/sv2v --version
# sv2v v0.0.13
```

### 4.2 Package ordering

sv2v requires packages before the modules that import them. Packages were listed first in a dedicated file list:

```
include/prim_util_pkg.sv
include/prim_secded_pkg.sv
include/prim_mubi_pkg.sv
include/prim_esc_pkg.sv
include/prim_cipher_pkg.sv
include/prim_pad_wrapper_pkg.sv
include/prim_subreg_pkg.sv
include/prim_count_pkg.sv
include/prim_ram_1p_pkg.sv
rtl/ibex_pkg.sv
```

### 4.3 Curated RTL file list

Verification-only modules were filtered out before conversion:

```bash
ls rtl/*.sv \
  | grep -v tracer \
  | grep -v ibex_top_tracing \
  | grep -v ibex_lockstep \
  > rtl_list.txt
```

### 4.4 Conversion command

```bash
~/sta_ibex_work/sv2v-Linux/sv2v \
  -D SYNTHESIS \
  -I include \
  $(cat pkg_list.txt) \
  $(cat rtl_list.txt) \
  > synth/ibex_core.v
```

**Important:** Redirect stdout only (`> synth/ibex_core.v`). Do not use `2>&1` — stderr must stay on the terminal so error text is not written into the Verilog output.

### 4.5 Output verification

| Metric | Result |
|:---|:---|
| Output | `synth/ibex_core.v` |
| Size | 381 KB |
| Lines | 11,169 |
| Modules | 25 |
| Top module | `ibex_core` |

### 4.6 Post-conversion cleanup

sv2v converted DPI-C scramble helpers into inline stub functions (returning zero). Any remaining non-synthesizable `export "DPI-C"` lines were removed so Yosys could parse the design. After cleanup, `grep 'DPI-C' synth/ibex_core.v` returns no matches.


## 5. Phase 3 — Yosys Gate-Level Synthesis

### 5.1 Inputs

| Item | Path |
|:---|:---|
| RTL netlist | `synth/ibex_core.v` |
| Liberty (TT) | `~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib` |
| Top module | `ibex_core` |

### 5.2 Synthesis script (`synth/synth.tcl`)

```tcl
read_liberty -lib .../sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog ibex_core.v
hierarchy -top ibex_core
proc; opt; fsm; opt; memory; opt
techmap; opt
dfflibmap -liberty .../sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty .../sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog ibex_synth.v
```

### 5.3 Execution

```bash
cd synth
yosys -s synth.tcl
```

The `-s` flag is required — without it Yosys treats the file as raw Tcl and commands like `read_liberty` fail.

### 5.4 Output

| Metric | Result |
|:---|:---|
| Output | `synth/ibex_synth.v` |
| Size | 1.5 MB |
| Lines | 75,356 |
| Cell library | SKY130 HD (`sky130_fd_sc_hd__*`) |
| Exit status | 0 (clean) |


## 6. Phase 4 — Timing Constraints (`sta/constraints.sdc`)

A full SDC file was written before STA so OpenSTA could build a valid timing graph:

```tcl
current_design ibex_core
create_clock -name clk_i -period 20 [get_ports clk_i]
set_clock_uncertainty 0.25 [get_clocks clk_i]
set_input_delay 0 -clock clk_i [get_ports -filter "direction == input && name != clk_i"]
set_output_delay 0 -clock clk_i [all_outputs]
set_load 0.0334 [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_1 -pin Y \
  [get_ports -filter "direction == input && name != clk_i"]
```

Without `create_clock`, OpenSTA reports WNS = 0.00 and produces no meaningful Startpoint/Endpoint paths.


## 7. Phase 5 — OpenSTA and Report Generation

### 7.1 Corner scripts

Two Tcl scripts differ only in the Liberty corner:

| Script | Liberty corner | Output report |
|:---|:---|:---|
| `sta/run_sta_tt.tcl` | `sky130_fd_sc_hd__tt_025C_1v80.lib` (25°C, 1.80 V) | `sta/ibex_tt.txt` |
| `sta/run_sta_ss.tcl` | `sky130_fd_sc_hd__ss_100C_1v60.lib` (100°C, 1.60 V) | `sta/ibex_ss.txt` |

Each script:

1. Reads the corner-specific `.lib`
2. Reads `../synth/ibex_synth.v`
3. Links design `ibex_core`
4. Applies `constraints.sdc`
5. Reports WNS, TNS, setup/hold paths, clock skew, and slew/cap violators

### 7.2 Execution

```bash
cd sta
opensta -no_init < run_sta_tt.tcl > ibex_tt.txt 2>&1
opensta -no_init < run_sta_ss.tcl > ibex_ss.txt 2>&1
```

### 7.3 Timing results

| Metric | TT (`ibex_tt.txt`) | SS (`ibex_ss.txt`) |
|:---|:---:|:---:|
| Setup WNS | −8.65 ns | −37.66 ns |
| Setup TNS | −3846.05 ns | −31690.22 ns |
| Violations | 4486 | 7458 |
| Timing met | No | No |
| Worst module | `gen_prefetch_buffer.prefetch_buffer_i` | `gen_prefetch_buffer.prefetch_buffer_i` |

### 7.4 Parser validation

```bash
cd sta
python3 verify_sta_parser.py ibex_tt.txt ibex_ss.txt
# FINAL: 2/2 passed
```

Structured findings are documented in `reports/sta_findings.md`.


## 8. Issues Encountered and Resolutions

All blockers below were resolved during initial setup. They are recorded here for reproducibility.

| # | Phase | Symptom | Root cause | Resolution |
|:---:|:---|:---|:---|:---|
| 1 | sv2v | `Could not find file "prim_assert.sv"` | LowRISC primitives not in include path | Copied `prim/rtl` and `prim_generic/rtl` into `include/` |
| 2 | sv2v | `prim_assert_standard_macros.svh not found` | `.svh` headers not collected | Added `find ... -name "*.svh"` copies from prim and dv_utils |
| 3 | sv2v | `could not find package "prim_secded_pkg"` | Packages not compiled before RTL | Created ordered `pkg_list.txt`; packages listed first |
| 4 | sv2v | `could not find package "prim_ram_1p_pkg"` | Package lives in `prim_generic/rtl` | Added to `pkg_list.txt` after copying prim_generic sources |
| 5 | sv2v | Unknown RVFI bindings (`rvfi_valid`, …) | Tracing/lockstep wrappers reference formal ports | Excluded `ibex_tracer.sv`, `ibex_top_tracing.sv`, `ibex_lockstep.sv` |
| 6 | sv2v | Error text inside `ibex_core.v` | Used `> file 2>&1` redirect | Redirect stdout only; keep stderr on terminal |
| 7 | sv2v / OpenSTA | `syntax error` in netlist; `ibex_core is not a verilog module` | Missing `-D SYNTHESIS`; `$display` block in `ibex_controller.sv` survived into netlist as `$write` | Add `-D SYNTHESIS` to sv2v command |
| 8 | Yosys | `invalid command name "read_liberty"` | Ran `yosys synth.tcl` without `-s` | Use `yosys -s synth.tcl` |
| 9 | Yosys | `syntax error, unexpected TOK_STRING` near DPI-C exports | DPI-C is simulation-only, non-synthesizable | Removed/stubbed DPI-C exports; sv2v left zero-return stub functions |
| 10 | OpenSTA | WNS = 0.00, no timing paths | No clock constraint | Added `create_clock` and full SDC in `constraints.sdc` |
| 11 | OpenSTA | Liberty file not found | Incorrect or unset library path | Set absolute path to `~/.ciel/sky130A/libs.ref/.../*.lib` in Tcl scripts |


## 9. Key Design Decisions

1. **Curated file lists over wildcards** — Excluding verification wrappers prevents RVFI binding failures and keeps the netlist synthesis-only.
2. **Flattened include directory** — A single `-I include` path is simpler and more reliable than nested vendor paths for sv2v.
3. **One gate netlist, two STA corners** — `ibex_synth.v` is synthesized once at TT; SS analysis reuses the same netlist with the SS Liberty file (standard practice for corner comparison).
4. **20 ns clock period** — Chosen as a realistic exploration target; both corners fail timing, confirming the flow captures real violations.


## 10. Artifact Summary

| Stage | Input | Output | Tool |
|:---|:---|:---|:---|
| Dependency setup | Ibex vendor tree | `include/` (199 files) | manual copy |
| SV → Verilog | `rtl/*.sv` + `include/*` | `synth/ibex_core.v` | sv2v v0.0.13 |
| Synthesis | `synth/ibex_core.v` + TT `.lib` | `synth/ibex_synth.v` | Yosys 0.33 |
| Constraints | Design ports | `sta/constraints.sdc` | manual SDC |
| STA (TT) | `ibex_synth.v` + TT `.lib` + SDC | `sta/ibex_tt.txt` | OpenSTA 3.1.0 |
| STA (SS) | `ibex_synth.v` + SS `.lib` + SDC | `sta/ibex_ss.txt` | OpenSTA 3.1.0 |
| Parse | `ibex_tt.txt`, `ibex_ss.txt` | WNS/TNS/violations | `sta_report_parser.py` |


## 11. Conclusion

The Ibex core was converted from SystemVerilog to Verilog, synthesized to SKY130 HD standard cells, and analyzed with OpenSTA at TT and SS corners. The resulting report files (`ibex_tt.txt`, `ibex_ss.txt`) contain WNS, TNS, detailed timing paths, and violation data consumed by the STA parser. The design does not meet timing at either corner; the instruction-fetch prefetch buffer is the dominant violation source and the primary optimization target.
