-- language: Lua, file: src/ui/tabs/config.lua, target: Roblox Executor
-- Config tab UI controls: SaveManager, ThemeManager, and Script Unloader

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local library = ctx.library
    local Options = getgenv().Options

    if shared.SaveManager and shared.ThemeManager then
        local config_folder = game.PlaceId == 14341521240 and "rabbihub/rlp_configs" or "rabbihub/configs"
        shared.SaveManager:SetFolder(config_folder)
        shared.ThemeManager:SetFolder("rabbihub")
        shared.SaveManager:SetIgnoreIndexes({ "SavedPaths" })

        shared.SaveManager:BuildConfigSection(Tabs.Config)
        shared.ThemeManager:SetDefaultTheme("Tokyo Night")
        shared.ThemeManager:ApplyToTab(Tabs.Config)

        local UtilityGroup = Tabs.Config:AddRightGroupbox("Utility")

        UtilityGroup:AddButton({
            Text = "Unload Script",
            Func = function()
                if shared and shared.is_unloading then return end
                if ctx.unload then ctx.unload() end
            end
        })

        UtilityGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
            Default = cheat_client.config.menu_keybind or "RightShift",
            NoUI = true,
            Text = "Menu keybind"
        })

        UtilityGroup:AddLabel("Unload bind"):AddKeyPicker("UnloadKeybind", {
            Default = cheat_client.config.unload_keybind or "End",
            Text = "Unload Script",
            Mode = "Toggle",
            Callback = function(Value)
                if shared and shared.is_unloading then return end
                if ctx.unload then ctx.unload() end
            end
        })

        library.ToggleKeybind = Options.MenuKeybind
        Options.MenuKeybind:OnChanged(function()
            cheat_client.config.menu_keybind = Options.MenuKeybind.Value
        end)

        Options.UnloadKeybind:OnChanged(function()
            cheat_client.config.unload_keybind = Options.UnloadKeybind.Value
        end)

        pcall(function()
            shared.SaveManager:LoadAutoloadConfig()
        end)
    end
end
