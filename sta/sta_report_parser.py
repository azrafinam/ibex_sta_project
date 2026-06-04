import re
import sys
import os
from collections import Counter

# ===================== SUMMARY =====================
def extract_summary(report_path):
    result = {
        'setup_wns': 0.0,  'setup_tns': 0.0,
        'hold_wns':  0.0,  'hold_tns':  0.0,
        'setup_violations': 0, 'hold_violations': 0,
        'timing_met': True
    }
    with open(report_path) as f:
        text = f.read()

    # TODO 1 — Setup WNS.
    m = re.search(r'^wns\s+(?:max\s+)?(-?\d+\.\d+)', text, re.MULTILINE)
    if m: result['setup_wns'] = float(m.group(1))

    # TODO 2 — Setup TNS.
    m = re.search(r'^tns\s+(?:max\s+)?(-?\d+\.\d+)', text, re.MULTILINE)
    if m: result['setup_tns'] = float(m.group(1))

    # TODO 3 — Hold WNS.
    # Leave as 0.0 for now as per instructions.

    # TODO 4 — Count setup violations.
    result['setup_violations'] = len(re.findall(r'VIOLATED', text))

    # Set timing_met based on WNS values:
    result['timing_met'] = (result['setup_wns'] >= 0
                            and result['hold_wns'] >= 0)
    return result


# ===================== PATH PARSER =====================
def parse_paths(report_path):
    paths   = []
    current = {}
    with open(report_path) as f:
        for line in f:
            s = line.strip()

            # TODO 5 — Detect new path start.
            if s.startswith('Startpoint:'):
                if current and 'startpoint' in current:
                    paths.append(current)
                current = {}
                current['startpoint'] = s.split(':', 1)[1].strip()
                # Remove parenthetical comments like (rising edge-triggered flip-flop)
                current['startpoint'] = re.sub(r'\s*\(.*?\)\s*$', '', current['startpoint']).strip()

            # TODO 6 — Extract endpoint.
            elif s.startswith('Endpoint:'):
                current['endpoint'] = s.split(':', 1)[1].strip()
                # Also remove parenthetical comments from endpoint
                current['endpoint'] = re.sub(r'\s*\(.*?\)\s*$', '', current['endpoint']).strip()

            # TODO 7 — Detect path type (setup vs hold).
            elif s.lower().startswith('path type') and ':' in s:
                current['path_type'] = 'hold' if 'min' in s.lower() else 'setup'

            # TODO 8 — Extract slack value and violated flag.
            elif 'slack' in s.lower():
                current['violated'] = 'VIOLATED' in s
                m = re.search(r'(-?\d+\.\d+)', s)
                if m:
                    current['slack'] = float(m.group(1))

    # Append the last path if it has required fields:
    if current and 'startpoint' in current and 'slack' in current:
        paths.append(current)

    # Fill missing fields with defaults so all paths have the same keys:
    for p in paths:
        p.setdefault('endpoint',  '')
        p.setdefault('path_type', 'setup')
        p.setdefault('slack',     0.0)
        p.setdefault('violated',  False)
    return paths


# ===================== MODULE ANALYSIS =====================
def count_by_module(paths):
    violated = [p for p in paths if p.get('violated', False)]

    modules = []
    for p in violated:
        ep = p.get('endpoint', '')
        parts = ep.split('/')
        module = parts[1] if len(parts) >= 2 else parts[0] if parts else 'unknown'
        modules.append(module)

    return dict(Counter(modules).most_common())


# ===================== PRINT REPORT =====================
def print_summary(report_path):
    '''Print a complete timing summary to the terminal.'''
    summary = extract_summary(report_path)
    paths   = parse_paths(report_path)
    modules = count_by_module(paths)

    label = os.path.splitext(os.path.basename(report_path))[0]

    print(f'')
    print(f'== STA Report: {label} ==')
    print(f'  Setup WNS:          {summary["setup_wns"]:8.3f} ns')
    print(f'  Setup TNS:          {summary["setup_tns"]:8.3f} ns')
    print(f'  Setup violations:   {summary["setup_violations"]:8d}')
    print(f'  Timing met:         {summary["timing_met"]}')
    print(f'  Total paths parsed: {len(paths):8d}')

    if paths:
        violated = [p for p in paths if p['violated']]
        if violated:
            worst = min(violated, key=lambda p: p['slack'])
            print(f'  Worst endpoint:     {worst["endpoint"]}')
            print(f'  Worst slack:        {worst["slack"]:8.3f} ns')

    if modules:
        print(f'  Violations by module (top 5):')
        for mod, cnt in list(modules.items())[:5]:
            print(f'    {cnt:4d}  {mod}')
    print()


# ===================== MAIN =====================
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python3 sta_report_parser.py <report_file> [report_file2 ...]')
        sys.exit(1)
    for report in sys.argv[1:]:
        print_summary(report)
