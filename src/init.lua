-- language: Lua, file: src/init.lua, target: Roblox Executor
-- Master modular initialization pipeline for rabbihub

return function(base_url)
    local REPO_URL = base_url or "https://raw.githubusercontent.com/rabbihubmaintainer/w/main/"
    local loaded_cache = {}

    local function import(path)
        if loaded_cache[path] then
            return loaded_cache[path]
        end

        local code = nil
        -- 1. Try local disk read
        local local_path = "src/" .. path .. ".lua"
        if isfile and isfile(local_path) then
            code = readfile(local_path)
        elseif isfile and isfile(path .. ".lua") then
            code = readfile(path .. ".lua")
        else
            -- 2. Fall back to remote HttpGet
            local remote_url = REPO_URL .. "src/" .. path .. ".lua"
            local ok, res = pcall(function()
                return game:HttpGet(remote_url, true)
            end)
            if ok and res then
                code = res
            else
                error("[rabbihub] Failed to load module: " .. path .. " from " .. remote_url, 2)
            end
        end

        local fn, err = loadstring(code, "@" .. path)
        if not fn then
            error("[rabbihub] Syntax error in module " .. path .. ": " .. tostring(err), 2)
        end

        local result = fn()
        loaded_cache[path] = result
        return result
    end

    -- Context table shared across all modules
    local ctx = {
        repo_url = REPO_URL,
        import = import,
        loaded_cache = loaded_cache
    }

    -- 1. Core Services and State
    ctx.Services = import("core/services")
    import("core/state")(ctx)
    import("core/config")(ctx)
    import("core/security")(ctx)
    import("core/utility")(ctx)
    import("core/game_client")(ctx)

    -- 2. UI Window and Linoria Library
    import("ui/window")(ctx)

    -- 3. UI Tab Sections
    import("ui/tabs/combat")(ctx)
    import("ui/tabs/visuals")(ctx)
    import("ui/tabs/world")(ctx)
    import("ui/tabs/exploits")(ctx)
    import("ui/tabs/movement")(ctx)
    import("ui/tabs/automation")(ctx)
    import("ui/tabs/misc")(ctx)
    import("ui/tabs/servers23")(ctx)
    import("ui/tabs/botting")(ctx)
    import("ui/tabs/macros")(ctx)
    import("ui/tabs/interface")(ctx)
    import("ui/tabs/config")(ctx)

    -- 4. Feature Execution Engines
    import("features/combat/parry")(ctx)
    import("features/combat/silent_aim")(ctx)
    import("features/combat/combat_utils")(ctx)
    import("features/visuals/player_esp")(ctx)
    import("features/visuals/chams")(ctx)
    import("features/visuals/world_esp")(ctx)
    import("features/movement/flight")(ctx)
    import("features/automation/auto_bag")(ctx)

    -- 5. Unload Handler
    function ctx.unload()
        ctx.shared.is_unloading = true
        if ctx.shared.connections then
            for _, conn in ipairs(ctx.shared.connections) do
                if conn and conn.Connected then conn:Disconnect() end
            end
        end
        if ctx.library and ctx.library.Unload then
            ctx.library:Unload()
        end
    end

    -- 6. Server-Hop Re-injection Setup
    local queue_func = queue_on_teleport or (syn and syn.queue_on_teleport) or queue_teleport
    if queue_func then
        pcall(function()
            local teleport_loader = [[
                local success, code = pcall(function() 
                    return game:HttpGet("]] .. REPO_URL .. [[loader.lua") 
                end) 
                if success and code then 
                    local fn = loadstring(code) 
                    if fn then fn() end 
                end
            ]]
            queue_func(teleport_loader)
        end)
    end

    return ctx
end
