-- language: Lua, file: src/ui/tabs/combat.lua, target: Roblox Executor
-- Combat tab UI controls: Combat Utilities, Auto Parry, Parry Settings, and Silent Aim

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local group_combat_utils = Tabs.Combat:AddLeftGroupbox("Combat Utilities")

    group_combat_utils:AddToggle("NoStun", {
        Text = "No Stun",
        Default = cheat_client.config.no_stun
    })

    group_combat_utils:AddToggle("AntiHystericus", {
        Text = "No Confusion",
        Default = cheat_client.config.anti_confusion
    })

    group_combat_utils:AddToggle("PerfloraTeleport", {
        Text = "Perflora Teleport",
        Default = cheat_client.config.perflora_teleport
    })

    group_combat_utils:AddDivider()

    group_combat_utils:AddLabel("Attach to Back"):AddKeyPicker("AttachToBackKeybind", {
        Default = cheat_client.config.attach_to_back_keybind,
        Text = "Attach to Back",
    })

    Options.AttachToBackKeybind:OnChanged(function()
        cheat_client.config.attach_to_back_keybind = Options.AttachToBackKeybind.Value
    end)

    group_combat_utils:AddDivider()

    group_combat_utils:AddToggle("better_mana", {
        Text = "Better Mana Charge",
        Default = cheat_client.config.better_mana,
        Callback = function(value)
            cheat_client.config.better_mana = value
        end
    })

    group_combat_utils:AddToggle("BetterUnequip", {
        Text = "Better Unequip",
        Default = cheat_client.config.better_unequip or false,
        Tooltip = "When your Dagger/Sword is removed, instantly equips a skill to cancel the animation then unequips",
        Callback = function(value)
            cheat_client.config.better_unequip = value
        end
    })

    group_combat_utils:AddDivider()

    group_combat_utils:AddToggle("AutoMisogi", {
        Text = "Auto Misogi",
        Default = cheat_client.config.auto_misogi
    })

    group_combat_utils:AddToggle("AntiBackfireViribus", {
        Text = "Anti Backfire Viribus",
        Default = cheat_client.config.anti_backfire_viribus
    })

    group_combat_utils:AddDivider()

    group_combat_utils:AddToggle("HoldBlock", {
        Text = "Hold Block (F)",
        Default = cheat_client.config.hold_block
    })

    group_combat_utils:AddSlider("HoldBlockDelay", {
        Text = "Block Delay (ms)",
        Default = cheat_client.config.hold_block_delay,
        Min = 0,
        Max = 1000,
        Rounding = 0,
        Compact = true
    })

    local group_auto_parry = Tabs.Combat:AddRightGroupbox("Auto Parry")

    group_auto_parry:AddToggle("AutoPerfectBlock", {
        Text = "Auto Perfect Block",
        Default = cheat_client.config.auto_perfect_block
    })

    group_auto_parry:AddDropdown("ParryAbilities", {
        Values = {"Viribus", "Owlslash", "Shadowrush", "Verdien", "Grapple"},
        Default = 1,
        Multi = true,
        Text = "Parry Abilities",
        Tooltip = "Select which abilities to auto parry"
    })

    local group_parry_settings = Tabs.Combat:AddLeftGroupbox("Parry Settings")

    group_parry_settings:AddToggle("ParryPingAdjust", {
        Text = "Ping Adjustment",
        Default = cheat_client.config.parry_ping_adjust
    })

    group_parry_settings:AddToggle("ParryCustomDelay", {
        Text = "Use Custom Delay",
        Default = cheat_client.config.parry_custom_delay
    })

    group_parry_settings:AddSlider("ParryCustomDelayMs", {
        Text = "Custom Delay",
        Default = cheat_client.config.custom_delay,
        Min = -500,
        Max = 500,
        Rounding = 1
    })

    group_parry_settings:AddSlider("ParryFovAngle", {
        Text = "Parry FOV Angle",
        Default = cheat_client.config.parry_fov_angle,
        Min = 0,
        Max = 360,
        Rounding = 1
    })

    group_parry_settings:AddToggle("ParryDisableWhenUnfocused", {
        Text = "Disable When Window Unfocused",
        Default = cheat_client.config.parry_disable_when_unfocused
    })

    group_parry_settings:AddToggle("ParryIgnoreVisibility", {
        Text = "Ignore Visibility (Blatant)",
        Default = cheat_client.config.parry_ignore_visibility
    })

    group_parry_settings:AddToggle("ParrySemiBlatantBlock", {
        Text = "Semi-Blatant Block",
        Default = cheat_client.config.parry_semi_blatant_block
    })

    local group_silent_aim = Tabs.Combat:AddRightGroupbox("Silent Aim")

    group_silent_aim:AddToggle("SilentAim", {
        Text = "Silent Aim",
        Default = cheat_client.config.silent_aim
    })

    group_silent_aim:AddSlider("SilentAimFov", {
        Text = "FOV",
        Default = cheat_client.config.fov,
        Min = 0,
        Max = 200,
        Rounding = 1
    })

    group_silent_aim:AddToggle("IgnoreBlocking", {
        Text = "Ignore Blocking Players",
        Default = cheat_client.config.ignore_blocking,
        Tooltip = "Don't target players who are blocking"
    })

    group_silent_aim:AddToggle("HideFovCircle", {
        Text = "Hide FOV Circle",
        Default = cheat_client.config.hide_fov_circle
    })

    group_silent_aim:AddToggle("SilentAimVisibleCheck", {
        Text = "Visible Check",
        Default = cheat_client.config.visible_check
    })

    -- Listeners
    Toggles.NoStun:OnChanged(function()
        cheat_client.config.no_stun = Toggles.NoStun.Value
    end)

    Toggles.AntiHystericus:OnChanged(function()
        cheat_client.config.anti_confusion = Toggles.AntiHystericus.Value
    end)

    Toggles.PerfloraTeleport:OnChanged(function()
        local value = Toggles.PerfloraTeleport.Value
        cheat_client.config.perflora_teleport = value
        if value then
            if cheat_client.start_perflora_teleport then cheat_client.start_perflora_teleport() end
        else
            if cheat_client.stop_perflora_teleport then cheat_client.stop_perflora_teleport() end
        end
    end)

    Toggles.AutoMisogi:OnChanged(function()
        cheat_client.config.auto_misogi = Toggles.AutoMisogi.Value
    end)

    Toggles.AntiBackfireViribus:OnChanged(function()
        cheat_client.config.anti_backfire_viribus = Toggles.AntiBackfireViribus.Value
    end)

    Toggles.HoldBlock:OnChanged(function()
        local value = Toggles.HoldBlock.Value
        cheat_client.config.hold_block = value
        if value then
            if cheat_client.start_hold_block then cheat_client.start_hold_block() end
        else
            if cheat_client.stop_hold_block then cheat_client.stop_hold_block() end
        end
    end)

    Toggles.AutoPerfectBlock:OnChanged(function()
        cheat_client.config.auto_perfect_block = Toggles.AutoPerfectBlock.Value
    end)

    Toggles.ParryPingAdjust:OnChanged(function()
        cheat_client.config.parry_ping_adjust = Toggles.ParryPingAdjust.Value
    end)

    Toggles.ParryCustomDelay:OnChanged(function()
        cheat_client.config.parry_custom_delay = Toggles.ParryCustomDelay.Value
    end)

    Options.ParryCustomDelayMs:OnChanged(function()
        cheat_client.config.custom_delay = Options.ParryCustomDelayMs.Value
    end)

    Options.ParryFovAngle:OnChanged(function()
        cheat_client.config.parry_fov_angle = Options.ParryFovAngle.Value
    end)

    Toggles.ParryDisableWhenUnfocused:OnChanged(function()
        cheat_client.config.parry_disable_when_unfocused = Toggles.ParryDisableWhenUnfocused.Value
    end)

    Toggles.ParryIgnoreVisibility:OnChanged(function()
        cheat_client.config.parry_ignore_visibility = Toggles.ParryIgnoreVisibility.Value
    end)

    Toggles.ParrySemiBlatantBlock:OnChanged(function()
        cheat_client.config.parry_semi_blatant_block = Toggles.ParrySemiBlatantBlock.Value
    end)

    Toggles.SilentAim:OnChanged(function()
        local value = Toggles.SilentAim.Value
        cheat_client.config.silent_aim = value
        if value then
            if cheat_client.start_silent_aim_rendering then cheat_client.start_silent_aim_rendering() end
        else
            if cheat_client.stop_silent_aim_rendering then cheat_client.stop_silent_aim_rendering() end
        end
    end)

    Options.SilentAimFov:OnChanged(function()
        cheat_client.config.fov = Options.SilentAimFov.Value
    end)

    Toggles.IgnoreBlocking:OnChanged(function()
        cheat_client.config.ignore_blocking = Toggles.IgnoreBlocking.Value
    end)

    Toggles.HideFovCircle:OnChanged(function()
        cheat_client.config.hide_fov_circle = Toggles.HideFovCircle.Value
    end)

    Toggles.SilentAimVisibleCheck:OnChanged(function()
        cheat_client.config.visible_check = Toggles.SilentAimVisibleCheck.Value
    end)
end
