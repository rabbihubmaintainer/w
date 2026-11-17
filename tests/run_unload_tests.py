#!/usr/bin/env python3
"""Exercise the production lifecycle/unload functions with a Luau CLI and API doubles."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--luau', default='luau', help='Path to the Luau CLI executable')
args = parser.parse_args()
tests = Path(__file__).resolve().parent
source = (tests.parent / 'internalscript.lua').read_text()


def section(start, end):
    offset = source.index(start)
    return source[offset:source.index(end, offset)]


production = {
    'LIFECYCLE': section('    -- All resources below belong', '    local success, err = xpcall(function()'),
    'DRAWING': section('        function utility:Create(', '        function utility:Connection('),
    'CONNECTION': section('        function utility:Connection(', '        function utility:RemoveConnection('),
    'UNLOAD': section('        function utility:Unload(', '        function utility:ChangeAccent('),
}
runner = (tests / 'unload_mocks.lua').read_text()
for name, code in production.items():
    marker = '-- @PRODUCTION_' + name + '@'
    assert runner.count(marker) == 1, 'Missing or duplicated production marker: ' + marker
    runner = runner.replace(marker, code)
runner += '\n' + (tests / 'unload_cases.lua').read_text()
with tempfile.TemporaryDirectory(prefix='rabbihub-unload-') as temporary:
    script = Path(temporary) / 'regressions.lua'
    script.write_text(runner)
    subprocess.run([args.luau, str(script)], check=True)
