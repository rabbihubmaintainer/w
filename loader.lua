-- language: Lua, file: loader.lua, target: Roblox Executor
-- rabbihub entrypoint loader

local success, isLoaded = pcall(function() return game:IsLoaded() end)
if success and not isLoaded then
    game.Loaded:Wait()
end

local REPO_BASE = "https://raw.githubusercontent.com/rabbihubmaintainer/w/main/"

local function load_init()
    -- Try local file first
    if isfile and isfile("src/init.lua") then
        local content = readfile("src/init.lua")
        local fn, err = loadstring(content, "@src/init.lua")
        if fn then
            return fn()(REPO_BASE)
        else
            warn("[rabbihub] Local init compile failed: " .. tostring(err))
        end
    end

    -- Fall back to remote GitHub raw
    local res = game:HttpGet(REPO_BASE .. "src/init.lua", true)
    local fn, err = loadstring(res, "@src/init.lua")
    if fn then
        return fn()(REPO_BASE)
    else
        error("[rabbihub] Remote init failed: " .. tostring(err), 2)
    end
end

return load_init()
