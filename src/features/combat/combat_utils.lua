-- language: Lua, file: src/features/combat/combat_utils.lua, target: Roblox Executor
-- Combat Utilities: No Stun, Anti Confusion, Auto Misogi, and Hold Block

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local rs = Services.RunService
    local vim = Services.VirtualInputManager

    -- No Stun & Anti Confusion Loop
    utility:Connection(rs.Heartbeat, function()
        local Toggles = getgenv().Toggles
        if not plr.Character then return end

        if Toggles and Toggles.NoStun and Toggles.NoStun.Value then
            for _, child in ipairs(plr.Character:GetChildren()) do
                if cheat_client.stuns[child.Name] then
                    child:Destroy()
                end
            end
        end

        if Toggles and Toggles.AntiHystericus and Toggles.AntiHystericus.Value then
            local confusion = plr.Character:FindFirstChild("Confusion") or plr.Character:FindFirstChild("Hysteria")
            if confusion then confusion:Destroy() end
        end
    end)

    -- Hold Block handler
    local hold_block_active = false
    function cheat_client.start_hold_block()
        hold_block_active = true
        task.spawn(function()
            while hold_block_active and shared and not shared.is_unloading do
                local Toggles = getgenv().Toggles
                if Toggles and Toggles.HoldBlock and Toggles.HoldBlock.Value then
                    vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                else
                    break
                end
                task.wait(0.2)
            end
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end

    function cheat_client.stop_hold_block()
        hold_block_active = false
        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end
end
