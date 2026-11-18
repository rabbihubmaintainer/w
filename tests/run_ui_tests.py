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
main_source = (tests.parent / 'internalscript.lua').read_text()
overlay_functions = []
for kind in ['player', 'trinket', 'fallion', 'npc', 'ingredient', 'ore']:
    start = main_source.index('                local function start_' + kind + '_esp_rendering()')
    end = main_source.index('                local function stop_' + kind + '_esp_rendering()', start)
    overlay_functions.append(main_source[start:end])
runner += '''
local function overlayHarness(kind)
    local calls, callback = {}, nil
    local esp_render_connections = {}
    local cheat_client = {}
    for _, category in ipairs({'player', 'trinket', 'fallion', 'npc', 'ingredient', 'ore'}) do
        local item = {}
        item['update_' .. category .. '_esp'] = function(enabled) calls[#calls + 1] = enabled end
        cheat_client[category .. '_esp_objects'] = {item}
    end
    local utility = {Connection = function(_, _, handler) callback = handler; return {} end}
    local rs = services.RunService
    local function LPH_NO_VIRTUALIZE(handler) return handler end
''' + '\n'.join(overlay_functions) + '''
    local starts = {player = start_player_esp_rendering, trinket = start_trinket_esp_rendering,
        fallion = start_fallion_esp_rendering, npc = start_npc_esp_rendering,
        ingredient = start_ingredient_esp_rendering, ore = start_ore_esp_rendering}
    starts[kind]()
    return function() callback(); callback(); return calls[#calls] end
end
'''
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
