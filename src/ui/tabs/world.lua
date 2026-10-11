-- language: Lua, file: src/ui/tabs/world.lua, target: Roblox Executor
-- World tab UI controls: World Settings (Freecam, No Killbrick, No Fall, Mob Trigger, Textures, Proximity) and Environment (Fullbright, No Fog, Clock Time, No Blindness/Blur/Sanity)

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local lit = Services.Lighting
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local ws = Services.Workspace
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local FindFirstChild = game.FindFirstChild
    local FindFirstChildOfClass = game.FindFirstChildOfClass

    local group_world = Tabs.World:AddLeftGroupbox("World Settings")

    group_world:AddToggle("freecam", {
        Text = "Freecam",
        Default = false,
        Callback = function(state)
            local camera = ws.CurrentCamera
            if plr.Character then
                local humanoid, torso = FindFirstChildOfClass(plr.Character, "Humanoid"), FindFirstChild(plr.Character, "Torso")
                if humanoid and torso then
                    if state then
                        camera.CameraType = Enum.CameraType.Scriptable
                        if cheat_client.start_freecam_rendering then cheat_client.start_freecam_rendering() end
                    else
                        camera.CameraType = Enum.CameraType.Custom
                        camera.CameraSubject = humanoid
                        if cheat_client.stop_freecam_rendering then cheat_client.stop_freecam_rendering() end
                    end
                end
            end
        end
    }):AddKeyPicker("FreecamKeybind", {
        Default = cheat_client.config.freecam_keybind,
        Text = "Freecam Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.FreecamKeybind:OnChanged(function()
        cheat_client.config.freecam_keybind = Options.FreecamKeybind.Value
    end)

    group_world:AddSlider("freecam_speed", {
        Text = "Freecam Speed",
        Default = cheat_client.config.freecam_speed or 1,
        Min = 0,
        Max = 12,
        Rounding = 1,
        Callback = function(value) cheat_client.config.freecam_speed = value end
    })

    group_world:AddDivider()

    group_world:AddToggle("no_fall", {
        Text = "No Fall Damage",
        Default = cheat_client.config.no_fall,
        Callback = function(value) cheat_client.config.no_fall = value end
    })

    group_world:AddToggle("temperature_lock", {
        Text = "Temperature Lock",
        Default = cheat_client.config.temperature_lock,
        Tooltip = "!!! Disables trinkets from spawning",
        Callback = function(value) cheat_client.config.temperature_lock = value end
    })

    group_world:AddDivider()

    group_world:AddToggle("proximity_notifier", {
        Text = "Proximity Notifier",
        Default = cheat_client.config.proximity_notifier
    })

    Toggles.proximity_notifier:OnChanged(function(enabled)
        cheat_client.config.proximity_notifier = enabled
        if enabled and cheat_client.proximity_setup then cheat_client.proximity_setup()
        elseif not enabled and cheat_client.proximity_cleanup then cheat_client.proximity_cleanup() end
    end)

    group_world:AddToggle("proximity_ignore_allies", {
        Text = "Ignore Allies",
        Default = cheat_client.config.proximity_ignore_allies,
        Tooltip = "Don't notify when allies are nearby"
    })

    Toggles.proximity_ignore_allies:OnChanged(function(value)
        cheat_client.config.proximity_ignore_allies = value
    end)

    -- Environment Groupbox
    local group_environment = Tabs.World:AddRightGroupbox("Environment")

    group_environment:AddToggle("fullbright", {
        Text = "Fullbright",
        Default = cheat_client.config.fullbright,
        Callback = function(state)
            cheat_client.config.fullbright = state
            if state then
                if lit:FindFirstChild("areacolor") then lit.areacolor.Enabled = false end
                local brightness_multiplier = cheat_client.config.brightness_level / 100
                local color = Color3.new(brightness_multiplier, brightness_multiplier, brightness_multiplier)
                lit.Ambient = color
                lit.OutdoorAmbient = color
                lit.Brightness = 1 + (brightness_multiplier * 2)
            else
                if lit:FindFirstChild("areacolor") then lit.areacolor.Enabled = true end
                lit.Brightness = 1
                if cheat_client.restore_ambience then cheat_client:restore_ambience() end
            end
        end
    }):AddKeyPicker("FullbrightKeybind", {
        Default = cheat_client.config.fullbright_keybind,
        Text = "Fullbright Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.FullbrightKeybind:OnChanged(function()
        cheat_client.config.fullbright_keybind = Options.FullbrightKeybind.Value
    end)

    group_environment:AddSlider("brightness_level", {
        Text = "Brightness Level",
        Default = cheat_client.config.brightness_level,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Callback = function(value)
            cheat_client.config.brightness_level = value
            if cheat_client.config.fullbright then
                local brightness_multiplier = value / 100
                local color = Color3.new(brightness_multiplier, brightness_multiplier, brightness_multiplier)
                lit.Ambient = color
                lit.OutdoorAmbient = color
                lit.Brightness = 1 + (brightness_multiplier * 2)
            end
        end
    })

    group_environment:AddToggle("no_fog", {
        Text = "No Fog",
        Default = cheat_client.config.no_fog,
        Callback = function(state)
            cheat_client.config.no_fog = state
            if state then
                lit.FogColor = Color3.fromRGB(254, 254, 254)
                lit.FogEnd = 100000
                lit.FogStart = 50
            else
                if cheat_client.restore_ambience then cheat_client:restore_ambience() end
            end
        end
    }):AddKeyPicker("NoFogKeybind", {
        Default = cheat_client.config.no_fog_keybind,
        Text = "No Fog Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.NoFogKeybind:OnChanged(function()
        cheat_client.config.no_fog_keybind = Options.NoFogKeybind.Value
    end)

    group_environment:AddToggle("change_time", {
        Text = "Change Time",
        Default = cheat_client.config.change_time,
        Callback = function(state)
            cheat_client.config.change_time = state
            if state then
                lit.ClockTime = Options and Options.clock_time and Options.clock_time.Value or 12
            end
        end
    })

    group_environment:AddSlider("clock_time", {
        Text = "Time",
        Default = cheat_client.config.clock_time,
        Min = 1,
        Max = 24,
        Rounding = 1,
        Callback = function(value)
            cheat_client.config.clock_time = value
            if Toggles.change_time and Toggles.change_time.Value then lit.ClockTime = value end
        end
    })

    group_environment:AddToggle("no_blindness", {
        Text = "No Blindness",
        Default = cheat_client.config.no_blindness,
        Callback = function(state)
            cheat_client.config.no_blindness = state
            local b = lit:FindFirstChild("Blindness")
            if b then b.Enabled = not state end
        end
    })

    group_environment:AddToggle("no_blur", {
        Text = "No Blur",
        Default = cheat_client.config.no_blur,
        Callback = function(state)
            cheat_client.config.no_blur = state
            local b = lit:FindFirstChild("Blur")
            if b then b.Enabled = not state end
        end
    })

    group_environment:AddToggle("no_sanity", {
        Text = "No Sanity",
        Default = cheat_client.config.no_sanity,
        Callback = function(state)
            cheat_client.config.no_sanity = state
            local s = lit:FindFirstChild("Sanity")
            if s then s.Enabled = not state end
        end
    })
end
