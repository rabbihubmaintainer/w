local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local httpService = cloneref(game:GetService("HttpService"))
local httprequest = (syn and syn.request) or request or http_request or (http and http.request)
local getassetfunc = getcustomasset or getsynasset
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(copyfunction) == "function" then
    -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

    local isfolder_copy, isfile_copy, listfiles_copy =
        copyfunction(isfolder), copyfunction(isfile), copyfunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {}
do
    ThemeManager.Folder = "HYDROXIDELib"
    -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

    ThemeManager.Library = nil
    ThemeManager.AppliedToTab = false
    ThemeManager.BuiltInThemes = {
        ["Default"] = {
            1,
            httpService:JSONDecode(
                [[{"MainColor":"212121","FontFace":"Code","AccentColor":"00f0ff","OutlineColor":"383838","BackgroundColor":"151515","FontColor":"eeffff"}]]
            ),
        },
        ["BBot"] = {
            2,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}]]
            ),
        },
        ["Fatality"] = {
            3,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}]]
            ),
        },
        ["Noob"] = {
            4,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"191919","AccentColor":"7d55ff","BackgroundColor":"0f0f0f","OutlineColor":"282828"}]]
            ),
        },
        ["Mint"] = {
            5,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}]]
            ),
        },
        ["Tokyo Night"] = {
            6,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}]]
            ),
        },
        ["Ubuntu"] = {
            7,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}]]
            ),
        },
        ["Quartz"] = {
            8,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}]]
            ),
        },
        ["Nord"] = {
            9,
            httpService:JSONDecode(
                [[{"FontColor":"eceff4","MainColor":"3b4252","AccentColor":"88c0d0","BackgroundColor":"2e3440","OutlineColor":"4c566a"}]]
            ),
        },
        ["Dracula"] = {
            10,
            httpService:JSONDecode(
                [[{"FontColor":"f8f8f2","MainColor":"44475a","AccentColor":"ff79c6","BackgroundColor":"282a36","OutlineColor":"6272a4"}]]
            ),
        },
        ["Monokai"] = {
            11,
            httpService:JSONDecode(
                [[{"FontColor":"f8f8f2","MainColor":"272822","AccentColor":"f92672","BackgroundColor":"1e1f1c","OutlineColor":"49483e"}]]
            ),
        },
        ["Gruvbox"] = {
            12,
            httpService:JSONDecode(
                [[{"FontColor":"ebdbb2","MainColor":"3c3836","AccentColor":"fb4934","BackgroundColor":"282828","OutlineColor":"504945"}]]
            ),
        },
        ["Solarized"] = {
            13,
            httpService:JSONDecode(
                [[{"FontColor":"839496","MainColor":"073642","AccentColor":"cb4b16","BackgroundColor":"002b36","OutlineColor":"586e75"}]]
            ),
        },
        ["Catppuccin"] = {
            14,
            httpService:JSONDecode(
                [[{"FontColor":"d9e0ee","MainColor":"302d41","AccentColor":"f5c2e7","BackgroundColor":"1e1e2e","OutlineColor":"575268"}]]
            ),
        },
        ["One Dark"] = {
            15,
            httpService:JSONDecode(
                [[{"FontColor":"abb2bf","MainColor":"282c34","AccentColor":"c678dd","BackgroundColor":"21252b","OutlineColor":"5c6370"}]]
            ),
        },
        ["Cyberpunk"] = {
            16,
            httpService:JSONDecode(
                [[{"FontColor":"f9f9f9","MainColor":"262335","AccentColor":"00ff9f","BackgroundColor":"1a1a2e","OutlineColor":"413c5e"}]]
            ),
        },
        ["Oceanic Next"] = {
            17,
            httpService:JSONDecode(
                [[{"FontColor":"d8dee9","MainColor":"1b2b34","AccentColor":"6699cc","BackgroundColor":"16232a","OutlineColor":"343d46"}]]
            ),
        },
        ["Material"] = {
            18,
            httpService:JSONDecode(
                [[{"FontColor":"eeffff","MainColor":"212121","AccentColor":"82aaff","BackgroundColor":"151515","OutlineColor":"424242"}]]
            ),
        },
    }

    function ThemeManager:SetLibrary(library)
        self.Library = library
        self.DefaultTheme = "Carbon Gray 100"
        if not self.CarbonInstalled then
            for _, theme in pairs(self.BuiltInThemes) do theme[1] += 4 end
            for index, name in ipairs({"Carbon Gray 100", "Carbon Gray 90", "Carbon White", "Carbon Gray 10"}) do
                self.BuiltInThemes[name] = {index, table.clone(library.CarbonThemes[name])}
            end
            self.BuiltInThemes.Default = {5, table.clone(library.CarbonThemes["Carbon Gray 100"])}
            self.CarbonInstalled = true
        end
    end

    --// Folders \\--
    function ThemeManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        paths[#paths + 1] = self.Folder .. "/themes"

        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then
                continue
            end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then
            return
        end
        self:BuildFolderTree()

        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    --// Apply, Update theme \\--
    function ThemeManager:ApplyTheme(theme)
        if type(theme) ~= "string" or theme == "" then return false, "Select a theme first" end
        local custom = self:GetCustomTheme(theme)
        local entry = self.BuiltInThemes[theme]
        local data = custom or (entry and entry[2])
        if type(data) ~= "table" then return false, "Theme is unavailable" end
        local colors = {}
        for _, field in ipairs(self.Library.ColorFields) do
            if data[field] ~= nil then
                local ok, color = pcall(Color3.fromHex, data[field])
                if not ok then return false, "Invalid theme color: " .. field end
                colors[field] = color
            end
        end
        self.ApplyingTheme = true
        self.Library:ApplyThemeColors(colors)
        self.Library:SetFont(data.FontFace or "IBM Plex Sans")
        for _, field in ipairs(self.Library.ColorFields) do
            if self.Library.Options[field] then self.Library.Options[field]:SetValueRGB(self.Library.Scheme[field]) end
        end
        if self.Library.Options.FontFace then self.Library.Options.FontFace:SetValue(data.FontFace or "IBM Plex Sans") end
        self.ApplyingTheme = false
        self.Library:UpdateColorsUsingRegistry()
        return true
    end

    function ThemeManager:ThemeUpdate()
        if self.ApplyingTheme then return end
        local colors = {}
        for _, field in ipairs({"FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "TextSecondary", "FocusColor"}) do
            local option = self.Library.Options[field]
            if option then colors[field] = option.Value end
        end
        self.Library:ApplyThemeColors(colors)
        self.Library:UpdateColorsUsingRegistry()
    end

    --// Get, Load, Save, Delete, Refresh \\--
    function ThemeManager:GetCustomTheme(file)
        if type(file) ~= "string" or file == "" or file:find("[/\\]") or file:find("..", 1, true) then return nil end
        local path = self.Folder .. "/themes/" .. file .. ".json"
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(httpService.JSONDecode, httpService, data)

        if not success or type(decoded) ~= "table" then return nil end
        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme = self.DefaultTheme or "Carbon Gray 100"
        local content = isfile(self.Folder .. "/themes/default.txt") and readfile(self.Folder .. "/themes/default.txt")

        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        if isDefault then
            local picker = self.Library.Options.ThemeManager_ThemeList
            if picker then picker:SetValue(theme) else self:ApplyTheme(theme) end
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:SaveDefault(theme)
        writefile(self.Folder .. "/themes/default.txt", theme)
    end

    function ThemeManager:SetDefaultTheme(theme)
        assert(self.Library, "Must set ThemeManager.Library first!")
        assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")
        if type(theme) == "string" then
            assert(self.BuiltInThemes[theme], "Unknown default theme")
            self.DefaultTheme = theme
        else
            assert(type(theme) == "table", "Expected a theme name or table")
            local data = table.clone(self.BuiltInThemes.Default[2])
            for _, field in ipairs(self.Library.ColorFields) do
                if typeof(theme[field]) == "Color3" then data[field] = theme[field]:ToHex()
                elseif type(theme[field]) == "string" then data[field] = theme[field] end
            end
            local face = theme.FontFace
            data.FontFace = typeof(face) == "EnumItem" and face.Name or type(face) == "string" and face or "IBM Plex Sans"
            self.BuiltInThemes.Default = {5, data}
            self.DefaultTheme = "Default"
        end
        self:ApplyTheme(self.DefaultTheme)
    end

    function ThemeManager:SaveCustomTheme(file)
        if type(file) ~= "string" or file:gsub("%s", "") == "" or file:find("[/\\]") or file:find("..", 1, true) then
            return false, "Enter a valid theme name"
        end
        local theme = {}
        for _, field in ipairs(self.Library.ColorFields) do theme[field] = self.Library.Scheme[field]:ToHex() end
        local picker = self.Library.Options.FontFace
        theme.FontFace = picker and picker.Value or "IBM Plex Sans"
        local ok = pcall(writefile, self.Folder .. "/themes/" .. file .. ".json", httpService:JSONEncode(theme))
        return ok, ok and nil or "Could not save theme"
    end

    function ThemeManager:Delete(name)
        if not name then
            return false, "no config file is selected"
        end

        local file = self.Folder .. "/themes/" .. name .. ".json"
        if not isfile(file) then
            return false, "invalid file"
        end

        local success = pcall(delfile, file)
        if not success then
            return false, "delete file error"
        end

        return true
    end

    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. "/themes")

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                -- i hate this but it has to be done ...

                local pos = file:find(".json", 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= "/" and char ~= "\\" and char ~= "" do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == "/" or char == "\\" then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    --// GUI \\--
    function ThemeManager:CreateThemeManager(groupbox)
        local library = self.Library
        local options = library.Options
        groupbox:AddLabel("Choose a Carbon palette or adjust the colors below.", true)
        local themes = {}
        for name in pairs(self.BuiltInThemes) do themes[#themes + 1] = name end
        table.sort(themes, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)
        groupbox:AddDropdown("ThemeManager_ThemeList", {Text = "Color theme", Values = themes, Default = self.DefaultTheme or "Carbon Gray 100"})
        options.ThemeManager_ThemeList:OnChanged(function() self:ApplyTheme(options.ThemeManager_ThemeList.Value) end)
        groupbox:AddButton({Text = "Use as default", Variant = "Primary", Func = function()
            self:SaveDefault(options.ThemeManager_ThemeList.Value)
            library:Notify("Default appearance updated")
        end})
        groupbox:AddDivider()
        for _, field in ipairs({
            {"BackgroundColor", "Background"}, {"MainColor", "Panels"}, {"AccentColor", "Interactive color"},
            {"OutlineColor", "Subtle borders"}, {"FontColor", "Primary text"},
            {"TextSecondary", "Secondary text"}, {"FocusColor", "Focus outline"},
        }) do
            groupbox:AddLabel(field[2]):AddColorPicker(field[1], {Default = library.Scheme[field[1]]})
        end
        groupbox:AddDropdown("FontFace", {
            Text = "Typeface", Default = "IBM Plex Sans",
            Values = {"IBM Plex Sans", "BuilderSans", "Code", "Gotham", "Roboto", "RobotoMono", "SourceSans"},
        })
        groupbox:AddDivider()
        groupbox:AddInput("ThemeManager_CustomThemeName", {Text = "New theme name", Placeholder = "e.g. My workspace", ClearTextOnFocus = false})
        groupbox:AddButton({Text = "Save new theme", Variant = "Primary", Func = function()
            local ok, err = self:SaveCustomTheme(options.ThemeManager_CustomThemeName.Value)
            if not ok then library:Notify(err); return end
            options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            library:Notify("Theme saved")
        end})
        groupbox:AddDropdown("ThemeManager_CustomThemeList", {Text = "Saved themes", Values = self:ReloadCustomThemes(), AllowNull = true})
        groupbox:AddButton({Text = "Apply theme", Variant = "Primary", Func = function()
            local ok, err = self:ApplyTheme(options.ThemeManager_CustomThemeList.Value)
            if not ok then library:Notify(err) end
        end}):AddButton({Text = "Update theme", Variant = "Secondary", Func = function()
            local ok, err = self:SaveCustomTheme(options.ThemeManager_CustomThemeList.Value)
            library:Notify(ok and "Theme updated" or err)
        end})
        groupbox:AddButton({Text = "Delete theme", Variant = "Danger", DoubleClick = true, Func = function()
            local ok, err = self:Delete(options.ThemeManager_CustomThemeList.Value)
            if not ok then library:Notify(err); return end
            options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            options.ThemeManager_CustomThemeList:SetValue(nil)
            library:Notify("Theme deleted")
        end}):AddButton({Text = "Refresh", Variant = "Ghost", Func = function()
            options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        end})
        groupbox:AddButton({Text = "Make saved theme default", Variant = "Secondary", Func = function()
            local name = options.ThemeManager_CustomThemeList.Value
            if not name then library:Notify("Select a saved theme first"); return end
            self:SaveDefault(name)
            library:Notify("Default appearance updated")
        end})
        groupbox:AddButton({Text = "Reset to Carbon default", Variant = "Ghost", Func = function()
            self:SaveDefault("Carbon Gray 100")
            options.ThemeManager_ThemeList:SetValue("Carbon Gray 100")
        end})
        for _, field in ipairs({"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "TextSecondary", "FocusColor"}) do
            options[field]:OnChanged(function() self:ThemeUpdate() end)
        end
        options.FontFace:OnChanged(function(value)
            if not self.ApplyingTheme then library:SetFont(value) end
        end)
        self:LoadDefault()
        self.AppliedToTab = true
    end



    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        return tab:AddLeftGroupbox("Appearance", "paintbrush")
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set ThemeManager.Library first!")
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager