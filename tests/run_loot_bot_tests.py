#!/usr/bin/env python3
"""Exercise the loot bot's production startup, movement, proximity, and hop guards."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--luau', default='luau')
args = parser.parse_args()
tests = Path(__file__).resolve().parent
source = (tests.parent / 'internalscript.lua').read_text()
def section(start, end):
    offset = source.index(start)
    return source[offset:source.index(end, offset)]
helpers = section('            local function cancel_bot_movement()', '            local function getPing()')
startup = section('            local function RunTrinketPath(test_mode)', '                library:Notify(test_mode and "Starting test path..."')
startup += '\n startup_moves += 1\n return true\n end\n'
wrapper = section('            local function ExecutePath(test_mode)', '            local group_trinket_bot =')
exit_handler = section('            emergency_logout = function(reason)', '            local function DoSafeServerhop(')
finish = section('            local function finish_emergency_hop()', '            local teleport_debounce = false')
hop_completion = 'local function complete_trinket_hop(immediate_logout)\n' + section('                if immediate_logout then\n                    finish_emergency_hop()', '            local function TrinketBotServerhop(')
proximity = section('                proximity_connection = track_connection("proximity"', '                local trinkets_list = {}')
runner = (tests / 'loot_bot_mocks.lua').read_text()
runner = runner.replace('-- @HELPERS@', helpers).replace('-- @STARTUP@', startup).replace('-- @WRAPPER@', wrapper)
runner = runner.replace('-- @EMERGENCY_LOGOUT@', exit_handler).replace('-- @FINISH_EMERGENCY@', finish).replace('-- @HOP_COMPLETION@', hop_completion)
runner = runner.replace('-- @PROXIMITY@', 'local function install_proximity()\n local critical_serverhop_sent = false\n' + proximity + '\nend')
runner += '\n' + (tests / 'loot_bot_cases.lua').read_text()
with tempfile.TemporaryDirectory(prefix='loot-bot-') as directory:
    script = Path(directory) / 'checks.lua'
    script.write_text(runner)
    subprocess.run([args.luau, str(script)], check=True)
