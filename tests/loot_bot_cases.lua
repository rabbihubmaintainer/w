local passed = 0
local function test(name, callback)
    reset()
    local ok, err = pcall(callback)
    assert(ok, name .. ': ' .. tostring(err))
    passed += 1; print('PASS ' .. name)
end
test('startup waits for an adjacent player even with optional proximity checks disabled', function()
    trinket_bot.path_running = false
    Options.CriticalDistance.Value = 0
    local player = addPlayer(1)
    spawn(ExecutePath, true)
    step(10)
    assert(startup_moves == 0 and trinket_bot.safety_paused)
    assert(#tweens == 0 and plr.Character.Humanoid.enabled)
    player.Character.HumanoidRootPart.Position = Vector3.new(100, 0, 0)
    step(15); assert(startup_moves == 0)
    step(10); assert(startup_moves == 1 and not trinket_bot.safety_paused)
end)
test('startup honors a larger configured proximity range', function()
    trinket_bot.path_running = false; Options.ProximityCheck.Value = 300
    addPlayer(250)
    spawn(ExecutePath, true); step(5)
    assert(startup_moves == 0 and trinket_bot.safety_paused)
end)
test('a clear startup proceeds immediately and duplicate starts cannot change the active run', function()
    trinket_bot.path_running = false
    addPlayer(10)
    spawn(ExecutePath, true)
    spawn(ExecutePath, false)
    assert(trinket_bot.test_mode == true and startup_moves == 0)
    players = {plr}; step(25)
    assert(startup_moves == 1 and not trinket_bot.path_executing)
    spawn(ExecutePath, false)
    assert(startup_moves == 2)
end)
test('startup pause stops cleanly on stop, unload, death, or respawn', function()
    for _, action in ipairs({'stop', 'unload', 'death', 'respawn'}) do
        reset(); trinket_bot.path_running = false; addPlayer(1)
        spawn(ExecutePath, true)
        if action == 'stop' then trinket_bot.path_running = false
        elseif action == 'unload' then shared.is_unloading = true
        elseif action == 'death' then plr.Character.Humanoid.Health = 0
        else plr.Character = character(0) end
        step(1)
        assert(startup_moves == 0 and not trinket_bot.safety_paused and not trinket_bot.path_executing)
        assert(#tweens == 0)
    end
end)
test('clearance needs two continuous seconds and a margin to avoid rapid toggling', function()
    Options.CriticalDistance.Value = 0
    local player = addPlayer(59)
    local finished = false
    spawn(function() finished = wait_for_safe_loot_area() end)
    player.Character.HumanoidRootPart.Position = Vector3.new(70, 0, 0)
    step(30); assert(not finished)
    player.Character.HumanoidRootPart.Position = Vector3.new(100, 0, 0)
    step(15)
    player.Character.HumanoidRootPart.Position = Vector3.new(60, 0, 0)
    step(1)
    player.Character.HumanoidRootPart.Position = Vector3.new(100, 0, 0)
    step(15); assert(not finished)
    step(10); assert(finished and #notices == 2)
end)
test('dead players and characters without a root do not block safety checks', function()
    local dead = addPlayer(0); dead.Character.Humanoid.Health = 0
    local loading = addPlayer(0); loading.Character.HumanoidRootPart = nil
    assert(wait_for_safe_loot_area())
    assert(nearby_loot_bot_player(60) == nil)
    assert(loot_bot_can_collect())
end)
test('movement waits when a player is near its destination', function()
    addPlayer(200)
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(200, 0, 0), true) end)
    step(5)
    assert(result == nil and #tweens == 0 and trinket_bot.safety_paused)
    assert(not loot_bot_can_collect(Vector3.new(200, 0, 0)))
end)
test('movement pauses for a new nearby player and resumes the same tween after clearance', function()
    Toggles.StayInServer = {Value = true}
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(100, 0, 0)) end)
    step(2)
    local player = addPlayer(10)
    step(2)
    assert(tweens[1].pauses == 1 and not tweens[1].playing)
    assert(not loot_bot_can_collect())
    player.Character.HumanoidRootPart.Position = Vector3.new(300, 0, 0)
    step(15); assert(not tweens[1].playing)
    step(20)
    assert(result == true and #tweens == 1 and not plr.Character.Humanoid.enabled)
    cancel_bot_movement()
    assert(plr.Character.Humanoid.enabled)
end)
test('emergency interruption cancels movement and never reports a successful arrival', function()
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(300, 0, 0), true) end)
    emergency_gate_requested = {action = 'gate_next'}
    step(1)
    assert(result == false and tweens[1].cancelled)
    assert(plr.Character.HumanoidRootPart.Position.X == 0)
    assert(active_tween_data.tween == nil and active_tween_data.connection == nil)
    assert(not loot_bot_can_collect())
    for _, c in ipairs(rs.RenderStepped.connections) do assert(not c.Connected) end
end)
test('movement cancels on stop, unload, death, respawn, or root removal', function()
    for _, action in ipairs({'stop', 'unload', 'death', 'respawn', 'root'}) do
        reset(); local result
        spawn(function() result = SmoothTeleport(Vector3.new(300, 0, 0)) end)
        if action == 'stop' then trinket_bot.stop_requested = true
        elseif action == 'unload' then shared.is_unloading = true
        elseif action == 'death' then plr.Character.Humanoid.Health = 0
        elseif action == 'root' then plr.Character.HumanoidRootPart = nil
        else plr.Character = character(0) end
        step(1)
        assert(result == false and tweens[1].cancelled)
        assert(active_tween_data.tween == nil)
    end
end)
test('zero movement speed stops safely instead of making an infinite tween', function()
    Options.TrinketBotSpeed.Value = 0
    assert(SmoothTeleport(Vector3.new(100, 0, 0)) == false)
    assert(not trinket_bot.path_running and #tweens == 0)
end)
test('movement restores a previously disabled humanoid state', function()
    plr.Character.Humanoid.enabled = false
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(10, 0, 0)) end)
    step(2)
    assert(result == true and plr.Character.Humanoid.enabled == false)
end)
test('escape movement bypasses the proximity wait but still respects manual stop', function()
    trinket_bot.path_running = false; addPlayer(0)
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(100, 0, 0), false, true) end)
    assert(#tweens == 1)
    trinket_bot.stop_requested = true; step(1)
    assert(result == false and tweens[1].cancelled)
end)
test('hop guard allows nesting but rejects concurrent hops and starts', function()
    local count = 0
    spawn(function()
        run_bot_hop(function()
            count += 1
            run_bot_hop(function() count += 1 end)
            task.wait()
        end)
    end)
    spawn(function() assert(run_bot_hop(function() count += 10 end) == false) end)
    spawn(ExecutePath, true)
    assert(count == 2 and startup_moves == 0)
    step(1); assert(trinket_bot.hop_owner == nil)
end)
test('a failed hop releases its guard and leaves the bot stopped', function()
    assert(run_bot_hop(function() error('network failed') end) == false)
    assert(trinket_bot.hop_owner == nil and not trinket_bot.path_running)
end)
test('critical proximity monitoring cancels movement and fires only once', function()
    spawn(function() SmoothTeleport(Vector3.new(300, 0, 0)) end)
    install_proximity()
    addPlayer(1)
    spawn(function() rs.Heartbeat:Fire() end)
    assert(tweens[1].cancelled and hop_count == 1 and not trinket_bot.path_running)
    spawn(function() rs.Heartbeat:Fire() end)
    assert(hop_count == 1)
    step(2)
end)
test('stopped and unloading bots cannot trigger a proximity hop', function()
    install_proximity(); addPlayer(1)
    trinket_bot.path_running = false
    rs.Heartbeat:Fire(); assert(hop_count == 0)
    trinket_bot.path_running = true; shared.is_unloading = true
    rs.Heartbeat:Fire(); assert(hop_count == 0)
end)
test('stay-in-server mode still pauses near a player without triggering a hop', function()
    Toggles.StayInServer = {Value = true}
    install_proximity(); addPlayer(1)
    rs.Heartbeat:Fire()
    assert(hop_count == 0)
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(100, 0, 0)) end)
    step(5)
    assert(result == nil and #tweens == 0 and trinket_bot.safety_paused)
end)
test('pickup guards reject missing roots, death, manual stop, and an active hop', function()
    assert(loot_bot_can_collect())
    trinket_bot.stop_requested = true; assert(not loot_bot_can_collect())
    trinket_bot.stop_requested = false
    trinket_bot.hop_owner = coroutine.running(); assert(not loot_bot_can_collect())
    trinket_bot.hop_owner = nil
    plr.Character.Humanoid.Health = 0; assert(not loot_bot_can_collect())
    plr.Character.Humanoid.Health = 100
    plr.Character.HumanoidRootPart = nil; assert(not loot_bot_can_collect())
end)
test('dead players do not trigger a critical hop', function()
    install_proximity()
    addPlayer(1).Character.Humanoid.Health = 0
    rs.Heartbeat:Fire()
    assert(hop_count == 0 and trinket_bot.path_running)
    Options.ProximityCheck.Value = 300
    rs.Heartbeat:Fire()
    assert(emergency_gate_requested == nil)
end)
test('critical range at startup logs out before the ping check or clearance wait', function()
    trinket_bot.path_running = false
    addPlayer(60)
    spawn(ExecutePath, false)
    assert(startup_moves == 0 and ping_checks == 0 and #tweens == 0)
    assert(#exit_events == 2 and exit_events[1].kind == 'menu' and exit_events[2].kind == 'hop')
    assert(exit_events[1].time == 0 and exit_events[2].time == 0)
    assert(not trinket_bot.path_running and not trinket_bot.safety_paused)
end)
test('entering critical range while startup is paused bypasses the two-second wait', function()
    trinket_bot.path_running = false; Options.ProximityCheck.Value = 300
    local player = addPlayer(100)
    spawn(ExecutePath, false)
    assert(trinket_bot.safety_paused and #exit_events == 0)
    player.Character.HumanoidRootPart.Position = Vector3.new(59, 0, 0)
    local detected_at = clock
    step(1)
    assert(#exit_events == 2 and exit_events[1].kind == 'menu')
    assert(exit_events[1].time - detected_at <= 0.10001)
    assert(startup_moves == 0 and not trinket_bot.safety_paused)
end)
test('a hanging menu request cannot delay the independent emergency hop', function()
    menu_hangs = true
    assert(emergency_logout('Critical player'))
    assert(#jobs == 1)
    assert(#exit_events == 2 and exit_events[1].kind == 'menu' and exit_events[2].kind == 'hop')
    assert(exit_events[1].time == 0 and exit_events[2].time == 0)
end)
test('a failed menu request still attempts an emergency hop without waiting', function()
    menu_fails = true
    assert(emergency_logout('Critical player'))
    assert(hop_count == 1 and exit_events[2].kind == 'hop' and exit_events[2].time == 0)
end)
test('an emergency server-search failure disconnects instead of waiting for Danger', function()
    for _, thrown in ipairs({false, true}) do
        reset()
        hop_success, hop_fails = false, thrown
        assert(emergency_logout('Critical player'))
        assert(exit_events[3].kind == 'kick' and exit_events[3].time == 0)
        assert(not trinket_bot.path_running)
    end
end)
test('critical logout is idempotent and does not wait for a notification', function()
    local original = library.Notify
    library.Notify = function() error('Emergency logout must run before UI work') end
    assert(emergency_logout('Critical player'))
    assert(emergency_logout('Duplicate critical player'))
    assert(#exit_events == 2 and hop_count == 1 and clock == 0)
    library.Notify = original
end)
test('critical logout cancels an in-flight tween before requesting the menu', function()
    spawn(function() SmoothTeleport(Vector3.new(300, 0, 0)) end)
    assert(active_tween_data.tween ~= nil)
    assert(emergency_logout('Critical player'))
    assert(tweens[1].cancelled and exit_events[1].kind == 'menu' and exit_events[1].time == 0)
    assert(active_tween_data.tween == nil)
end)
test('disabled critical range, test mode, and Stay in Server retain their protections', function()
    for _, mode in ipairs({'disabled', 'test', 'stay'}) do
        reset(); addPlayer(1)
        if mode == 'disabled' then Options.CriticalDistance.Value = 0
        elseif mode == 'test' then trinket_bot.test_mode = true
        else Toggles.StayInServer = {Value = true} end
        assert(not check_critical_player())
        assert(#exit_events == 0 and trinket_bot.path_running)
    end
end)
test('arrival keeps a stable hover throughout pickup delays and idle time', function()
    simulate_gravity = true
    local result
    spawn(function() result = SmoothTeleport(Vector3.new(20, 25, 0), true) end)
    step(20)
    local root = plr.Character.HumanoidRootPart
    assert(result == true and root.Position.Y == 25)
    assert(active_tween_data.tween == nil and active_tween_data.connection.Connected)
    assert(not plr.Character.Humanoid.enabled and not root.Anchored)
    step(50)
    assert(root.Position.Y == 25 and root.Position.X == 20)
    assert(root.AssemblyLinearVelocity.Magnitude == 0 and root.AssemblyAngularVelocity.Magnitude == 0)
end)
test('the real trinket collector clicks successive items without losing height', function()
    simulate_gravity = true
    Toggles.PickupTrinkets = {Value = true}
    addLoot(10, 25, 'first'); addLoot(20, 25, 'second')
    spawn(CheckForTrinkets)
    step(50)
    assert(#pickups == 2)
    for _, pickup in ipairs(pickups) do assert(pickup.y == 25 and pickup.x == pickup.target.X) end
    assert(collected.first and collected.second)
    assert(active_tween_data.connection.Connected and plr.Character.HumanoidRootPart.Position.Y == 25)
    for _, connection in ipairs(ws.ChildAdded.connections) do assert(not connection.Connected) end
end)
test('a new move transfers hover ownership without leaving old position locks', function()
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
    local previous = active_tween_data.connection
    assert(previous.Connected)
    simulate_gravity = true
    spawn(function() SmoothTeleport(Vector3.new(30, 40, 0)) end); step(10)
    assert(not previous.Connected and active_tween_data.connection.Connected)
    local count = 0
    for _, connection in ipairs(rs.RenderStepped.connections) do if connection.Connected then count += 1 end end
    assert(count == 1 and plr.Character.HumanoidRootPart.Position.Y == 40)
end)
test('hover stays active while a nearby player delays the next move', function()
    Toggles.StayInServer = {Value = true}
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
    local root = plr.Character.HumanoidRootPart
    addPlayer(11)
    simulate_gravity = true
    spawn(function() SmoothTeleport(Vector3.new(30, 40, 0)) end)
    step(20)
    assert(trinket_bot.safety_paused and root.Position.Y == 20 and #tweens == 1)
end)
test('a proximity pause during movement holds its current position against gravity', function()
    Toggles.StayInServer = {Value = true}
    spawn(function() SmoothTeleport(Vector3.new(300, 50, 0)) end)
    step(1); addPlayer(1); step(1)
    local root = plr.Character.HumanoidRootPart
    local position = root.Position
    simulate_gravity = true; step(15)
    assert(tweens[1].pauses == 1 and root.Position.Y == position.Y and root.Position.X == position.X)
end)
test('stop, death, respawn, and root removal release an already completed hover', function()
    for _, action in ipairs({'stop', 'death', 'respawn', 'root'}) do
        reset()
        spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
        local previous, humanoid = active_tween_data.connection, plr.Character.Humanoid
        if action == 'stop' then trinket_bot.stop_requested = true
        elseif action == 'death' then humanoid.Health = 0
        elseif action == 'respawn' then plr.Character = character(0)
        else plr.Character.HumanoidRootPart = nil end
        step(1)
        assert(not previous.Connected and active_tween_data.release == nil and active_tween_data.connection == nil)
        assert(humanoid.enabled)
        if action == 'respawn' then assert(plr.Character.Humanoid.enabled) end
    end
end)
test('release restores original collision and humanoid settings and stops pinning position', function()
    local root, humanoid = plr.Character.HumanoidRootPart, plr.Character.Humanoid
    local limb = node('Limb', 'Part'); limb.CanCollide = false
    function plr.Character:GetDescendants() return {root, limb} end
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
    assert(not root.CanCollide and not limb.CanCollide and not humanoid.enabled)
    cancel_bot_movement(); cancel_bot_movement()
    assert(root.CanCollide and not limb.CanCollide and humanoid.enabled)
    root.Position = Vector3.new(50, 70, 0); step(2)
    assert(root.Position.X == 50 and root.Position.Y == 70)
end)
test('critical logout releases an arrival hover before dispatching the menu request', function()
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0), true) end); step(5)
    local previous = active_tween_data.connection
    assert(previous.Connected)
    assert(emergency_logout('Player in critical range'))
    assert(not previous.Connected and active_tween_data.release == nil)
    assert(exit_events[1].kind == 'menu' and exit_events[1].time == clock)
end)
test('the production unload cleanup releases a completed hover', function()
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
    local previous = active_tween_data.connection
    shared.is_unloading = true
    bot_cleanup()
    assert(not previous.Connected and active_tween_data.release == nil and active_tween_data.connection == nil)
end)
test('a gate attempt releases hover before handing control to the gate routine', function()
    spawn(function() SmoothTeleport(Vector3.new(10, 20, 0)) end); step(5)
    local previous = active_tween_data.connection
    assert(previous.Connected)
    -- No Gate tool is present: even a failed attempt must relinquish its old lock.
    assert(Gate('Test destination') == false)
    assert(not previous.Connected and active_tween_data.release == nil)
    local root = plr.Character.HumanoidRootPart
    root.Position = Vector3.new(100, 80, 0); step(2)
    assert(root.Position.X == 100 and root.Position.Y == 80)
end)
print(tostring(passed) .. ' loot bot safety checks passed')
