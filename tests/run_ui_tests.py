#!/usr/bin/env python3
"""Run UI and manager behavior checks against offline Roblox API doubles."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--luau', default='luau')
parser.add_argument('--snapshot', type=Path, help='Write an approximate UI instance snapshot as JSON')
args = parser.parse_args()
tests = Path(__file__).resolve().parent
runner = (tests / 'ui_mocks.lua').read_text()
for name, filename, function in [
    ('LIBRARY', 'Library.lua', 'loadLibrary'),
    ('THEME_MANAGER', 'ThemeManager.lua', 'loadThemeManager'),
    ('SAVE_MANAGER', 'SaveManager.lua', 'loadSaveManager'),
]:
    source = (tests.parent / filename).read_text()
    runner = runner.replace('-- @' + name + '@', 'local function ' + function + '()\n' + source + '\nend')
runner += '\n' + (tests / 'ui_cases.lua').read_text()
with tempfile.TemporaryDirectory(prefix='carbon-ui-') as temporary:
    script = Path(temporary) / 'ui-tests.lua'
    script.write_text(runner)
    result = subprocess.run([args.luau, str(script)], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if line.startswith('UI_SNAPSHOT '):
            if args.snapshot: args.snapshot.write_text(line.removeprefix('UI_SNAPSHOT '))
        else:
            print(line)
    if result.returncode:
        raise SystemExit(result.stderr)
