-- language: Lua, file: src/ui/tabs/servers23.lua, target: Roblox Executor
-- 23s Tab UI controls: 23-Max Server Scanner and Auto Joiner

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local library = ctx.library
    local mem = Services.MemStorageService
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local group_23s = Tabs.Servers23:AddLeftGroupbox("23 Scanner")

    group_23s:AddSlider("join_23_target_size", {
        Text = "Minimum Server Size",
        Default = 20,
        Min = 1,
        Max = 22,
        Rounding = 0,
        Compact = false,
        Tooltip = "The minimum player count a 23-max server must have for the bot to join it.",
    })

    group_23s:AddToggle("join_23_servers", {
        Text = "23 Joiner",
        Default = false,
        Tooltip = "Poll for 23-max servers and join when player count meets the minimum target size.",
        Callback = function(value)
            if not value then return end

            if Toggles.anti_afk then
                Toggles.anti_afk:SetValue(true)
            end

            task.spawn(function()
                local PlaceId = game.PlaceId
                local HttpService = Services.HttpService
                local Req = (syn and syn.request) or (http and http.request) or http_request or request
                
                if not Req then
                    if library and library.Notify then library:Notify("Your executor does not support HTTP requests.") end
                    Toggles.join_23_servers:SetValue(false)
                    return
                end
                
                if library and library.Notify then library:Notify("23 Joiner: Polling for target servers...") end
                
                while Toggles.join_23_servers and Toggles.join_23_servers.Value do
                    local cursor = ""
                    local targetFound = false
                    
                    while cursor ~= nil and Toggles.join_23_servers.Value do
                        local targetSize = Options.join_23_target_size.Value
                        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", PlaceId)
                        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
                        
                        local success, response = pcall(function() return Req({ Url = url, Method = "GET" }) end)
                        if not success or not response or response.StatusCode ~= 200 then
                            local fallbackUrl = string.format("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", PlaceId)
                            if cursor ~= "" then fallbackUrl = fallbackUrl .. "&cursor=" .. cursor end
                            success, response = pcall(function() return Req({ Url = fallbackUrl, Method = "GET" }) end)
                        end
                        
                        if success and response and response.StatusCode == 200 then
                            local data = HttpService:JSONDecode(response.Body)
                            if data and data.data then
                                for _, server in ipairs(data.data) do
                                    if server.maxPlayers == 23 and server.playing >= targetSize and server.playing < 23 and server.id ~= game.JobId then
                                        if library and library.Notify then library:Notify("23 Joiner: Found server (" .. server.playing .. "/23). Joining...") end
                                        if mem then mem:SetItem("joined_via_23_joiner", server.id) end
                                        
                                        local rps = Services.ReplicatedStorage
                                        if rps:FindFirstChild("Requests") and rps.Requests:FindFirstChild("JoinPublicServer") then
                                            rps.Requests.JoinPublicServer:FireServer(server.id)
                                        end
                                        targetFound = true
                                        break
                                    end
                                end
                            end
                            if targetFound then break end
                            cursor = data.nextPageCursor
                        else
                            break
                        end
                        task.wait(0.5)
                    end
                    
                    if targetFound then
                        task.wait(10)
                        if mem then mem:RemoveItem("joined_via_23_joiner") end
                    else
                        task.wait(3)
                    end
                end
            end)
        end
    })
end
