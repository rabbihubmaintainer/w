-- language: Lua, file: src/ui/tabs/misc.lua, target: Roblox Executor
-- Misc tab UI controls: Misc Settings, Server Info, Server Join, and Spoofing

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local library = ctx.library
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local rs = Services.RunService
    local rps = Services.ReplicatedStorage
    local cs = Services.CollectionService
    local txt = Services.TextChatService
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local FindFirstChild = game.FindFirstChild

    local group_misc = Tabs.Misc:AddLeftGroupbox("Misc Settings")

    local function wait_danger()
        while shared and not shared.is_unloading and cs:HasTag(plr.Character, "Danger") and not (Toggles and Toggles.ignore_danger and Toggles.ignore_danger.Value) do
            rs.Heartbeat:Wait()
        end
    end

    group_misc:AddButton({
        Text = "Unblock All",
        DoubleClick = true,
        Func = function() utility:UnblockAll() end
    })

    group_misc:AddButton({
        Text = "Reconnect",
        DoubleClick = true,
        Func = function()
            wait_danger()
            if rps:FindFirstChild("Requests") and FindFirstChild(rps.Requests, "ReturnToMenu") and plr.Character then
                rps.Requests.ReturnToMenu:InvokeServer()
            end
            utility:ForceRejoin()
        end
    })

    group_misc:AddButton({
        Text = "Serverhop",
        DoubleClick = true,
        Func = function()
            wait_danger()
            if rps:FindFirstChild("Requests") and FindFirstChild(rps.Requests, "ReturnToMenu") and plr.Character then
                rps.Requests.ReturnToMenu:InvokeServer()
            end
            utility:Serverhop()
        end
    })

    group_misc:AddToggle("roblox_chat", {
        Text = "Roblox Chat",
        Default = cheat_client.config.roblox_chat,
        Callback = function(state)
            if txt:FindFirstChild("ChatWindowConfiguration") then
                txt.ChatWindowConfiguration.Enabled = state
            end
            cheat_client.config.roblox_chat = state
        end
    })

    group_misc:AddToggle("gate_anti_backfire", {
        Text = "Gate Anti Backfire",
        Default = cheat_client.config.gate_anti_backfire,
        Callback = function(value) cheat_client.config.gate_anti_backfire = value end
    })

    -- Server Info
    local group_timers = Tabs.Misc:AddRightGroupbox("Server Info")
    group_timers:AddLabel("PlrsServer", { Text = "Players: " .. #plrs:GetPlayers(), DoesWrap = false })
    group_timers:AddLabel("InventoryValue", { Text = "Inventory Value: 0", DoesWrap = false })

    -- Server Join
    local group_server_join = Tabs.Misc:AddRightGroupbox("Server Join")
    local target_job_id = ""

    group_server_join:AddInput("TargetJobId", {
        Default = "",
        Numeric = false,
        Finished = true,
        Text = "Job ID",
        Placeholder = "Paste JobId here",
        Callback = function(value) target_job_id = value end
    })

    group_server_join:AddButton({
        Text = "Join by Job ID",
        Func = function()
            if target_job_id ~= "" and rps:FindFirstChild("Requests") and rps.Requests:FindFirstChild("JoinPublicServer") then
                wait_danger()
                rps.Requests.JoinPublicServer:FireServer(target_job_id)
            end
        end
    })
end
