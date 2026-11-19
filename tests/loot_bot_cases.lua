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
    assert(result == true and #tweens == 1 and plr.Character.Humanoid.enabled)
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
print(tostring(passed) .. ' loot bot safety checks passed')
