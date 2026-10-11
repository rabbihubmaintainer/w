-- language: Lua, file: src/ui/tabs/macros.lua, target: Roblox Executor
-- Macros tab UI controls: Macro Builder and Playback Configuration

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local library = ctx.library
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles

    local group_builder = Tabs.Macros:AddLeftGroupbox("Macro Builder")
    local group_config = Tabs.Macros:AddRightGroupbox("Macro Config")

    group_builder:AddToggle("macro_recording", {
        Text = "Record Macro",
        Default = false,
        Callback = function(val)
            if val then
                if cheat_client.start_macro_recording then cheat_client.start_macro_recording() end
            else
                if cheat_client.stop_macro_recording then cheat_client.stop_macro_recording() end
            end
        end
    })

    group_builder:AddToggle("macro_playing", {
        Text = "Play Macro",
        Default = false,
        Callback = function(val)
            if val then
                if cheat_client.start_macro_playback then cheat_client.start_macro_playback() end
            else
                if cheat_client.stop_macro_playback then cheat_client.stop_macro_playback() end
            end
        end
    })
end
