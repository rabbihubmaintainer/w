-- language: Lua, file: src/ui/tabs/automation.lua, target: Roblox Executor
-- Automation tab UI controls: General, Farming, Auto Potion/Craft, and Auto Pickup (Bag/Trinket/Ingredient/Weapon)

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
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local FindFirstChild = game.FindFirstChild

    local group_general = Tabs.Automation:AddLeftGroupbox("General")
    local group_farm = Tabs.Automation:AddRightGroupbox("Farming")

    group_general:AddToggle("auto_dialogue", {
        Text = "Auto Dialogue",
        Default = cheat_client.config.auto_dialogue,
        Callback = function(value) cheat_client.config.auto_dialogue = value end
    })

    group_general:AddToggle("auto_bard", {
        Text = "Auto Bard",
        Default = cheat_client.config.auto_bard,
        Callback = function(value) cheat_client.config.auto_bard = value end
    })

    group_general:AddToggle("hide_bard", {
        Text = "Hide Bard",
        Default = cheat_client.config.hide_bard,
        Callback = function(value) cheat_client.config.hide_bard = value end
    })

    group_general:AddDivider()

    group_general:AddToggle("anti_afk", {
        Text = "Anti AFK",
        Default = cheat_client.config.anti_afk,
    })

    Toggles.anti_afk:OnChanged(function(state)
        cheat_client.config.anti_afk = state
        for _, connection in next, getconnections(plr.Idled) do
            if state then connection:Disable() else connection:Enable() end
        end
    end)

    -- Farming
    group_farm:AddToggle("AutoCharge", {
        Text = "Auto Mana Charge",
        Default = cheat_client.config.auto_charge,
        Callback = function(value) cheat_client.config.auto_charge = value end
    })

    group_farm:AddSlider("AutoChargeThreshold", {
        Text = "Charge At Percent",
        Default = cheat_client.config.auto_charge_threshold,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(value) cheat_client.config.auto_charge_threshold = value end
    })

    -- Pickups & Bagging
    local group_auto_pickup = Tabs.Automation:AddLeftGroupbox("Auto Pickup")

    group_auto_pickup:AddToggle("auto_trinket", {
        Text = "Auto Trinket",
        Default = cheat_client.config.auto_trinket,
        Callback = function(value)
            cheat_client.config.auto_trinket = value
            if value then
                if cheat_client.start_auto_trinket_rendering then cheat_client.start_auto_trinket_rendering() end
            else
                if cheat_client.stop_auto_trinket_rendering then cheat_client.stop_auto_trinket_rendering() end
            end
        end
    }):AddKeyPicker("AutoTrinketPickupKeybind", {
        Default = cheat_client.config.auto_trinket_keybind,
        Text = "Auto Trinket Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.AutoTrinketPickupKeybind:OnChanged(function()
        cheat_client.config.auto_trinket_keybind = Options.AutoTrinketPickupKeybind.Value
    end)

    group_auto_pickup:AddToggle("auto_ingredient", {
        Text = "Auto Ingredient",
        Default = cheat_client.config.auto_ingredient,
        Callback = function(value)
            cheat_client.config.auto_ingredient = value
            if value then
                if cheat_client.start_auto_ingredient_rendering then cheat_client.start_auto_ingredient_rendering() end
            else
                if cheat_client.stop_auto_ingredient_rendering then cheat_client.stop_auto_ingredient_rendering() end
            end
        end
    }):AddKeyPicker("AutoIngredientPickupKeybind", {
        Default = cheat_client.config.auto_ingredient_keybind,
        Text = "Auto Ingredient Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.AutoIngredientPickupKeybind:OnChanged(function()
        cheat_client.config.auto_ingredient_keybind = Options.AutoIngredientPickupKeybind.Value
    end)

    group_auto_pickup:AddToggle("auto_weapon", {
        Text = "Auto Weapon",
        Default = cheat_client.config.auto_weapon,
        Callback = function(value) cheat_client.config.auto_weapon = value end
    })

    group_auto_pickup:AddToggle("auto_bag", {
        Text = "Auto Bag",
        Default = cheat_client.config.auto_bag,
        Callback = function(value)
            cheat_client.config.auto_bag = value
            if value then
                if cheat_client.start_auto_bag then cheat_client.start_auto_bag() end
            else
                if cheat_client.stop_auto_bag then cheat_client.stop_auto_bag() end
            end
        end
    }):AddKeyPicker("AutoBagKeybind", {
        Default = cheat_client.config.auto_bag_keybind,
        Text = "Auto Bag Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Options.AutoBagKeybind:OnChanged(function()
        cheat_client.config.auto_bag_keybind = Options.AutoBagKeybind.Value
    end)

    group_auto_pickup:AddSlider("bag_range", {
        Text = "Range",
        Default = cheat_client.config.bag_range,
        Min = 1,
        Max = 80,
        Rounding = 1,
        Callback = function(value) cheat_client.config.bag_range = value end
    })
end
