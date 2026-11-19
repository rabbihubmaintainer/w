local clock = 0
local os = {clock = function() return clock end}
local jobs, tweens, notices = {}, {}, {}
local function signal()
    local event = {connections = {}}
    function event:Connect(callback)
        local connection = {Connected = true, callback = callback}
        function connection:Disconnect() self.Connected = false end
        self.connections[#self.connections + 1] = connection
        return connection
    end
    function event:Fire(...)
        for _, connection in ipairs(self.connections) do if connection.Connected then connection.callback(...) end end
    end
    return event
end
local function spawn(callback, ...)
    local thread = coroutine.create(callback)
    local ok, err = coroutine.resume(thread, ...)
    assert(ok, err)
    if coroutine.status(thread) ~= 'dead' then jobs[#jobs + 1] = thread end
    return thread
end
local task = {spawn = spawn, wait = function() return coroutine.yield() end}
local Vector3 = {}
local vectorMeta = {__type = 'Vector3'}
function Vector3.new(x, y, z) return setmetatable({X = x or 0, Y = y or 0, Z = z or 0}, vectorMeta) end
function vectorMeta.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vectorMeta.__index(v, key) if key == 'Magnitude' then return math.sqrt(v.X^2 + v.Y^2 + v.Z^2) end end
local function typeof(value) return type(value) == 'table' and (getmetatable(value) or {}).__type or type(value) end
local CFrame = {new = function(position) return setmetatable({Position = position}, {__type = 'CFrame'}) end}
local Enum = {PlaybackState = {Completed = 'Completed', Cancelled = 'Cancelled'}, EasingStyle = {Linear = 'Linear'}, EasingDirection = {InOut = 'InOut'}}
local TweenInfo = {new = function(time) return {Time = time} end}
local function LPH_NO_VIRTUALIZE(fn) return fn end
local function node(name, class)
    local result = {Name = name, ClassName = class, Parent = true}
    function result:IsA(kind) return self.ClassName == kind or (self.ClassName == 'Part' and kind == 'BasePart') end
    function result:GetDescendants() return self.HumanoidRootPart and {self.HumanoidRootPart} or {} end
    return result
end
local function character(x)
    local result = node('Character', 'Model')
    result.HumanoidRootPart = node('HumanoidRootPart', 'Part')
    result.HumanoidRootPart.Position = Vector3.new(x, 0, 0)
    result.HumanoidRootPart.Parent = result
    result.Humanoid = node('Humanoid', 'Humanoid')
    result.Humanoid.Health, result.Humanoid.enabled = 100, true
    function result.Humanoid:GetStateEnabled() return self.enabled end
    function result.Humanoid:SetStateEnabled(_, value) self.enabled = value end
    function result.Humanoid:ChangeState() end
    return result
end
local plr = {Name = 'Local', Character = character(0)}
local players = {plr}
local plrs = {GetPlayers = function() return players end}
local function FindFirstChild(parent, name) return parent and parent[name] end
local function FindFirstChildOfClass(parent, class) return parent and parent[class] end
local shared, trinket_bot, active_tween_data, Options, Toggles
local emergency_gate_requested, emergency_gate_in_progress, startup_moves, hop_count, restore_count
local utility = {Connection = function(_, event, callback) return event:Connect(callback) end, plain_webhook = function() end}
local library = {Notify = function(_, message) notices[#notices + 1] = message end}
local rs = {RenderStepped = signal(), Heartbeat = signal()}
local lifecycle = {RememberHumanoidState = function() end, Remember = function() end}
function lifecycle:CreateTween(_, root, info, properties)
    local tween = {Completed = signal(), time = info.Time, elapsed = 0, playing = false, pauses = 0, cancelled = false}
    function tween:Play() self.playing = true end
    function tween:Pause() self.playing = false; self.pauses += 1 end
    function tween:Cancel()
        if self.cancelled then return end
        self.cancelled, self.playing = true, false
        self.Completed:Fire(Enum.PlaybackState.Cancelled)
    end
    tween.root, tween.properties = root, properties
    tweens[#tweens + 1] = tween
    return tween
end
local function step(count)
    for _ = 1, count or 1 do
        clock += 0.1
        rs.RenderStepped:Fire()
        for _, tween in ipairs(tweens) do
            if tween.playing then
                tween.elapsed += 0.1
                if tween.elapsed >= tween.time then
                    tween.playing = false
                    tween.root.Position = tween.properties.CFrame.Position
                    tween.Completed:Fire(Enum.PlaybackState.Completed)
                end
            end
        end
        local pending = jobs; jobs = {}
        for _, thread in ipairs(pending) do
            local ok, err = coroutine.resume(thread)
            assert(ok, err)
            if coroutine.status(thread) ~= 'dead' then jobs[#jobs + 1] = thread end
        end
    end
end
local cheat_client = {config = {blatant_mode = true}}
local mem = {HasItem = function() return false end}
local function checkPingAndHop() return false end
local function check_twenty_three_status() return true end
local function restore_bot_state() restore_count += 1 end
local function warn() end
local function tick() return clock end
local ts, droppedTools = {}, {}
local function track_connection(name, connection) trinket_bot.connections[name] = connection; return connection end
local ws = {FindFirstChild = function() return nil end}
local function SafeServerhop() hop_count += 1; task.wait() end
local function get_proximity_distance() return Options.ProximityCheck.Value end
local current_gate_section, player_encounters, proximity_warnings = 0, {}, {}
local function reset()
    clock, jobs, tweens, notices = 0, {}, {}, {}
    plr.Character = character(0); players = {plr}
    shared = {is_unloading = false}
    trinket_bot = {path_running = true, connections = {}, path_points = {{position = Vector3.new(10, 0, 0)}}}
    active_tween_data = {}
    Options = {CriticalDistance = {Value = 60}, ProximityCheck = {Value = 0}, TrinketBotSpeed = {Value = 100}}
    Toggles = {}
    rs.RenderStepped, rs.Heartbeat = signal(), signal()
    emergency_gate_requested, emergency_gate_in_progress, startup_moves, hop_count, restore_count = nil, false, 0, 0, 0
    current_gate_section, player_encounters, proximity_warnings = 0, {}, {}
end
local function addPlayer(x, name)
    local player = {Name = name or 'Nearby', UserId = #players + 1, Character = character(x)}
    players[#players + 1] = player
    return player
end
-- @HELPERS@
-- @STARTUP@
-- @WRAPPER@
-- @PROXIMITY@
