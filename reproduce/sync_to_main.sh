#!/usr/bin/env bash
# Copy successful STA artifacts from ~/Project_STA into ibex_sta_project.
set -euo pipefail

SRC="${1:-$HOME/Project_STA}"
DST="${2:-$HOME/ibex_sta_project}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -f "$SRC/sta/ibex_tt.txt" ]] || die "missing $SRC/sta/ibex_tt.txt — run reproduce flow in Project_STA first"
[[ -d "$DST/sta" ]]             || die "missing $DST/sta"

echo "SRC=$SRC"
echo "DST=$DST"

# STA reports (main deliverables)
cp "$SRC/sta/ibex_tt.txt" "$DST/sta/"
cp "$SRC/sta/ibex_ss.txt" "$DST/sta/"

# STA scripts (keep in sync with what produced the reports)
cp "$SRC/sta/constraints.sdc"   "$DST/sta/"
cp "$SRC/sta/run_sta_tt.tcl"    "$DST/sta/"
cp "$SRC/sta/run_sta_ss.tcl"    "$DST/sta/"

# Synthesis outputs
cp "$SRC/synth/ibex_core.v"   "$DST/synth/"
cp "$SRC/synth/ibex_synth.v"  "$DST/synth/"
cp "$SRC/synth/synth.tcl"     "$DST/synth/"

# Conversion lists (optional, for re-running sv2v from main repo)
cp "$SRC/reproduce/pkg_list.txt"  "$DST/reproduce/" 2>/dev/null || cp "$SRC/pkg_list.txt" "$DST/reproduce/" 2>/dev/null || true
cp "$SRC/reproduce/rtl_list.txt"  "$DST/reproduce/" 2>/dev/null || cp "$SRC/rtl_list.txt" "$DST/reproduce/" 2>/dev/null || true

echo ""
echo "Copied into $DST"
grep "^wns" "$DST/sta/ibex_tt.txt" "$DST/sta/ibex_ss.txt"
grep "^tns" "$DST/sta/ibex_tt.txt" "$DST/sta/ibex_ss.txt"
echo ""
echo "Verify parser:"
echo "  cd $DST/sta && python3 sta_report_parser.py ibex_tt.txt ibex_ss.txt"
