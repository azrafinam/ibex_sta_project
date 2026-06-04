# Reproduce STA Reports from `~/Desktop/ibex-master`

Everything is copied automatically from the Ibex repo on the Desktop.  
One does not need `ibex_sta_project` — only this `reproduce/` folder (or these commands).

**Source repo (fixed):** `~/Desktop/ibex-master`  
**Output project:** `~/ibex_sta_project` (default when scripts run from this repo)  
**Alternate:** `~/Project_STA` — use `reproduce/sync_to_main.sh` to copy results back  
**Final reports:** `sta/ibex_tt.txt` and `sta/ibex_ss.txt`

---

## What gets copied from `ibex-master`

| From `~/Desktop/ibex-master` | Into `Project_STA` | Purpose |
|:---|:---|:---|
| `rtl/` | `rtl/` | Ibex core SystemVerilog |
| `vendor/lowrisc_ip/ip/prim/rtl/*.sv` | `include/` | LowRISC primitive modules |
| `vendor/lowrisc_ip/ip/prim/rtl/*.svh` | `include/` | Assertion / macro headers |
| `vendor/lowrisc_ip/ip/prim_generic/rtl/*` | `include/` | Generic RAM packages |
| `vendor/lowrisc_ip/dv/sv/dv_utils/*.svh` | `include/` | DV macro headers |

Nothing else from `ibex-master` is required (no `dv/`, `syn/`, `examples/`, etc.).

---

## Prerequisites

```bash
export IBEX_SRC=$HOME/Desktop/ibex-master
export PROJECT=$HOME/Project_STA
export SV2V=$HOME/sta_ibex_work/sv2v-Linux/sv2v
export SKY130_LIB=$HOME/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib
```

```bash
$SV2V --version
yosys -V
opensta -version
test -d $IBEX_SRC/rtl && test -d $IBEX_SRC/vendor/lowrisc_ip && echo "OK: ibex-master layout"
ls $SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib
ls $SKY130_LIB/sky130_fd_sc_hd__ss_100C_1v60.lib
```

---

## Quick path — two scripts

Copy the `reproduce/` folder anywhere, then:

```bash
chmod +x reproduce/setup_from_ibex.sh reproduce/run_flow.sh
reproduce/setup_from_ibex.sh
reproduce/run_flow.sh
```

Verify:

```bash
grep "^wns" $PROJECT/sta/ibex_tt.txt $PROJECT/sta/ibex_ss.txt
grep "^tns" $PROJECT/sta/ibex_tt.txt $PROJECT/sta/ibex_ss.txt
grep "Error:" $PROJECT/sta/ibex_tt.txt $PROJECT/sta/ibex_ss.txt && echo FAIL || echo OK
```

---

## Step-by-step (exact terminal lines)

### Step 0 — Paths

```bash
export IBEX_SRC=$HOME/Desktop/ibex-master
export PROJECT=$HOME/Project_STA
export SV2V=$HOME/sta_ibex_work/sv2v-Linux/sv2v
export SKY130_LIB=$HOME/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib
```

### Step 1 — Auto-copy from `ibex-master` + create scripts

```bash
bash reproduce/setup_from_ibex.sh
```

This creates:

```
Project_STA/
├── rtl/              ← cp -r ~/Desktop/ibex-master/rtl
├── include/          ← vendor prim + dv_utils from ibex-master
├── reproduce/
│   ├── pkg_list.txt
│   └── rtl_list.txt
├── synth/synth.tcl
└── sta/constraints.sdc, run_sta_tt.tcl, run_sta_ss.tcl
```

Verify:

```bash
ls $PROJECT/rtl/ibex_core.sv
ls $PROJECT/include/prim_assert.sv $PROJECT/include/prim_secded_pkg.sv
wc -l $PROJECT/reproduce/rtl_list.txt
grep -E "tracer|lockstep|top_tracing" $PROJECT/reproduce/rtl_list.txt && echo FAIL || echo OK
```

### Step 2 — sv2v → `synth/ibex_core.v`

**Required:** `-D SYNTHESIS` (strips `$display` in `ibex_controller.sv`).

```bash
cd $PROJECT
$SV2V \
  -D SYNTHESIS \
  -I include \
  $(cat reproduce/pkg_list.txt) \
  $(cat reproduce/rtl_list.txt) \
  > synth/ibex_core.v
```

Do not use `2>&1` on the redirect.

```bash
grep -En '\$display|\$write' synth/ibex_core.v && echo FAIL || echo OK
grep -q 'export "DPI-C"' synth/ibex_core.v && sed -i '/export "DPI-C"/d' synth/ibex_core.v || true
```

### Step 3 — Yosys → `synth/ibex_synth.v`

```bash
cd $PROJECT/synth
yosys -s synth.tcl
```

```bash
grep -En '\$display|\$write|always @\(negedge' ibex_synth.v && echo FAIL || echo OK
```

Use `yosys -s synth.tcl`, not `yosys synth.tcl`. Full ABC takes ~30 min on ibex_core.

### Step 4 — OpenSTA TT → `sta/ibex_tt.txt`

```bash
cd $PROJECT/sta
opensta -no_init < run_sta_tt.tcl > ibex_tt.txt 2>&1
```

```bash
grep "^wns" ibex_tt.txt
grep "^tns" ibex_tt.txt
grep "Error:" ibex_tt.txt && echo FAIL || echo OK
```

### Step 5 — OpenSTA SS → `sta/ibex_ss.txt`

```bash
cd $PROJECT/sta
opensta -no_init < run_sta_ss.tcl > ibex_ss.txt 2>&1
```

```bash
grep "^wns" ibex_ss.txt
grep "^tns" ibex_ss.txt
grep "Error:" ibex_ss.txt && echo FAIL || echo OK
```

Expected (matches current reports):

```
# ibex_tt.txt
wns max -8.65
tns max -3846.05

# ibex_ss.txt
wns max -37.66
tns max -31690.22
```

---

## Copy results from `Project_STA` → `ibex_sta_project`

If you ran the flow in `~/Project_STA` and want the artifacts in the main repo:

```bash
chmod +x ~/ibex_sta_project/reproduce/sync_to_main.sh
~/ibex_sta_project/reproduce/sync_to_main.sh
```

Or copy manually:

| Copy from (`~/Project_STA`) | Paste to (`~/ibex_sta_project`) | Why |
|:---|:---|:---|
| `sta/ibex_tt.txt` | `sta/ibex_tt.txt` | TT timing report |
| `sta/ibex_ss.txt` | `sta/ibex_ss.txt` | SS timing report |
| `sta/constraints.sdc` | `sta/constraints.sdc` | SDC used for STA |
| `sta/run_sta_tt.tcl` | `sta/run_sta_tt.tcl` | TT OpenSTA script |
| `sta/run_sta_ss.tcl` | `sta/run_sta_ss.tcl` | SS OpenSTA script |
| `synth/ibex_core.v` | `synth/ibex_core.v` | sv2v output |
| `synth/ibex_synth.v` | `synth/ibex_synth.v` | Yosys gate netlist |
| `synth/synth.tcl` | `synth/synth.tcl` | Yosys script |
| `reproduce/pkg_list.txt` | `reproduce/pkg_list.txt` | sv2v package order |
| `reproduce/rtl_list.txt` | `reproduce/rtl_list.txt` | sv2v module list |

**Do not copy** (already in main repo, same content):

| Skip | Reason |
|:---|:---|
| `rtl/` | already in `ibex_sta_project/rtl/` |
| `include/` | already in `ibex_sta_project/include/` |
| `reproduce/` | already in `ibex_sta_project/reproduce/` |

One-liner:

```bash
SRC=~/Project_STA DST=~/ibex_sta_project
cp $SRC/sta/ibex_tt.txt $SRC/sta/ibex_ss.txt $SRC/sta/constraints.sdc $SRC/sta/run_sta_tt.tcl $SRC/sta/run_sta_ss.tcl $DST/sta/
cp $SRC/synth/ibex_core.v $SRC/synth/ibex_synth.v $SRC/synth/synth.tcl $DST/synth/
cp $SRC/reproduce/pkg_list.txt $SRC/reproduce/rtl_list.txt $DST/reproduce/ 2>/dev/null || true
cd $DST/sta && python3 sta_report_parser.py ibex_tt.txt ibex_ss.txt
```

Your measured numbers after copy:

```
# ibex_tt.txt
wns max -8.65
tns max -3846.05

# ibex_ss.txt
wns max -37.66
tns max -31690.22
```

---

```
~/Desktop/ibex-master/          ← read-only source (never modified)
    rtl/
    vendor/lowrisc_ip/...

~/Project_STA/                  ← generated workspace
    rtl/
    include/
    reproduce/pkg_list.txt
    reproduce/rtl_list.txt
    reports/
    logs/
    synth/ibex_core.v
    synth/ibex_synth.v
    synth/synth.tcl
    sta/constraints.sdc
    sta/run_sta_tt.tcl
    sta/run_sta_ss.tcl
    sta/ibex_tt.txt
    sta/ibex_ss.txt
```

---

## Troubleshooting

| Symptom | Fix |
|:---|:---|
| `missing .../rtl` | Clone or unpack Ibex to `~/Desktop/ibex-master` |
| `missing vendor/lowrisc_ip` | Run `git submodule update --init` inside ibex-master |
| `Could not find prim_assert.sv` | Re-run `setup_from_ibex.sh` |
| `syntax error` + `ibex_core is not a verilog module` | Add `-D SYNTHESIS` to sv2v |
| WNS = 0.00 | OpenSTA failed; check `Error:` in `.txt` |
| `invalid command name "read_liberty"` | Use `yosys -s synth.tcl` |
