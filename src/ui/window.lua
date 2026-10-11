-- language: Lua, file: src/ui/window.lua, target: Roblox Executor
-- Linoria UI Library initialization, main window setup, and tab registration

return function(ctx)
    local shared = ctx.shared
    local utility = ctx.utility
    local repo = ctx.repo_url or "https://raw.githubusercontent.com/rabbihubmaintainer/w/main/"

    local library = nil
    local success, library_func = pcall(function()
        if isfile and isfile("Library.lua") then
            return loadstring(readfile("Library.lua"))()
        end
        return loadstring(game:HttpGet(repo .. "Library.lua", true))()
    end)

    if success then
        if type(library_func) == "function" then
            library = library_func(shared, utility)
        else
            library = library_func
        end
        shared.library = library
        ctx.library = library

        getgenv().Toggles = library.Toggles or {}
        getgenv().Options = library.Options or {}
        getgenv().Labels = library.Labels or {}

        local SaveManager = nil
        local ThemeManager = nil

        pcall(function()
            if isfile and isfile("SaveManager.lua") then
                SaveManager = loadstring(readfile("SaveManager.lua"))()
            else
                SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()
            end
            if isfile and isfile("ThemeManager.lua") then
                ThemeManager = loadstring(readfile("ThemeManager.lua"))()
            else
                ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
            end

            SaveManager:SetLibrary(library)
            ThemeManager:SetLibrary(library)
            SaveManager:IgnoreThemeSettings()

            shared.SaveManager = SaveManager
            shared.ThemeManager = ThemeManager
            ctx.SaveManager = SaveManager
            ctx.ThemeManager = ThemeManager
        end)
    else
        warn("[rabbihub] FAILED to load Library.lua! Error: " .. tostring(library_func))
        error("[rabbihub] Library load failed — check HttpGet access and repo URL. Error: " .. tostring(library_func), 2)
    end

    -- Create Main Window
    local window = library:CreateWindow({
        Title = "rabbihub.cc",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    ctx.window = window

    local Tabs = {
        Combat = window:AddTab("Combat", "sword"),
        Visuals = window:AddTab("Visuals", "eye"),
        World = window:AddTab("World", "globe"),
        Exploits = window:AddTab("Exploits", "zap"),
        Movement = window:AddTab("Movement", "wind"),
        Automation = window:AddTab("Automation", "cog"),
        Misc = window:AddTab("Misc", "settings"),
        Botting = window:AddTab("Botting", "bot"),
        Macros = window:AddTab("Macros", "play"),
        Interface = window:AddTab("Interface", "monitor"),
        Config = window:AddTab("Config", "save"),
        Servers23 = window:AddTab("23s", "server")
    }

    ctx.Tabs = Tabs
    return Tabs
end
