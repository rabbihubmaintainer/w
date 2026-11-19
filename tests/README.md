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

## Loot bot proximity checks

```sh
python3 tests/run_loot_bot_tests.py --luau /path/to/luau
```

These checks execute the production proximity helpers, movement, startup checks,
run guard, and proximity monitor with an offline clock and Roblox API doubles.
They cover nearby players at startup, interrupted movement, continuous clearance,
stop/unload/death/respawn, concurrent starts and hops, pickup guards, zero speed,
and Stay in Server mode. The collector checks also simulate gravity through real
pickup loops and verify hover ownership, collision restoration, gate handoff,
and unload cleanup. The startup harness ends before game-specific setup;
these checks do not execute a full route in Roblox.

Critical Distance takes priority at startup, during movement, and while paused.
When enabled, it requests return to menu immediately and starts an independent
server hop. It bypasses the clearance wait, notifications, detailed webhook logs,
escape/gate attempts, and waiting for Danger to clear. A hanging menu request does
not block the hop; a failed emergency hop disconnects rather than entering a
wait/retry loop. Test mode and Stay in Server still prevent this automatic exit.
The game/network controls the actual transition after the request is sent.

Outside that emergency case, the bot waits before starting if a living player is
within the largest of 60 studs, Critical Distance, or Proximity Check. Normal
movement and pickups use the largest of 60 studs or Critical Distance. After a
pause, players must leave that radius plus 15 studs for two continuous seconds
before movement resumes. Emergency gates still apply outside critical range;
escape movement can bypass the pause so it does not deadlock beside a threat.

Successful ordinary moves retain a position hold through pickup delays and idle
time, without anchoring the character. The next move takes over that hold; gates,
stop, emergency logout, death, respawn, root removal, and unload release it.
Position and assembly velocity are stabilized while hovering and while movement
is paused. Releasing the hold restores its saved collision and humanoid settings.

Verify in-game by starting with another player beside you, letting them leave and
return during movement, and using Stop Bot while paused. Repeat with Stay in Server
enabled and with the configured critical/emergency settings.
Also collect several trinkets above ground and check that the character does not
drop between arrival and pickup, then verify a gate and manual stop release it.
