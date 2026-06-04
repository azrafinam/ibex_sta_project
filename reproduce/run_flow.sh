#!/usr/bin/env bash
# sv2v -> Yosys -> OpenSTA. Run after setup_from_ibex.sh.
set -euo pipefail

PROJECT="${PROJECT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SV2V="${SV2V:-$HOME/sta_ibex_work/sv2v-Linux/sv2v}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$PROJECT/rtl" ]]        || die "run setup_from_ibex.sh first"
[[ -f "$PROJECT/reproduce/pkg_list.txt" ]] || die "run setup_from_ibex.sh first"
[[ -x "$SV2V" || -f "$SV2V" ]] || die "sv2v not found at $SV2V"

echo "PROJECT=$PROJECT"
echo "SV2V=$SV2V"

# --- sv2v ---
echo "--- sv2v ---"
cd "$PROJECT"
"$SV2V" \
  -D SYNTHESIS \
  -I include \
  $(cat reproduce/pkg_list.txt) \
  $(cat reproduce/rtl_list.txt) \
  > synth/ibex_core.v

grep -En '\$display|\$write' synth/ibex_core.v && die "simulation tasks in ibex_core.v — check -D SYNTHESIS"
grep -q 'export "DPI-C"' synth/ibex_core.v && sed -i '/export "DPI-C"/d' synth/ibex_core.v || true

# --- Yosys ---
echo "--- Yosys ---"
cd "$PROJECT/synth"
yosys -s synth.tcl

grep -En '\$display|\$write|always @\(negedge' ibex_synth.v && die "simulation code in netlist"

# --- OpenSTA ---
echo "--- OpenSTA TT ---"
cd "$PROJECT/sta"
opensta -no_init < run_sta_tt.tcl > ibex_tt.txt 2>&1
grep "Error:" ibex_tt.txt && die "OpenSTA TT failed" || true

echo "--- OpenSTA SS ---"
opensta -no_init < run_sta_ss.tcl > ibex_ss.txt 2>&1
grep "Error:" ibex_ss.txt && die "OpenSTA SS failed" || true

echo ""
echo "Done."
grep "^wns" ibex_tt.txt ibex_ss.txt
grep "^tns" ibex_tt.txt ibex_ss.txt
grep -c "Startpoint:" ibex_tt.txt ibex_ss.txt
