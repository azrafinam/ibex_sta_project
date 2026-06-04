#!/usr/bin/env bash
# Populate Project_STA from ~/Desktop/ibex-master (rtl + vendor deps only).
set -euo pipefail

IBEX_SRC="${IBEX_SRC:-$HOME/Desktop/ibex-master}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${PROJECT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SKY130_LIB="${SKY130_LIB:-$HOME/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$IBEX_SRC/rtl" ]]           || die "missing $IBEX_SRC/rtl"
[[ -d "$IBEX_SRC/vendor/lowrisc_ip" ]] || die "missing $IBEX_SRC/vendor/lowrisc_ip"
[[ -f "$SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib" ]] || die "missing TT liberty at $SKY130_LIB"
[[ -f "$SKY130_LIB/sky130_fd_sc_hd__ss_100C_1v60.lib" ]] || die "missing SS liberty at $SKY130_LIB"

echo "IBEX_SRC=$IBEX_SRC"
echo "PROJECT=$PROJECT"

mkdir -p "$PROJECT"/{include,synth,sta}

# --- rtl (only synthesizable subset source tree) ---
rm -rf "$PROJECT/rtl"
cp -r "$IBEX_SRC/rtl" "$PROJECT/rtl"

# --- LowRISC primitives + DV headers (from ibex-master vendor) ---
find "$IBEX_SRC/vendor/lowrisc_ip/ip/prim/rtl"          -name '*.sv'  -exec cp {} "$PROJECT/include/" \;
find "$IBEX_SRC/vendor/lowrisc_ip/ip/prim/rtl"          -name '*.svh' -exec cp {} "$PROJECT/include/" \;
find "$IBEX_SRC/vendor/lowrisc_ip/ip/prim_generic/rtl"  -name '*.sv'  -exec cp {} "$PROJECT/include/" \;
find "$IBEX_SRC/vendor/lowrisc_ip/ip/prim_generic/rtl"  -name '*.svh' -exec cp {} "$PROJECT/include/" \;
find "$IBEX_SRC/vendor/lowrisc_ip/dv/sv/dv_utils"       -name '*.svh' -exec cp {} "$PROJECT/include/" \;

# --- package order for sv2v ---
cat > "$PROJECT/reproduce/pkg_list.txt" << 'EOF'
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
EOF

# --- RTL list: drop verification / tracing wrappers ---
ls "$PROJECT"/rtl/*.sv \
  | grep -v tracer \
  | grep -v ibex_top_tracing \
  | grep -v ibex_lockstep \
  > "$PROJECT/reproduce/rtl_list.txt"

# --- Yosys script ---
cat > "$PROJECT/synth/synth.tcl" << EOF
read_liberty -lib $SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ibex_core.v

hierarchy -top ibex_core

proc
opt
fsm
opt
memory
opt

techmap
opt

dfflibmap -liberty $SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib

abc -liberty $SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib

clean

write_verilog ibex_synth.v
EOF

# --- SDC ---
cat > "$PROJECT/sta/constraints.sdc" << 'EOF'
current_design ibex_core
create_clock -name clk_i -period 20 [get_ports clk_i]
set_clock_uncertainty 0.25 [get_clocks clk_i]
set_input_delay 0 -clock clk_i [get_ports -filter "direction == input && name != clk_i"]
set_output_delay 0 -clock clk_i [all_outputs]
set_load 0.0334 [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_1 -pin Y [get_ports -filter "direction == input && name != clk_i"]
EOF

# --- OpenSTA Tcl ---
cat > "$PROJECT/sta/run_sta_tt.tcl" << EOF
set LIB "$SKY130_LIB/sky130_fd_sc_hd__tt_025C_1v80.lib"
set NETLIST "../synth/ibex_synth.v"
set SDC "constraints.sdc"
set TOP "ibex_core"

read_liberty \$LIB
read_verilog \$NETLIST
link_design \$TOP
read_sdc \$SDC

report_wns
report_tns
report_checks -path_delay max -endpoint_path_count 20 -fields {slew capacitance input_pin net} -format full_clock_expanded
report_checks -path_delay min -endpoint_path_count 10
report_clock_skew -setup
report_check_types -max_slew -max_cap -violators
EOF

cat > "$PROJECT/sta/run_sta_ss.tcl" << EOF
set LIB "$SKY130_LIB/sky130_fd_sc_hd__ss_100C_1v60.lib"
set NETLIST "../synth/ibex_synth.v"
set SDC "constraints.sdc"
set TOP "ibex_core"

read_liberty \$LIB
read_verilog \$NETLIST
link_design \$TOP
read_sdc \$SDC

report_wns
report_tns
report_checks -path_delay max -endpoint_path_count 20 -fields {slew capacitance input_pin net} -format full_clock_expanded
report_checks -path_delay min -endpoint_path_count 10
report_clock_skew -setup
report_check_types -max_slew -max_cap -violators
EOF

echo ""
echo "Setup complete: $PROJECT"
echo "  rtl files:    $(ls "$PROJECT/rtl"/*.sv | wc -l)"
echo "  include files: $(ls "$PROJECT/include" | wc -l)"
echo "  rtl_list:     $(wc -l < "$PROJECT/reproduce/rtl_list.txt") modules"
echo ""
echo "Next: run reproduce/run_flow.sh (or follow REPRODUCE.md Steps 5-9)"
