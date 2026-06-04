# parser_schema.md

## 1. extract_summary(report_path)

Returns:

{
  'setup_wns': float,
  'setup_tns': float,
  'hold_wns': float,
  'hold_tns': float,
  'setup_violations': int,
  'hold_violations': int,
  'timing_met': bool
}

Notes:
- Currently only setup WNS, setup TNS, and setup violation counts are extracted.
- Hold metrics are initialized to 0.0 / 0 until hold parsing is implemented.

---

## 2. parse_paths(report_path)

Returns:

[
  {
    'startpoint': str,
    'endpoint': str,
    'path_type': str,   # "setup" or "hold"
    'slack': float,
    'violated': bool
  }
]

Description:
- Extracts timing paths from OpenSTA reports.
- Removes parenthetical annotations from startpoints and endpoints.
- Detects path type from "Path Type:" field.
- Extracts slack and violation status.

---

## 3. count_by_module(paths)

Returns:

{
  "module_name": int
}

Description:
- Counts timing violations grouped by endpoint module.
- Results are sorted by descending violation count.

---

## 4. print_summary(report_path)

Description:
- Generates a terminal summary for a timing report.
- Displays:
  - Setup WNS
  - Setup TNS
  - Setup violation count
  - Timing-met status
  - Number of parsed paths
  - Worst violating endpoint
  - Worst slack
  - Top violating modules