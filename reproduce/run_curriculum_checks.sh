#!/usr/bin/env bash
# Run curriculum acceptance checks for ibex_sta_project (ibex reports only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STA="$ROOT/sta"

die() { echo "FAIL: $*" >&2; exit 1; }

cd "$STA"
test -f ibex_tt.txt && test -f ibex_ss.txt || die "missing ibex_tt.txt or ibex_ss.txt"

echo "========== Prerequisites =========="
opensta -version | head -1
ls ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
ls ~/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib

echo ""
echo "========== Day 0 — Ground truth =========="
for corner in tt ss; do
  f="ibex_${corner}.txt"
  echo "--- $f ---"
  grep '^wns' "$f"
  grep '^tns' "$f"
  echo "Startpoint count: $(grep -c 'Startpoint:' "$f")"
  echo "VIOLATED count:   $(grep -c 'VIOLATED' "$f")"
done

echo ""
echo "========== Day 3 — Parser =========="
python3 sta_report_parser.py ibex_tt.txt ibex_ss.txt

echo ""
echo "========== Day 4 — Verifier =========="
python3 verify_sta_parser.py ibex_tt.txt ibex_ss.txt

echo ""
echo "========== DONE — see reports/CURRICULUM_VERIFICATION.md =========="
