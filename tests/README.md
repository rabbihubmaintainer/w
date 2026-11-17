# Unload regression checks

Install Python 3 and the [Luau CLI](https://github.com/luau-lang/luau/releases), then run:

```sh
luau-compile --null internalscript.lua
python3 tests/run_unload_tests.py --luau /path/to/luau
```

The runner extracts lifecycle, connection, drawing, and unload functions from the
current `internalscript.lua`. It runs those functions with API doubles; it does not
execute the full game script, install executor hooks, or make network requests.

The 26 checks cover cancellation of sleeping tasks and yielded signal handlers,
repeated/reentrant unload, failed cleanup operations, resource ordering, hook and
remote callback restoration, property/state snapshots, missing character/UI,
rendering restoration, and manual versus teleport unload memory handling.

These checks do not establish that every feature works in Roblox. The script still
depends on the game, executor APIs, and remote Library/SaveManager/ThemeManager files.

## In-game verification still needed

1. Start a fresh game session and load the revised script. A copy already running
   still has its original unload implementation.
2. Unload from both the menu and the keybind; repeat unload to check reentrancy.
3. Repeat while flight/noclip/freecam, a bot tween, crafting, macros, and CPU/GPU
   optimization are active. Check collision, input, camera, rendering, and UI recovery.
4. Repeat after respawn and with the leaderboard absent or being recreated.
5. Load the script again after unloading and check for duplicate events or UI.
6. Verify server-hop resume separately: `Unload(true)` preserves bot/config memory.

Cleanup failures are now reported as `[rabbihub] unload ...` or `[rabbihub] restore ...`
instead of being silently discarded. Capture the first such error and its context
if an in-game problem remains.
