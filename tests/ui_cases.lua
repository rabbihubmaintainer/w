local passed = 0
local function equal(actual, expected)
    assert(actual == expected, 'Expected ' .. tostring(expected) .. ', received ' .. tostring(actual))
end
local function test(name, callback)
    local ok, err = pcall(callback)
    assert(ok, name .. ': ' .. tostring(err))
    passed += 1
    print('PASS ' .. name)
end
local function color(value)
    return value:ToHex()
end
local function find(node, name)
    for _, item in ipairs(node:GetDescendants()) do if item.Name == name then return item end end
end

test('Catppuccin Mocha is the initial palette and square corners remain the default', function()
    equal(library.DefaultThemeName, 'Catppuccin')
    equal(color(library.Scheme.BackgroundColor), '1e1e2e')
    equal(color(library.Scheme.AccentColor), 'cba6f7')
    equal(color(library.Scheme.FieldColor), '45475a')
    equal(library.CornerRadius, 0)
end)
themeManager:SetLibrary(library)
saveManager:SetLibrary(library)
saveManager:IgnoreThemeSettings()
test('theme manager and reset alias default to Catppuccin', function()
    equal(themeManager.DefaultTheme, 'Catppuccin')
    equal(themeManager.BuiltInThemes.Catppuccin[1], 1)
    equal(themeManager.BuiltInThemes.Default[2].BackgroundColor, '1e1e2e')
end)
test('named Carbon defaults work before building theme controls', function()
    themeManager:SetDefaultTheme('Carbon White')
    equal(color(library.Scheme.BackgroundColor), 'ffffff')
    assert(library.IsLightTheme)
    themeManager:SetDefaultTheme('Carbon Gray 100')
end)
test('custom font capability failure uses a valid built-in font', function()
    equal(typeof(library:ResolveFont('IBM Plex Sans')), 'Font')
    equal(library:ResolveFont('IBM Plex Sans').Family, 'Roboto')
    equal(library:ResolveFont('Code').Family, 'Code')
end)

test('bundled font loader builds regular and semibold family faces', function()
    local original = game.HttpGet
    game.HttpGet = function() return '\0\1\0\0' .. string.rep('x', 1200) end
    getcustomasset = function(path) return 'asset://' .. path end
    library.PlexFont = nil
    local face = library:ResolveFont('IBM Plex Sans')
    equal(face.Family, 'asset://rabbihub/assets/carbon/IBMPlexSans.json')
    local family = HttpService:JSONDecode(files['rabbihub/assets/carbon/IBMPlexSans.json'])
    equal(family.faces[1].weight, 400)
    equal(family.faces[2].weight, 600)
    game.HttpGet = original
end)

test('Catppuccin and Carbon presets keep text and primary actions above WCAG AA contrast', function()
    local function luminance(color)
        local function linear(value) return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4 end
        return linear(color.R) * 0.2126 + linear(color.G) * 0.7152 + linear(color.B) * 0.0722
    end
    local function contrast(a, b)
        local x, y = luminance(a), luminance(b)
        return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
    end
    local names = {'Catppuccin'}
    for name in pairs(library.CarbonThemes) do names[#names + 1] = name end
    for _, name in ipairs(names) do
        themeManager:ApplyTheme(name)
        local colors = library.Scheme
        assert(contrast(colors.FontColor, colors.MainColor) >= 4.5, name)
        assert(contrast(colors.TextSecondary, colors.MainColor) >= 4.5, name)
        assert(contrast(colors.TextOnAccent, colors.AccentColor) >= 4.5, name)
        assert(contrast(colors.TextPlaceholder, colors.FieldColor) >= 4.5, name)
    end
    themeManager:ApplyTheme('Carbon Gray 100')
end)

local window = library:CreateWindow({Title = 'rabbihub', Footer = 'Settings workspace', AutoShow = false, Font = 'IBM Plex Sans'})
local combat = window:AddTab('Combat', 'sword', 'Configure your workspace')
local settings = window:AddTab('Appearance', 'settings')
local left = combat:AddLeftGroupbox('Combat utilities')
local right = combat:AddRightGroupbox('Target settings')
local toggleCalls = 0
local toggle = left:AddToggle('test_toggle', {Text = 'Auto parry', Default = true, Callback = function() toggleCalls += 1 end})
left:AddCheckbox('test_checkbox', {Text = 'Visible targets only', Default = true})
local input = left:AddInput('test_input', {Text = 'Profile name', Default = 'Everyday', Placeholder = 'Name', ClearTextOnFocus = false})
local slider = right:AddSlider('test_slider', {Text = 'Detection range', Min = 0, Max = 100, Default = 60, Rounding = 0, Suffix = ' m'})
local dropdown = right:AddDropdown('test_dropdown', {Text = 'Target priority', Values = {'Nearest', 'Lowest health', 'Cursor'}, Default = 'Nearest', Searchable = true})
local primary = left:AddButton({Text = 'Apply settings', Variant = 'Primary', Func = function() end})
local secondary = right:AddButton({Text = 'Reset settings', Variant = 'Secondary', Func = function() end})
local hidden = right:AddButton({Text = 'Hidden action', Visible = false, Func = function() end})
themeManager:ApplyToTab(settings)
saveManager:BuildConfigSection(settings)
combat:Show()
flush()

test('all navigation and control icons have bundled native shapes', function()
    local original = game.HttpGet
    game.HttpGet = function() error('Network unavailable') end
    for _, name in ipairs({'sword', 'eye', 'globe', 'zap', 'wind', 'cog', 'settings', 'bot', 'play', 'monitor', 'save', 'server', 'check', 'chevron-up', 'move-diagonal-2', 'key', 'search', 'move', 'paintbrush', 'folder-cog'}) do
        local icon = library:GetIcon(name)
        assert(icon.Builtin and icon.Name == name, name)
    end
    local count = 0
    for _, node in ipairs(library.ScreenGui:GetDescendants()) do
        if node.Name == 'BuiltinIcon' then assert(#node:GetChildren() > 1); count += 1 end
    end
    assert(count >= 10)
    game.HttpGet = original
end)
test('reset applies and saves Catppuccin as the default', function()
    local found = false
    for _, button in pairs(library.Buttons) do
        if button.Text == 'Reset to Catppuccin default' then button.Func(); found = true end
    end
    assert(found)
    equal(files[themeManager.Folder .. '/themes/default.txt'], 'Catppuccin')
    equal(library.Options.ThemeManager_ThemeList.Value, 'Catppuccin')
    equal(color(library.Scheme.BackgroundColor), '1e1e2e')
    themeManager:ApplyTheme('Carbon Gray 100')
end)
test('unknown icons have a visible fallback and native assets remain supported', function()
    equal(library:GetIcon('unknown-icon').Name, 'grid')
    equal(library:GetIcon(nil), nil)
    local custom = library:GetCustomIcon('rbxassetid://12345')
    assert(custom.Custom)
    equal(custom.Url, 'rbxassetid://12345')
end)
test('bundled icons follow tint and transparency and can be replaced safely', function()
    local image = Instance.new('ImageLabel')
    image.Size = UDim2.fromOffset(24, 24)
    image.Parent = library.ScreenGui
    library:SetIcon(image, library:GetIcon('search'))
    image.ImageColor3 = Color3.fromHex('cba6f7')
    image.ImageTransparency = 0.4
    local line = find(image, 'IconLine')
    assert(line)
    equal(color(line.BackgroundColor3), 'cba6f7')
    equal(line.BackgroundTransparency, 0.4)
    library:SetIcon(image, library:GetIcon('play'))
    equal(#image:GetChildren(), 1)
    library:SetIcon(image, library:GetCustomIcon('rbxassetid://12345'))
    equal(image.Image, 'rbxassetid://12345')
    equal(image:FindFirstChild('BuiltinIcon'), nil)
    image:Destroy()
end)

test('window and controls are constructed through the real library', function()
    equal(primary.Holder.Size.Y.Offset, 40)
    equal(input.Holder.Size.Y.Offset, 64)
    equal(dropdown.Holder.Size.Y.Offset, 64)
    equal(hidden.Holder.Visible, false)
    equal(toggle.Holder.Size.Y.Offset, 32)
end)
test('toggle callbacks and dependency updates still run', function()
    toggle:SetValue(false)
    equal(toggle.Value, false)
    equal(toggleCalls, 1)
    toggle:SetValue(true)
end)
test('text input and slider retain their public value APIs', function()
    input:SetValue('Travel')
    equal(input.Value, 'Travel')
    slider:SetValue(75)
    equal(slider.Value, 75)
    slider:SetValue(600)
    equal(slider.Value, 100)
    slider:SetValue(60)
end)
test('input focus rings respond to focus and blur', function()
    local box = input.Holder:FindFirstChildOfClass('TextBox')
    local ring = box:FindFirstChild('CarbonFocus')
    equal(ring.Transparency, 1)
    box.Focused:Fire()
    equal(ring.Transparency, 0)
    box.FocusLost:Fire(false)
    equal(ring.Transparency, 1)
end)
test('gamepad selection shows button focus without permanently changing it', function()
    local ring = primary.Base:FindFirstChild('CarbonFocus')
    primary.Base.SelectionGained:Fire()
    equal(ring.Transparency, 0)
    primary.Base.SelectionLost:Fire()
    equal(ring.Transparency, 1)
end)
test('dropdown list sizing matches its new forty pixel rows', function()
    dropdown:RecalculateListSize(3)
    equal(dropdown.Menu.Menu.Size.Y.Offset, 120)
    dropdown:SetValue('Cursor')
    equal(dropdown.Value, 'Cursor')
end)
test('light and dark themes update controls already in the registry', function()
    assert(themeManager:ApplyTheme('Carbon White'))
    equal(color(primary.Base.BackgroundColor3), '0f62fe')
    equal(color(primary.Base.TextColor3), 'ffffff')
    equal(color(secondary.Base.TextColor3), '161616')
    equal(color(library.Scheme.FocusColor), '0f62fe')
    assert(themeManager:ApplyTheme('Carbon Gray 100'))
    equal(color(secondary.Base.TextColor3), 'f4f4f4')
    equal(color(library.Scheme.FocusColor), 'ffffff')
end)
test('legacy theme names and font choices remain supported', function()
    assert(themeManager:ApplyTheme('Tokyo Night'))
    equal(color(library.Scheme.BackgroundColor), '16161f')
    assert(themeManager:ApplyTheme('Carbon Gray 100'))
end)
test('all Carbon color roles and the selected font survive theme save/load', function()
    local ok = themeManager:SaveCustomTheme('My workspace')
    assert(ok)
    local stored = HttpService:JSONDecode(files[themeManager.Folder .. '/themes/My workspace.json'])
    equal(stored.FocusColor, 'ffffff')
    equal(stored.FieldColor, '393939')
    equal(stored.FontFace, 'IBM Plex Sans')
    themeManager:ApplyTheme('Carbon White')
    assert(themeManager:ApplyTheme('My workspace'))
    equal(color(library.Scheme.FieldColor), '393939')
end)
test('theme actions validate missing selections and invalid color data', function()
    equal(themeManager:ApplyTheme(nil), false)
    equal(themeManager:SaveCustomTheme(nil), false)
    equal(themeManager:SaveCustomTheme('../outside'), false)
    themeManager.BuiltInThemes.Invalid = {99, {BackgroundColor = 'bad color'}}
    equal(themeManager:ApplyTheme('Invalid'), false)
    equal(themeManager.ApplyingTheme, false)
end)
test('configuration save/load preserves controls without overriding appearance', function()
    saveManager:SetFolder('test-configs')
    assert(saveManager:Save('Everyday'))
    toggle:SetValue(false); slider:SetValue(20); input:SetValue('Other')
    themeManager:ApplyTheme('Carbon White')
    assert(saveManager:Load('Everyday'))
    equal(toggle.Value, true)
    equal(slider.Value, 60)
    equal(input.Value, 'Travel')
    equal(color(library.Scheme.BackgroundColor), 'ffffff')
    themeManager:ApplyTheme('Carbon Gray 100')
end)
test('narrow windows stack right panels and can return to two columns', function()
    local main = library.ScreenGui:FindFirstChild('Main')
    main.Size = UDim2.fromOffset(680, 720)
    combat:Resize()
    equal(left.BoxHolder.Parent, right.BoxHolder.Parent)
    equal(combat.Sides[2].Visible, false)
    main.Size = UDim2.fromOffset(1040, 720)
    combat:Resize()
    assert(left.BoxHolder.Parent ~= right.BoxHolder.Parent)
    equal(combat.Sides[2].Visible, true)
end)
test('destructive configuration actions use a danger button and confirmation', function()
    local found = false
    for _, button in pairs(library.Buttons) do
        if button.Text == 'Delete config' then equal(button.Variant, 'Danger'); equal(button.DoubleClick, true); found = true end
    end
    assert(found)
end)

local main = library.ScreenGui:FindFirstChild('Main')
main.Visible = true
combat:Show()
flush()
local function snapshot(node, parentVisible)
    local visible = parentVisible and node.Visible ~= false
    local children = {}
    for _, child in ipairs(node:GetChildren()) do children[#children + 1] = snapshot(child, visible) end
    local size, pos = node.AbsoluteSize, node.AbsolutePosition
    local corner = node:FindFirstChildOfClass('UICorner')
    return {
        class = node.ClassName, name = node.Name, visible = visible, x = pos.X, y = pos.Y,
        width = size.X, height = size.Y, text = node.Text, textSize = node.TextSize,
        textColor = color(node.TextColor3), color = color(node.BackgroundColor3),
        opacity = 1 - node.BackgroundTransparency, textOpacity = 1 - node.TextTransparency,
        radius = corner and (corner.CornerRadius.Scale > 0 and 100 or corner.CornerRadius.Offset) or 0,
        align = node.TextXAlignment == Enum.TextXAlignment.Left and 'left' or 'center',
        z = node.ZIndex, children = children,
    }
end
print('UI_SNAPSHOT ' .. json(snapshot(main, true)))
test('library unload disconnects registered focus signals', function()
    library:Unload()
    assert(library.Unloaded)
    for _, connection in ipairs(library.Signals) do equal(connection.Connected, false) end
end)
print(tostring(passed) .. ' UI and manager checks passed')
