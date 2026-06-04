import subprocess
import sys
import re
from collections import Counter
from sta_report_parser import extract_summary, parse_paths, count_by_module


def chk(label, ok, detail=''):
    status = 'PASS' if ok else 'FAIL'
    print(f'  [{status}] {label}')
    if not ok and detail:
        print(f'         -> {detail}')
    return ok


def grep_count(pattern, filepath):
    r = subprocess.run(['grep', '-c', pattern, filepath],
                       capture_output=True, text=True)
    return int(r.stdout.strip()) if r.returncode == 0 else 0


def grep_value(pattern, filepath):
    r = subprocess.run(['grep', pattern, filepath],
                       capture_output=True, text=True)
    m = re.search(r'(-?\d+\.\d+)', r.stdout)
    return float(m.group(1)) if m else None


def raw_module_counts(filepath):
    counts = Counter()
    endpoint = ''

    with open(filepath) as f:
        for line in f:
            s = line.strip()

            if s.startswith('Endpoint:'):
                endpoint = s.split(':', 1)[1].strip()
                endpoint = re.sub(r'\s*\(.*?\)\s*$', '', endpoint).strip()

            elif re.search(r'^-?\d+\.\d+\s+slack\b', s, re.IGNORECASE):
                if 'VIOLATED' not in s:
                    continue
                parts = endpoint.split('/')
                module = parts[1] if len(parts) >= 2 else parts[0] if parts else 'unknown'
                counts[module] += 1

    return dict(counts.most_common())


def verify_report(report_path):
    print(f"\n-- Verifying: {report_path} ---------")
    all_pass = True

    summary = extract_summary(report_path)
    paths = parse_paths(report_path)
    modules = count_by_module(paths)

    grep_wns = grep_value('wns', report_path)
    grep_paths = grep_count('Startpoint:', report_path)
    grep_viol = grep_count('VIOLATED', report_path)

    # 1 WNS type
    all_pass &= chk(
        'setup_wns is float',
        isinstance(summary['setup_wns'], float)
    )

    # 2 WNS match
    if grep_wns is not None:
        all_pass &= chk(
            'setup_wns matches grep',
            abs(summary['setup_wns'] - grep_wns) < 0.001,
            f'{summary["setup_wns"]} vs {grep_wns}'
        )

    # 3 path count
    all_pass &= chk(
        'path count matches',
        len(paths) == grep_paths,
        f'{len(paths)} vs {grep_paths}'
    )

    # 4 violations
    all_pass &= chk(
        'VIOLATED count matches',
        summary['setup_violations'] == grep_viol,
        f'{summary["setup_violations"]} vs {grep_viol}'
    )

    # 5 fields check
    req = ['startpoint', 'endpoint', 'path_type', 'slack', 'violated']
    missing = [k for p in paths for k in req if k not in p]
    all_pass &= chk(
        'all paths have fields',
        len(missing) == 0
    )

    # 6 slack float
    all_pass &= chk(
        'slack values valid',
        all(isinstance(p['slack'], float) for p in paths)
    )

    # 7 timing_met type
    all_pass &= chk(
        'timing_met is bool',
        isinstance(summary['timing_met'], bool)
    )

    # 8 module ranking
    raw_modules = raw_module_counts(report_path)
    all_pass &= chk(
        'module counts match raw report',
        modules == raw_modules,
        f'{modules} vs {raw_modules}'
    )

    print(f"\n  RESULT: {'ALL PASS' if all_pass else 'FAIL'}")
    return all_pass


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 verify_sta_parser.py <report>")
        sys.exit(1)

    results = [verify_report(r) for r in sys.argv[1:]]
    print(f"\nFINAL: {sum(results)}/{len(results)} passed")
