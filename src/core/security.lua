-- language: Lua, file: src/core/security.lua, target: Roblox Executor
-- Anticheat bypasses, security hooks, and executor capability verification

return function(ctx)
    local Services = ctx.Services
    local Players = Services.Players

    -- Stubs
    loadstring([[
        function LPH_NO_VIRTUALIZE(f) return f end;
        function LPH_ENCSTR(f) return f end;
        LPH_OBFUSCATED = false;
    ]])();

    pcall(loadstring([[if not HXD_HWID then HXD_HWID="STUB_HWID" HXD_DISCORD_ID="123456789" HXD_EXPIRES_AT=os.time()+2592000 HXD_STATUS="active" HXD_EXECUTION_COUNT=1 HXD_SECONDS_LEFT=2592000 HXD_UserNote="beta" end]]));
    pcall(loadstring([[if not HXD_SANITIZE then function HXD_SANITIZE(value,pattern)if not value or not pattern then return""end;value=tostring(value)local charset=pattern:match("%[(.-)%]")if not charset then return""end;local _,max=pattern:match("{%s*(%d+)%s*,%s*(%d+)%s*}")local max_len=tonumber(max)or#value;local extra_chars="→←↑↓★☆"charset=charset:gsub("%]","%%]")value=value:gsub("[^"..charset..extra_chars.."]","")return value:sub(1,max_len)end end]]));

    -- Global Webhook Bridge
    do
        local existing = rawget(getgenv(), "HXD_SEND_WEBHOOK")
        if not existing or (type(existing) ~= "function" and type(existing) ~= "table") then
            getgenv().HXD_SEND_WEBHOOK = function(url, data)
                local req = http_request or request or (syn and syn.request)
                if not req then return false end
                local body = game:GetService("HttpService"):JSONEncode(data)
                local ok, res = pcall(req, {
                    Url = url, 
                    Method = "POST", 
                    Headers = {["Content-Type"] = "application/json"}, 
                    Body = body
                })
                if not ok then return false end
                if type(res) ~= "table" then return true end
                local code = res.StatusCode or res.statusCode or 200
                return code >= 200 and code < 300
            end
        end
    end

    -- Anticheat mode loader
    local anticheat_mode = "Normal"
    pcall(function()
        if isfile and readfile and isfile("rabbihub/anticheat_mode.txt") then
            local saved_mode = readfile("rabbihub/anticheat_mode.txt")
            if saved_mode == "Kick" or saved_mode == "Normal" then
                anticheat_mode = saved_mode
            end
        end
    end)
    ctx.anticheat_mode = anticheat_mode

    -- Executor Compatibility Validation
    local Required = {
        "hookfunction",
        "getconnections",
        "hookmetamethod",
        "bit32",
        "getgenv",
        "setmetatable",
        "clonefunction",
        "cloneref",
        "fireclickdetector",
        "checkcaller"
    }

    local Kick = clonefunction and clonefunction(Players.LocalPlayer.Kick) or Players.LocalPlayer.Kick
    for i = 1, #Required do
        local v = Required[i]
        if not getgenv()[v] then
            Kick(Players.LocalPlayer, "bad executor sorry kid")
        end
    end

    -- Anticheat Hooks Setup
    if not getgenv().lolololol then
        local old_destroy = nil
        old_destroy = hookfunction(workspace.Destroy, function(Self)
            if not checkcaller() then
                if tostring(Self) == "CharacterHandler" then
                    return
                end
            end
            return old_destroy(Self)
        end)

        if anticheat_mode == "Kick" then
            task.spawn(function()
                local cw
                local lockThreads = {}

                cw = hookfunction(coroutine.wrap, newcclosure(function(f, ...)
                    if not checkcaller() then
                        if type(f) == "function" and islclosure(f) then
                            local consts, upvals = getconstants(f), getupvalues(f)
                            local g3 = getfenv(3)

                            if typeof(upvals[2]) == "Instance" and upvals[2]:IsA("AnimationTrack") and upvals[1] == upvals[2].Play then
                                lockThreads[g3] = true
                            end

                            if consts[1] == "scr" and consts[2] == "Parent" then
                                lockThreads[g3] = true
                            end

                            if consts[1] == "coroutine" and consts[2] == "create" and table.find(consts, "dead") then
                                lockThreads[g3] = true
                            end

                            if g3 and lockThreads[g3] then
                                local plrs_local = Services.Players
                                while true do
                                    plrs_local.LocalPlayer:Kick("Ban Attempt")
                                    task.wait()
                                end
                            end
                        end

                        if lockThreads[getfenv(3)] then
                            return function() end
                        end
                    end

                    return cw(f, ...)
                end))
            end)
        else
            LPH_NO_VIRTUALIZE(function()
                local type = type
                local getupvalues = getupvalues
                local islclosure = islclosure
                local EmptyFunc = function() end
                local RunService = Services.RunService
                local debug_info = debug.info

                local old
                old = hookfunction(coroutine.wrap, newcclosure(function(func)
                    if not checkcaller() then
                        if type(func) == "function" and islclosure(func) then
                            local upvals = getupvalues(func)
                            if #upvals == 1 then
                                if upvals[1] == RunService then
                                    return old(EmptyFunc)
                                end
                            end
                        end

                        local stackfunc = debug_info(5, "n")
                        if stackfunc and stackfunc == "pcall" then
                            return
                        end
                    end
                    return old(func)
                end))
            end)()
        end
    end
end
