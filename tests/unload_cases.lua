local passed = 0
local function test(name, callback)
    local ok, message = pcall(callback)
    assert(ok, name .. ": " .. tostring(message))
    passed += 1
    print("PASS " .. name)
end
local function equal(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

test("unload is immediate, repeatable, and retains the stop flag", function()
    local s = makeSession()
    s.utility:Unload()
    assert(s.lifecycle.stopped and s.shared.is_unloading)
    equal(s.environment.loaded, nil)
    equal(type(s.shared.connections), "table")
    s.utility:Unload()
    equal(#s.warnings, 0)
end)

test("unload cancels sleeping workers and delayed callbacks", function()
    local s = makeSession()
    local resumed = false
    local worker = s.task.spawn(function() s.task.wait(); resumed = true end)
    local delayed = s.task.delay(10, function() resumed = true end)
    local deferred = s.task.defer(function() resumed = true end)
    s.utility:Unload()
    s.advance()
    assert(s.cancelled[worker] and s.cancelled[delayed] and s.cancelled[deferred])
    equal(resumed, false)
end)

test("completed tasks do not accumulate in the registry", function()
    local s = makeSession()
    for _ = 1, 100 do s.task.spawn(function() end) end
    equal(next(s.lifecycle.threads), nil)
    s.task.spawn(function() s.task.wait() end)
    s.advance()
    equal(next(s.lifecycle.threads), nil)
end)

test("yielding signal handlers are cancelled, including skip_tracking", function()
    local s = makeSession()
    local event = s.signal()
    local resumed = false
    local connection = s.utility:Connection(event, function() s.task.wait(); resumed = true end, true)
    event:Fire()
    s.utility:Unload()
    s.advance()
    equal(connection.Connected, false)
    equal(resumed, false)
end)

test("unload can run from a tracked event without cancelling itself", function()
    local s = makeSession()
    local event = s.signal()
    local returned = false
    s.utility:Connection(event, function() s.utility:Unload(); returned = true end)
    event:Fire()
    assert(returned and s.lifecycle.stopped)
end)

test("unload can run from a spawned worker without cancelling itself", function()
    local s = makeSession()
    local returned = false
    s.task.spawn(function() s.utility:Unload(); returned = true end)
    assert(returned and s.lifecycle.stopped)
end)

test("new tasks and callbacks do no work after unload", function()
    local s = makeSession()
    local calls = 0
    s.utility:Unload()
    s.task.spawn(function() calls += 1 end)
    s.task.defer(function() calls += 1 end)
    s.task.delay(1, function() calls += 1 end)
    s.lifecycle:Run(function() calls += 1 end)
    local event = s.signal()
    local connection = s.utility:Connection(event, function() calls += 1 end)
    event:Fire()
    s.advance()
    equal(calls, 0)
    equal(connection.Connected, false)
end)

test("already removed drawings cannot interrupt later cleanup", function()
    local s = makeSession()
    s.shared.drawing_containers.esp = {
        {Remove = function() error("already removed") end},
        {Remove = function(self) self.removed = true end},
    }
    local second = s.shared.drawing_containers.esp[2]
    s.utility:Unload()
    assert(second.removed and s.lifecycle.stopped)
    assert(s.cpu.services.rs.enabled and s.memory.botstarted)
    equal(s.environment.loaded, nil)
    equal(#s.warnings, 1)
end)

test("one failing feature does not suppress the remaining restorations", function()
    local s = makeSession({bad_memory = "dayfarming"})
    local restored = false
    s.client.restore_ambience = function() error("missing effect") end
    s.client.restore_state = function() restored = true end
    s.utility:Unload()
    assert(restored and s.lifecycle.stopped and s.memory.loaded_config)
    equal(#s.warnings, 2)
end)

test("cleanup registry runs through errors and in reverse order", function()
    local s = makeSession()
    local order = {}
    s.lifecycle:AddCleanup("first", function() order[#order + 1] = 1 end)
    s.lifecycle:AddCleanup("broken", function() error("broken cleanup") end)
    s.lifecycle:AddCleanup("last", function() order[#order + 1] = 2 end)
    s.utility:Unload()
    equal(table.concat(order), "21")
    equal(#s.warnings, 1)
end)

test("active tweens are cancelled before their targets are destroyed", function()
    local s = makeSession()
    local target = s.instance.new("Part")
    local tween = s.lifecycle:CreateTween({Create = function()
        return {Cancel = function(self) assert(target.destroyed == 0); self.cancelled = true end}
    end})
    s.utility:Unload()
    assert(tween.cancelled and target.destroyed == 1)
end)

test("property and humanoid state snapshots preserve original false values", function()
    local s = makeSession()
    local target = {CanTouch = false, CanCollide = true}
    local human = {enabled = false}
    function human:GetStateEnabled() return self.enabled end
    function human:SetStateEnabled(_, value) self.enabled = value end
    s.lifecycle:Remember(target, "CanTouch")
    s.lifecycle:Remember(target, "CanCollide")
    s.lifecycle:RememberHumanoidState(human, 5)
    target.CanTouch = true; target.CanCollide = false; human.enabled = true
    s.lifecycle:Remember(target, "CanTouch")
    s.lifecycle:RememberHumanoidState(human, 5)
    s.utility:Unload()
    equal(target.CanTouch, false)
    equal(target.CanCollide, true)
    equal(human.enabled, false)
end)

test("rendering, volume, quality, and captured FPS cap are restored", function()
    local s = makeSession()
    s.lifecycle.original_fps_cap = 144
    s.utility:Unload()
    equal(s.cpu.services.ugs.MasterVolume, 0.7)
    equal(s.cpu.services.rs.enabled, true)
    equal(s.fps(), 144)
    equal(s.cpu.status.active, false)
end)

test("unload succeeds with no character or leaderboard", function()
    local s = makeSession({no_character = true})
    s.utility:Unload()
    assert(s.lifecycle.stopped)
    equal(#s.warnings, 0)
end)

test("HealerVision no longer skips hook and rendering restoration", function()
    local s = makeSession()
    s.plr.Backpack.HealerVision = {}
    s.utility:Unload()
    assert(s.lifecycle.stopped and s.cpu.services.rs.enabled)
end)

test("teleport unload preserves bot/config state; manual unload removes it", function()
    local s = makeSession()
    s.utility:Unload(true)
    equal(s.memory.botstarted, nil)
    equal(s.memory.loaded_config, nil)
    equal(s.memory.desert_mist_farming, nil)
    assert(s.memory.dayfarming)
    local manual = makeSession()
    manual.utility:Unload()
    assert(manual.memory.botstarted and manual.memory.loaded_config and manual.memory.desert_mist_farming)
end)

test("day rollers and part transparency/materials are restored", function()
    local s = makeSession()
    local roller = {Parent = {}, Text = "9"}
    local disconnected = false
    s.original_days.one = {object = roller, text = "3", connection = {Disconnect = function() disconnected = true end}}
    local part = {Parent = {}, Transparency = 0.7, Material = "Plastic", Reflectance = 0}
    s.transparent_parts[part] = 0.2
    s.original_materials[part] = {Material = "Metal", Reflectance = 0.5}
    s.utility:Unload()
    assert(disconnected)
    equal(roller.Text, "3")
    equal(part.Transparency, 0.2)
    equal(part.Material, "Metal")
    equal(part.Reflectance, 0.5)
end)

test("library-driven unload is reentrant", function()
    local s = makeSession()
    local calls = 0
    s.shared.library = {Unload = function(self)
        calls += 1
        s.utility:Unload()
        self.Unloaded = true
    end}
    s.utility:Unload()
    equal(calls, 1)
    assert(s.lifecycle.stopped)
end)

test("drawing creation applies false values and parentless text positions", function()
    local s = makeSession()
    local drawing = s.utility:Create("Text", {Visible = false, Position = {X = {Scale = 0.5, Offset = 5}, Y = {Scale = 0.5, Offset = 3}}}, "esp")
    equal(drawing.Visible, false)
    equal(drawing.Position.X, 405)
    equal(drawing.Position.Y, 303)
    s.utility:Update(drawing, "Position", {X = {Scale = 0, Offset = 1}, Y = {Scale = 0, Offset = 2}})
    equal(drawing.Position.X, 1)
    equal(drawing.Position.Y, 2)
end)

test("nested callbacks retain nil return values", function()
    local s = makeSession()
    local result = table.pack(s.lifecycle:Run(function()
        return s.lifecycle:Run(function() return 1, nil, 3 end)
    end))
    equal(result.n, 3)
    equal(result[1], 1)
    equal(result[2], nil)
    equal(result[3], 3)
    equal(next(s.lifecycle.threads), nil)
end)

test("all installed function and metamethod hooks restore in reverse order", function()
    local original_index = function() end
    local s = makeSession({original_metamethod = original_index})
    local first = function() end
    local second = function() end
    local target = {}
    s.hookfunction(first, function() end)
    s.hookfunction(second, function() end)
    s.hookmetamethod(target, "__index", function() end)
    s.utility:Unload()
    equal(#s.hooks, 6)
    equal(s.hooks[4].target, target)
    equal(s.hooks[4].replacement, original_index)
    equal(s.hooks[5].target, second)
    equal(s.hooks[5].replacement, second)
    equal(s.hooks[6].target, first)
    equal(s.hooks[6].replacement, first)
end)

test("unsupported hook restoration reports an error and finishes cleanup", function()
    local s = makeSession({broken_restore = true})
    s.hookfunction(function() end, function() end)
    local target = s.instance.new("Part")
    s.utility:Unload()
    assert(s.lifecycle.stopped and target.destroyed == 1)
    equal(#s.warnings, 1)
end)

test("original remote callbacks restore after feature finalizers", function()
    local s = makeSession()
    local original = function() return "game" end
    local remote = {OnClientInvoke = original}
    s.lifecycle:RememberCallback(remote, "OnClientInvoke")
    remote.OnClientInvoke = function() return "feature" end
    s.lifecycle:RememberCallback(remote, "OnClientInvoke")
    s.lifecycle:AddCleanup("feature", function() remote.OnClientInvoke = function() return "stale feature" end end)
    s.utility:Unload()
    equal(remote.OnClientInvoke, original)
end)

test("nil remote callbacks also restore correctly", function()
    local s = makeSession()
    local remote = {}
    s.lifecycle:RememberCallback(remote, "OnClientInvoke")
    remote.OnClientInvoke = function() end
    s.utility:Unload()
    equal(remote.OnClientInvoke, nil)
end)

test("read-protected remote callbacks use the provided fallback", function()
    local s = makeSession()
    local fallback = function() return "mouse" end
    local remote = setmetatable({}, {__index = function() error("read protected") end})
    s.lifecycle:RememberCallback(remote, "OnClientInvoke", fallback)
    remote.OnClientInvoke = function() end
    s.utility:Unload()
    equal(remote.OnClientInvoke, fallback)
end)

test("partial initialization can clean resources without a completed UI", function()
    local s = makeSession()
    local ran = false
    s.task.delay(5, function() ran = true end)
    local target = s.instance.new("Part")
    s.lifecycle.stopping = true
    s.lifecycle:Quiesce()
    s.lifecycle:Finish()
    s.advance()
    equal(ran, false)
    assert(target.destroyed == 1 and s.lifecycle.stopped)
end)

print(string.format("%d regression checks passed", passed))
