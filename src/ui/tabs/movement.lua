-- language: Lua, file: src/ui/tabs/movement.lua, target: Roblox Executor
-- Movement tab UI controls: Flight, Better Flight, Noclip, SpeedBoost, and Auto Fall

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local library = ctx.library
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local FindFirstChild = game.FindFirstChild
    local FindFirstChildOfClass = game.FindFirstChildOfClass

    local group_flight = Tabs.Movement:AddLeftGroupbox("Flight")

    group_flight:AddToggle("flight", {
        Text = "Flight",
        Tooltip = "good for flying on the ground",
        Default = false,
        Callback = function(value)
            if value then
                if cheat_client.start_flight_rendering then cheat_client.start_flight_rendering() end
            else
                if cheat_client.stop_flight_rendering then cheat_client.stop_flight_rendering() end
            end
        end
    }):AddKeyPicker("FlightKeybind", {
        Default = cheat_client.config.flight_keybind,
        Text = "Flight Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.FlightKeybind:OnChanged(function()
        cheat_client.config.flight_keybind = Options.FlightKeybind.Value
    end)

    group_flight:AddToggle("noclip", {
        Text = "Noclip",
        Tooltip = "separate from better flight",
        Default = cheat_client.config.noclip,
        Callback = function(value) cheat_client.config.noclip = value end
    }):AddKeyPicker("NoclipKeybind", {
        Default = cheat_client.config.noclip_keybind,
        Text = "Noclip Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.NoclipKeybind:OnChanged(function()
        cheat_client.config.noclip_keybind = Options.NoclipKeybind.Value
    end)

    group_flight:AddToggle("auto_fall", {
        Text = "Auto Fall",
        Default = cheat_client.config.auto_fall,
        Callback = function(value) cheat_client.config.auto_fall = value end
    })

    group_flight:AddSlider("flight_speed", {
        Text = "Speed",
        Default = cheat_client.config.flight_speed,
        Min = 0,
        Max = 145,
        Rounding = 1,
        Callback = function(value) cheat_client.config.flight_speed = value end
    })

    group_flight:AddDivider()

    if game.PlaceId ~= 14341521240 then
        group_flight:AddToggle("better_flight", {
            Text = "Better Flight",
            Tooltip = "good for looting",
            Default = cheat_client.config.better_flight,
            Callback = function(state)
                cheat_client.config.better_flight = state
                if plr.Character then
                    local huma = FindFirstChildOfClass(plr.Character, "Humanoid")
                    if huma then
                        if state then
                            huma:SetStateEnabled(5, false)
                            huma:ChangeState(3)
                            if cheat_client.start_better_flight then cheat_client.start_better_flight() end
                        else
                            if cheat_client.stop_better_flight then cheat_client.stop_better_flight() end
                            for _, part in ipairs(plr.Character:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                    if part.Name == "Head" or part.Name == "Torso" then
                                        part.CanCollide = true
                                    else
                                        part.CanCollide = false
                                    end
                                end
                            end
                            if huma then
                                huma:SetStateEnabled(5, true)
                                huma:ChangeState(5)
                            end
                            local rootPart = FindFirstChild(plr.Character, "HumanoidRootPart")
                            if rootPart then rootPart.Anchored = false end
                        end
                    end
                end
            end
        })

        group_flight:AddLabel("Better Flight Keybind"):AddKeyPicker("BetterFlightKeybind", {
            Default = cheat_client.config.better_flight_keybind,
            Text = "Better Flight Toggle",
            Mode = "Toggle",
            Callback = function(Value)
                local blatant_mode_enabled = Toggles.blatant_mode and Toggles.blatant_mode.Value
                if blatant_mode_enabled and Toggles.better_flight then
                    Toggles.better_flight:SetValue(not Toggles.better_flight.Value)
                end
            end
        })

        Options.BetterFlightKeybind:OnChanged(function()
            cheat_client.config.better_flight_keybind = Options.BetterFlightKeybind.Value
        end)
    end

    local group_movement = Tabs.Movement:AddRightGroupbox("Movement")

    group_movement:AddToggle("speed_boost", {
        Text = "SpeedBoost",
        Default = cheat_client.config.speed_boost or false,
        Callback = function(value) cheat_client.config.speed_boost = value end
    })

    local last_speed_notif = 0
    group_movement:AddSlider("speed_boost_value", {
        Text = "Speed",
        Default = cheat_client.config.speed_boost_value or 16,
        Min = 0.1,
        Max = 250,
        Rounding = 1,
        Compact = false,
        Callback = function(value)
            local blatant_mode_enabled = Toggles.blatant_mode and Toggles.blatant_mode.Value
            if not blatant_mode_enabled and value > 20 then
                Options.speed_boost_value:SetValue(20)
                local now = tick()
                if now - last_speed_notif > 2 then
                    if library and library.Notify then library:Notify("Speed limited to 20 (blatant mode disabled)") end
                    last_speed_notif = now
                end
                return
            end
            cheat_client.config.speed_boost_value = value
        end
    })
end
