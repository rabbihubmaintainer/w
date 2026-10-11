-- language: Lua, file: src/ui/tabs/botting.lua, target: Roblox Executor
-- Botting tab UI controls: Trinket Bot, Pathing, and Looping Configuration

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local library = ctx.library
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local group_trinket_bot = Tabs.Botting:AddLeftGroupbox("Trinket Bot")
    local group_trinket_config = Tabs.Botting:AddRightGroupbox("Trinket Bot Config")

    group_trinket_bot:AddToggle("start_path", {
        Text = "Start Trinket Bot",
        Default = false,
        Callback = function(state)
            if state then
                if cheat_client.start_trinket_bot then cheat_client.start_trinket_bot() end
            else
                if cheat_client.stop_trinket_bot then cheat_client.stop_trinket_bot() end
            end
        end
    })

    group_trinket_config:AddToggle("serverhop_on_full", {
        Text = "Serverhop on Full Bag",
        Default = true,
        Callback = function(val) cheat_client.config.serverhop_on_full = val end
    })

    group_trinket_config:AddSlider("min_player_count", {
        Text = "Min Players on Hop",
        Default = 5,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Callback = function(val) cheat_client.config.min_player_count = val end
    })
end
