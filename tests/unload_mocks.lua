-- These tests run extracted production functions against small Roblox API doubles.
-- They do not load the game, install executor hooks, or contact any remote service.
local function makeSession(options)
    options = options or {}
    local warnings, hook_calls, scheduled, cancelled, unbound, removed_memory = {}, {}, {}, {}, {}, {}
    local environment = {loaded = {}}
    local function getgenv() return environment end
    local function warn(message) warnings[#warnings + 1] = message end
    local function resume(thread, ...)
        local ok, value = coroutine.resume(thread, ...)
        assert(ok, tostring(value))
        return thread
    end
    local task = {}
    function task.spawn(thread, ...) scheduled[thread] = true; return resume(thread, ...) end
    function task.defer(thread, ...) scheduled[thread] = table.pack(...); return thread end
    function task.delay(_, thread, ...) scheduled[thread] = table.pack(...); return thread end
    function task.wait() return coroutine.yield() end
    function task.cancel(thread)
        assert(thread ~= coroutine.running(), "Attempted to cancel the unload caller")
        cancelled[thread] = true
        scheduled[thread] = nil
        coroutine.close(thread)
    end
    local function advance()
        local snapshot = {}
        for thread, arguments in pairs(scheduled) do snapshot[thread] = arguments end
        for thread, arguments in pairs(snapshot) do
            if not cancelled[thread] and coroutine.status(thread) ~= "dead" then
                if type(arguments) == "table" then
                    scheduled[thread] = true
                    resume(thread, table.unpack(arguments, 1, arguments.n))
                else
                    resume(thread)
                end
            end
            if coroutine.status(thread) == "dead" then scheduled[thread] = nil end
        end
    end
    local function signal()
        local listeners = {}
        return {
            Connect = function(_, callback)
                local connection = {Connected = true}
                function connection:Disconnect() self.Connected = false end
                listeners[connection] = callback
                return connection
            end,
            Fire = function(_, ...)
                for connection, callback in pairs(listeners) do
                    if connection.Connected then
                        local thread = coroutine.create(callback)
                        scheduled[thread] = true
                        resume(thread, ...)
                    end
                end
            end,
        }
    end
    local function object(name)
        local result = {Name = name, Parent = {}, destroyed = 0, children = {}}
        function result:Destroy() self.destroyed += 1; self.Parent = nil end
        function result:GetDescendants() return self.children end
        function result:FindFirstChild(child) return self[child] end
        function result:IsA(kind) return self.ClassName == kind end
        return result
    end
    local Instance = {new = function(name) return object(name) end}
    local function hookfunction(target, replacement)
        hook_calls[#hook_calls + 1] = {target = target, replacement = replacement}
        if options.broken_restore and target == replacement then error("restore unsupported") end
        return target
    end
    local function hookmetamethod(target, name, replacement)
        hook_calls[#hook_calls + 1] = {target = target, name = name, replacement = replacement}
        return options.original_metamethod or function() end
    end
    -- @PRODUCTION_LIFECYCLE@
    lifecycle.initialization_thread = nil
    local function typeof(value) return type(value) end
    local Vector2 = {new = function(x, y) return {X = x or 0, Y = y or 0} end}
    local Drawing = {new = function(kind)
        return {kind = kind, TextBounds = Vector2.new(30, 10), Remove = function(self)
            if self.removed then error("drawing was already removed") end
            self.removed = true
        end}
    end}
    local ws = {CurrentCamera = {ViewportSize = Vector2.new(800, 600)}}
    local hidden_folder = Instance.new("Folder")
    local humanoid = object("Humanoid")
    local plr = {PlayerGui = object("PlayerGui"), Character = {Humanoid = humanoid}, Backpack = {}}
    if options.no_character then plr.Character = nil end
    local function FindFirstChild(parent, name) return parent and parent[name] end
    local function FindFirstChildOfClass(parent, name) return parent and parent[name] end
    local shared = {
        is_unloading = false, connections = {}, hidden_connections = {},
        drawing_containers = {esp = {}, menu = {}}, accents = {}, theme = {},
    }
    local cheat_client = {trinket_bot = {path_running = true}}
    local utility = {}
    local streamer_connections, hooked_connections, disabled_connections = {}, {}, {}
    local original_names, original_days, original_materials, transparent_parts, playerLabels, mana_overlay, watched_guis = {}, {}, {}, {}, {}, {}, {}
    local auto_pot_active, auto_craft_active = true, true
    local teleport_init_failed_connection
    local cas = {UnbindAction = function(_, name) unbound[name] = true end}
    local memory = {RemoveItem = function(_, name)
        if options.bad_memory == name then error("memory unavailable") end
        removed_memory[name] = true
    end}
    local mem = memory
    local render = {QualityLevel = 10}
    local function settings() return {Rendering = render} end
    local fps_cap
    local function setfpscap(value) fps_cap = value end
    local Enum = {CameraType = {Custom = "Custom"}}
    local cpu = {status = {active = true}, services = {
        ms = 0.7, ql = 5, ugs = {}, rs = {Set3dRenderingEnabled = function(self, value) self.enabled = value end},
    }}
    local key = "loaded"
    -- @PRODUCTION_DRAWING@
    -- @PRODUCTION_CONNECTION@
    -- @PRODUCTION_UNLOAD@
    return {
        lifecycle = lifecycle, task = task, utility = utility, shared = shared, client = cheat_client,
        warnings = warnings, hooks = hook_calls, instance = Instance, cancelled = cancelled,
        hookfunction = hookfunction, hookmetamethod = hookmetamethod,
        advance = advance, signal = signal, object = object, plr = plr, camera = ws.CurrentCamera,
        original_days = original_days, transparent_parts = transparent_parts,
        original_materials = original_materials, memory = removed_memory, cpu = cpu,
        unbound = unbound, environment = environment, hidden = hidden_folder,
        fps = function() return fps_cap end,
    }
end
