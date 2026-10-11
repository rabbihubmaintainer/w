-- language: Lua, file: src/ui/tabs/interface.lua, target: Roblox Executor
-- Interface tab UI controls: UI Settings, Notifications, Blatant Mode, Safety, and Keybinds

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local library = ctx.library
    local anticheat_mode = ctx.anticheat_mode or "Normal"
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local group_ui = Tabs.Interface:AddLeftGroupbox("UI Settings")

    group_ui:AddToggle("notifications", {
        Text = "Notifications",
        Default = cheat_client.config.notifications,
        Callback = function(state) cheat_client.config.notifications = state end
    })

    group_ui:AddSlider("notification_volume", {
        Text = "Notification Volume",
        Default = cheat_client.config.notification_volume or 5,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Compact = false,
        Callback = function(value) cheat_client.config.notification_volume = value end
    })

    group_ui:AddToggle("blatant_mode", {
        Text = "Blatant Mode",
        Default = cheat_client.config.blatant_mode,
        Callback = function(state)
            cheat_client.config.blatant_mode = state
            for _, featureName in pairs(shared.blatant_features) do
                local toggle = Toggles[featureName]
                if toggle then
                    if state then
                        toggle:SetDisabled(false)
                        if toggle.Value ~= nil then toggle:SetValue(toggle.Value) end
                    else
                        if toggle.Value then toggle:SetValue(false) end
                        toggle:SetDisabled(true)
                    end
                end
            end
        end
    })

    group_ui:AddDivider()
    group_ui:AddLabel("Safety & Security")

    group_ui:AddDropdown("AnticheatMode", {
        Text = "Anti-Cheat Mode",
        Values = {"Normal", "Kick"},
        Default = anticheat_mode == "Kick" and 2 or 1,
        Tooltip = "Normal: Silent bypass | Kick: Locks you in kick loop on detection (requires reload to apply)",
        Callback = function(value)
            cheat_client.config.anticheat_mode = value
            pcall(function()
                if writefile then writefile("rabbihub/anticheat_mode.txt", value) end
            end)
        end
    })

    -- Keybinds Groupbox
    local group_keybinds = Tabs.Interface:AddRightGroupbox("Keybind Settings")

    group_keybinds:AddLabel("Instant Menu Key"):AddKeyPicker("MenuKey", {
        Default = cheat_client.config.instant_menu_keybind,
        Text = "Instant Menu",
        Mode = "Press",
        Callback = function(Value)
            local rps = Services.ReplicatedStorage
            if rps:FindFirstChild("Requests") and rps.Requests:FindFirstChild("ReturnToMenu") then
                rps.Requests.ReturnToMenu:InvokeServer()
            end
        end
    })

    Options.MenuKey:OnChanged(function()
        cheat_client.config.instant_menu_keybind = Options.MenuKey.Value
    end)
end
