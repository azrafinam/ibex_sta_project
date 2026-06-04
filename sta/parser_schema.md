# parser_schema.md

## 1. extract_summary(report_path)

Returns:
{
  'setup_wns': float,
  'setup_tns': float,
  'hold_wns': float,
  'setup_violations': int,
  'hold_violations': int,
  'timing_met': bool
}

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

---

## 3. count_by_module(paths)

Returns:
{
  "module_name": int
}

- Sorted by most violations first
