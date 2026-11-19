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

test('Catppuccin Mocha uses softer surfaces and rounded panels by default', function()
    equal(library.DefaultThemeName, 'Catppuccin')
    equal(color(library.Scheme.BackgroundColor), '1e1e2e')
    equal(color(library.Scheme.AccentColor), 'cba6f7')
    equal(color(library.Scheme.FieldColor), '303247')
    equal(library.CornerRadius, 10)
    equal(library.DefaultFontName, 'BuilderSans')
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

local window = library:CreateWindow({Title = 'rabbihub', Footer = '', AutoShow = false, Font = 'BuilderSans'})
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
local proximityPanel = combat:AddRightGroupbox('Server safety')
local compactProximity = proximityPanel:AddSlider('test_proximity', {Text = 'Proximity Check (studs)', Min = 0, Max = 1000, Default = 352, Rounding = 0, Compact = true})
local compactCritical = proximityPanel:AddSlider('test_critical', {Text = 'Critical Distance (studs)', Min = 0, Max = 1000, Default = 165, Rounding = 0, Compact = true})
local compactPlayers = proximityPanel:AddSlider('test_players', {Text = 'Min Player Count', Min = 0, Max = 23, Default = 2, Rounding = 0, Compact = true})
local longToggle = proximityPanel:AddToggle('test_long_toggle', {Text = 'Automatically disable when the window is unfocused', Default = false})
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
    assert(input.Holder.Size.Y.Offset >= 64)
    assert(dropdown.Holder.Size.Y.Offset >= 64)
    equal(hidden.Holder.Visible, false)
    equal(toggle.Holder.Size.Y.Offset, 36)
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
test('compact sliders keep full setting names out of the numeric value badge', function()
    for _, item in ipairs({{compactProximity, 'Proximity Check (studs)', '352'}, {compactCritical, 'Critical Distance (studs)', '165'}, {compactPlayers, 'Min Player Count', '2'}}) do
        equal(item[1].Label.Text, item[2])
        equal(item[1].ValueLabel.Text, item[3])
        assert(item[1].Track.Size.X.Scale == 1 and item[1].Track.Size.X.Offset == 0)
    end
end)
test('long slider names wrap without overlapping the value or track', function()
    local old = proximityPanel.BoxHolder.Size
    proximityPanel.BoxHolder.Size = UDim2.fromOffset(230, old.Y.Offset)
    for _, item in ipairs({compactProximity, compactCritical, compactPlayers}) do
        item:Reflow()
        local label, value, track = item.Label, item.ValueLabel, item.Track
        assert(label.AbsolutePosition.X + label.AbsoluteSize.X <= value.AbsolutePosition.X - 8)
        assert(track.AbsolutePosition.Y >= label.AbsolutePosition.Y + label.AbsoluteSize.Y)
        assert(item.Holder.AbsoluteSize.Y >= track.Position.Y.Offset + track.AbsoluteSize.Y)
    end
    assert(compactProximity.Label.AbsoluteSize.Y > 26)
    proximityPanel.BoxHolder.Size = old
    compactProximity:Reflow(); compactCritical:Reflow(); compactPlayers:Reflow()
end)
test('panel content is below its header and its slot encloses all rows', function()
    for _, panel in ipairs({left, right, proximityPanel}) do
        panel:Resize()
        assert(panel.Container.AbsolutePosition.Y >= panel.Header.AbsolutePosition.Y + panel.Header.AbsoluteSize.Y)
        assert(panel.Container.AbsolutePosition.Y + panel.Container.AbsoluteSize.Y <= panel.BoxHolder.AbsolutePosition.Y + panel.BoxHolder.AbsoluteSize.Y + 1)
    end
    for _, side in ipairs(combat.Sides) do
        for _, child in ipairs(side:GetChildren()) do
            if child:IsA('Frame') then equal(child.Name, 'PanelSlot') end
        end
    end
end)
test('long toggle labels grow their rows instead of clipping text', function()
    local old = proximityPanel.BoxHolder.Size
    proximityPanel.BoxHolder.Size = UDim2.fromOffset(230, old.Y.Offset)
    longToggle:Reflow()
    assert(longToggle.Holder.Size.Y.Offset > 36)
    assert(longToggle.TextLabel.TextWrapped)
    proximityPanel.BoxHolder.Size = old
    longToggle:Reflow()
end)
test('viewport resizing fits the window and preserves readable text across resolutions', function()
    for _, resolution in ipairs({{3840, 2160}, {1920, 1080}, {1440, 900}, {1280, 720}, {960, 540}, {640, 480}, {360, 640}}) do
        workspace.CurrentCamera.ViewportSize = Vector2.new(resolution[1], resolution[2])
        window:Reflow()
        local frame = window.Frame
        assert(frame.Position.X.Offset >= 0 and frame.Position.Y.Offset >= 0)
        assert(frame.Position.X.Offset + frame.Size.X.Offset <= resolution[1] + 1)
        assert(frame.Position.Y.Offset + frame.Size.Y.Offset <= resolution[2] + 1)
        assert(compactProximity.Label.TextSize >= 15)
        assert(compactProximity.Label.AbsolutePosition.X + compactProximity.Label.AbsoluteSize.X <= compactProximity.ValueLabel.AbsolutePosition.X)
        local context, search = find(frame, 'PageContext'), find(frame, 'SettingsSearch')
        if search.Visible then assert(context.AbsolutePosition.X + context.AbsoluteSize.X <= search.AbsolutePosition.X) end
    end
    workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
end)
test('DPI changes do not accumulate and slider labels return to their original size', function()
    for _ = 1, 3 do
        workspace.CurrentCamera.ViewportSize = Vector2.new(1920, 1080)
        workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
    end
    equal(library.DPIScale, 1)
    equal(compactProximity.Label.TextSize, 15)
    equal(compactProximity.ValueLabel.Text, '352')
end)
test('replacing the camera rebinds viewport sizing and disconnects the old listener', function()
    local previous = workspace.CurrentCamera
    local camera = Instance.new('Camera')
    camera.ViewportSize = Vector2.new(800, 600)
    workspace.CurrentCamera = camera
    workspace:GetPropertyChangedSignal('CurrentCamera'):Fire()
    assert(window.Frame.Size.X.Offset <= 768)
    for _, connection in ipairs(previous:GetPropertyChangedSignal('ViewportSize').connections) do equal(connection.Connected, false) end
    camera.ViewportSize = Vector2.new(1440, 1000)
end)
test('destructive configuration actions use a danger button and confirmation', function()
    local found = false
    for _, button in pairs(library.Buttons) do
        if button.Text == 'Delete config' then equal(button.Variant, 'Danger'); equal(button.DoubleClick, true); found = true end
    end
    assert(found)
end)
test('world overlay labels hide while the menu is open and resume when it closes', function()
    for _, kind in ipairs({'player', 'trinket', 'fallion', 'npc', 'ingredient', 'ore'}) do
        local tick = overlayHarness(kind)
        library.Toggled = false; equal(tick(), true)
        library.Toggled = true; equal(tick(), false)
        library.Toggled = false; equal(tick(), true)
    end
end)

test('default window is compact at desktop and laptop resolutions', function()
    workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
    equal(window.Frame.Size.X.Offset, 900)
    equal(window.Frame.Size.Y.Offset, 600)
    workspace.CurrentCamera.ViewportSize = Vector2.new(1920, 1080)
    assert(window.Frame.Size.X.Offset <= 1035 and window.Frame.Size.Y.Offset <= 690)
    workspace.CurrentCamera.ViewportSize = Vector2.new(1280, 720)
    assert(window.Frame.Size.X.Offset <= 900 and window.Frame.Size.Y.Offset <= 600)
    equal(compactProximity.Label.TextSize, 15)
    workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
end)
local function removeNotification(notification)
    notification:Destroy()
    notification.Frame:Destroy()
end
local function inside(node, container)
    local a, b = node.AbsolutePosition, container.AbsolutePosition
    local size, bounds = node.AbsoluteSize, container.AbsoluteSize
    assert(a.X >= b.X and a.Y >= b.Y, node.Name .. ' starts outside ' .. container.Name)
    assert(a.X + size.X <= b.X + bounds.X + 1, node.Name .. ' extends beyond right edge')
    assert(a.Y + size.Y <= b.Y + bounds.Y + 1, node.Name .. ' extends beyond bottom edge')
end
test('notification side survives repeated DPI changes without moving cards off-screen', function()
    for _, side in ipairs({'Left', 'Right'}) do
        library:SetNotifySide(side)
        local notification = library:Notify({Title = 'Settings saved', Description = 'Your changes have been saved.'})
        for _, dpi in ipairs({115, 100, 150, 75, 100}) do
            library:SetDPIScale(dpi)
            local area = notification.Frame.Parent
            equal(area.AnchorPoint.X, side == 'Left' and 0 or 1)
            equal(area.Position.X.Scale, side == 'Left' and 0 or 1)
            inside(notification.Card, library.ScreenGui)
            inside(notification.TitleLabel, notification.Card)
            inside(notification.DescriptionLabel, notification.Card)
            equal(notification.Card.GroupTransparency, 0)
        end
        removeNotification(notification)
    end
    window:FitToViewport()
end)
test('notifications wrap and remain readable on narrow screens and camera resizes', function()
    local notification = library:Notify({Title = 'Notification', Description = string.rep('Long notification text ', 12)})
    for _, side in ipairs({'Right', 'Left'}) do
        library:SetNotifySide(side)
        for _, resolution in ipairs({{3840, 2160}, {1280, 720}, {360, 640}, {280, 640}}) do
            workspace.CurrentCamera.ViewportSize = Vector2.new(resolution[1], resolution[2])
            inside(notification.Card, library.ScreenGui)
            inside(notification.DescriptionLabel, notification.Card)
            assert(notification.DescriptionLabel.AbsoluteSize.Y > notification.DescriptionLabel.TextSize)
        end
    end
    removeNotification(notification)
    workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
end)
test('notification text changes resize cards and stacked cards do not overlap', function()
    local first = library:Notify('First notification')
    local second = library:Notify('Second notification')
    local original = first.Frame.AbsoluteSize.Y
    first:ChangeTitle('Saved settings')
    first:ChangeDescription(string.rep('Additional information ', 6))
    assert(first.Frame.AbsoluteSize.Y > original)
    inside(first.TitleLabel, first.Card)
    inside(first.DescriptionLabel, first.Card)
    assert(second.Frame.AbsolutePosition.Y >= first.Frame.AbsolutePosition.Y + first.Frame.AbsoluteSize.Y + 6)
    assert(first.Frame.Parent.ClipsDescendants)
    removeNotification(first); removeNotification(second)
end)
test('notifications expire after three seconds and dispose after their short fade', function()
    local previous, scheduled = task.delay, {}
    task.delay = function(seconds, callback) scheduled[#scheduled + 1] = {seconds, callback} end
    local notification = library:Notify({Description = 'Saved'})
    equal(notification.Title, nil)
    equal(notification.TitleLabel.Visible, false)
    equal(notification.Time, 3)
    equal(scheduled[1][1], 3)
    scheduled[1][2]()
    assert(notification.Destroyed)
    equal(library.Notifications[notification.Frame], nil)
    equal(notification.Card.GroupTransparency, 1)
    equal(scheduled[2][1], 0.15)
    scheduled[2][2]()
    equal(notification.Frame.Parent, nil)
    notification:Destroy(); notification:ChangeDescription('Already dismissed')
    equal(#scheduled, 2)
    task.delay = previous
end)
test('explicit durations and persistent progress notifications retain their APIs', function()
    local previous, scheduled = task.delay, {}
    task.delay = function(seconds, callback) scheduled[#scheduled + 1] = {seconds, callback} end
    local timed = library:Notify('Custom duration', 1.5)
    equal(scheduled[1][1], 1.5)
    removeNotification(timed)
    local count = #scheduled
    local persistent = library:Notify({Title = 'Progress', Persist = true, Steps = 4})
    equal(#scheduled, count)
    persistent:ChangeStep(2)
    equal(find(persistent.Card, 'NotificationTimer'):GetChildren()[1].Size.X.Scale, 0.5)
    persistent:ChangeStep(9)
    equal(find(persistent.Card, 'NotificationTimer'):GetChildren()[1].Size.X.Scale, 1)
    removeNotification(persistent)
    local invalid = library:Notify({Description = 'Invalid duration', Time = 'invalid', Steps = 0})
    equal(invalid.Time, 3)
    equal(invalid.Steps, nil)
    removeNotification(invalid)
    task.delay = previous
end)
test('instance-bound notifications dismiss on deletion and release their listener', function()
    local owner = Instance.new('Frame')
    local notification = library:Notify({Description = 'Working', Time = owner})
    local connection = owner.Destroying.connections[1]
    assert(connection.Connected)
    owner:Destroy()
    assert(notification.Destroyed)
    equal(connection.Connected, false)
    notification.Frame:Destroy()
end)

local main = library.ScreenGui:FindFirstChild('Main')
themeManager:ApplyTheme('Catppuccin')
window:FitToViewport()
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
    local owner = Instance.new('Frame')
    local notification = library:Notify({Description = 'Working', Time = owner})
    local connection = owner.Destroying.connections[1]
    library:Unload()
    assert(library.Unloaded)
    assert(notification.Destroyed)
    equal(connection.Connected, false)
    equal(next(library.Notifications), nil)
    for _, connection in ipairs(library.Signals) do equal(connection.Connected, false) end
end)
print(tostring(passed) .. ' UI and manager checks passed')
