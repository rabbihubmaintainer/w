-- Minimal, offline Roblox API doubles for the real UI library and managers.
-- Layout measurements are approximate; this is not a Roblox renderer.
local function typed(kind, values)
    values.__kind = kind
    return values
end
local function typeof(value) return type(value) == "table" and value.__kind or type(value) end
local vectorMeta = {__mul = function(vector, factor)
    return setmetatable(typed('Vector2', {X = vector.X * factor, Y = vector.Y * factor}), getmetatable(vector))
end}
local Vector2 = {new = function(x, y) return setmetatable(typed("Vector2", {X = x or 0, Y = y or 0}), vectorMeta) end}
Vector2.zero = Vector2.new()
local Vector3 = {new = function(x, y, z) return typed("Vector3", {X = x or 0, Y = y or 0, Z = z or 0}) end}
Vector3.zero = Vector3.new()
local UDim = {new = function(scale, offset) return typed("UDim", {Scale = scale or 0, Offset = offset or 0}) end}
local dimensionMeta = {__eq = function(a, b)
    return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end}
local UDim2 = {new = function(xs, xo, ys, yo) return setmetatable(typed("UDim2", {X = UDim.new(xs, xo), Y = UDim.new(ys, yo)}), dimensionMeta) end}
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
local ColorMethods = {}
local Color3 = {}
function Color3.new(r, g, b) return setmetatable(typed("Color3", {R = r, G = g, B = b}), {__index = ColorMethods}) end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
function Color3.fromHex(hex)
    assert(type(hex) == "string", "Expected hex color")
    hex = hex:gsub("^#", "")
    assert(#hex == 6 and hex:match("^%x+$"), "Invalid hex color")
    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end
function ColorMethods:ToHex() return string.format("%02x%02x%02x", math.round(self.R * 255), math.round(self.G * 255), math.round(self.B * 255)) end
function ColorMethods:Lerp(other, t) return Color3.new(self.R + (other.R - self.R) * t, self.G + (other.G - self.G) * t, self.B + (other.B - self.B) * t) end
function ColorMethods:ToHSV()
    local high, low = math.max(self.R, self.G, self.B), math.min(self.R, self.G, self.B)
    local delta = high - low
    local h = 0
    if delta > 0 then
        if high == self.R then h = ((self.G - self.B) / delta) % 6
        elseif high == self.G then h = (self.B - self.R) / delta + 2
        else h = (self.R - self.G) / delta + 4 end
    end
    return h / 6, high == 0 and 0 or delta / high, high
end
function Color3.fromHSV(h, s, v)
    local function channel(n)
        local k = (n + h * 6) % 6
        return v - v * s * math.max(0, math.min(k, 4 - k, 1))
    end
    return Color3.new(channel(5), channel(3), channel(1))
end
local Enum = setmetatable({}, {__index = function(self, category)
    local group = setmetatable({}, {__index = function(t, name)
        local item = typed("EnumItem", {Name = name, Value = 1})
        function item:GetEnumItems() return {} end
        rawset(t, name, item)
        return item
    end})
    function group:GetEnumItems() return {} end
    rawset(self, category, group)
    return group
end})
local Font = {new = function(family, weight, style) return typed("Font", {Family = family, Weight = weight or Enum.FontWeight.Regular, Style = style or Enum.FontStyle.Normal}) end}
function Font.fromEnum(item) assert(item and item.Name); return Font.new(item.Name) end
local TweenInfo = {new = function(time) return {Time = time or 0} end}
local ColorSequenceKeypoint = {new = function(time, color) return {Time = time, Value = color} end}
local ColorSequence = {new = function(value) return value end}
local NumberSequenceKeypoint = {new = function(time, value) return {Time = time, Value = value} end}
local NumberSequence = {new = function(value) return value end}
local queued = {}
local task = {wait = function() return 0 end, delay = function() end}
function task.defer(callback, ...) queued[#queued + 1] = {callback, table.pack(...)} end
function task.spawn(callback, ...) return callback(...) end
local function flush()
    while #queued > 0 do
        local batch = queued; queued = {}
        for _, entry in ipairs(batch) do entry[1](table.unpack(entry[2], 1, entry[2].n)) end
    end
end
local function signal()
    local event = {connections = {}}
    function event:Connect(callback)
        local connection = typed("RBXScriptConnection", {Connected = true, callback = callback})
        function connection:Disconnect() self.Connected = false end
        self.connections[#self.connections + 1] = connection
        return connection
    end
    function event:Fire(...)
        for _, connection in ipairs(self.connections) do if connection.Connected then connection.callback(...) end end
    end
    function event:Once(callback)
        local connection
        connection = self:Connect(function(...) connection:Disconnect(); callback(...) end)
        return connection
    end
    function event:Wait() return nil end
    return event
end

local Instance, Methods = {}, {}
local all = {}
local events = {InputBegan = true, InputChanged = true, InputEnded = true, MouseEnter = true, MouseLeave = true,
    MouseMoved = true, MouseButton1Click = true, MouseButton1Down = true, MouseButton2Click = true, Focused = true,
    FocusLost = true, SelectionGained = true, SelectionLost = true, DescendantRemoving = true, Destroying = true,
    ChildAdded = true, ChildRemoved = true, PlayerAdded = true, PlayerRemoving = true, Changed = true,
    RenderStepped = true, Heartbeat = true, WindowFocused = true, WindowFocusReleased = true, TouchPinch = true}
local workspace
local gui = {Frame = true, CanvasGroup = true, TextLabel = true, TextButton = true, TextBox = true, ImageLabel = true, ImageButton = true, ScrollingFrame = true, ViewportFrame = true}
local function childOf(parent, kind)
    if not parent then return nil end
    for _, child in ipairs(parent._children) do if child.ClassName == kind then return child end end
end
local function padding(node)
    local p = childOf(node, "UIPadding")
    if not p then return 0, 0, 0, 0 end
    return p.PaddingLeft.Offset, p.PaddingRight.Offset, p.PaddingTop.Offset, p.PaddingBottom.Offset
end
local function content(node)
    local layout = childOf(node, "UIListLayout")
    if not layout then return Vector2.zero end
    local horizontal = layout.FillDirection == Enum.FillDirection.Horizontal
    local along, across, count = 0, 0, 0
    for _, child in ipairs(node._children) do
        if gui[child.ClassName] and child.Visible then
            local size = child.AbsoluteSize
            along += horizontal and size.X or size.Y
            across = math.max(across, horizontal and size.Y or size.X)
            count += 1
        end
    end
    along += math.max(count - 1, 0) * layout.Padding.Offset
    return horizontal and Vector2.new(along, across) or Vector2.new(across, along)
end
local function absoluteSize(node)
    if node.ClassName == "ScreenGui" then return workspace and workspace.CurrentCamera.ViewportSize or Vector2.new(1440, 1000) end
    if not gui[node.ClassName] then return Vector2.zero end
    if rawget(node, '_measuring') then return rawget(node, '_lastSize') or Vector2.zero end
    rawset(node, '_measuring', true)
    local dimension = node.Size
    local parent = node.Parent
    local size = parent and parent.AbsoluteSize or Vector2.zero
    local left, right, top, bottom = padding(parent)
    local width, height = math.max(0, size.X - left - right), math.max(0, size.Y - top - bottom)
    local x, y = dimension.X.Scale * width + dimension.X.Offset, dimension.Y.Scale * height + dimension.Y.Offset
    if parent then
        local layout = childOf(parent, "UIListLayout")
        if layout and layout.FillDirection == Enum.FillDirection.Horizontal and layout.HorizontalFlex == Enum.UIFlexAlignment.Fill then
            local n = 0
            for _, sibling in ipairs(parent._children) do if gui[sibling.ClassName] and sibling.Visible then n += 1 end end
            x = (width - math.max(0, n - 1) * layout.Padding.Offset) / math.max(n, 1)
        end
    end
    if node.SizeConstraint == Enum.SizeConstraint.RelativeYY then x = y * dimension.X.Scale + dimension.X.Offset end
    if node.AutomaticSize == Enum.AutomaticSize.Y or node.AutomaticSize == Enum.AutomaticSize.XY then
        local _, _, ownTop, ownBottom = padding(node)
        y = math.max(y, content(node).Y + ownTop + ownBottom)
        if node.ClassName == 'TextLabel' and #node.Text > 0 then y = math.max(y, node.TextSize) end
    end
    local result = Vector2.new(x, y)
    rawset(node, '_lastSize', result)
    rawset(node, '_measuring', false)
    return result
end
local function absolutePosition(node)
    local parent = node.Parent
    if not parent then return Vector2.zero end
    local base, size, own = parent.AbsolutePosition, parent.AbsoluteSize, node.AbsoluteSize
    local left, right, top, bottom = padding(parent)
    local width, height = size.X - left - right, size.Y - top - bottom
    local x = node.Position.X.Scale * width + node.Position.X.Offset - node.AnchorPoint.X * own.X
    local y = node.Position.Y.Scale * height + node.Position.Y.Offset - node.AnchorPoint.Y * own.Y
    local layout = childOf(parent, "UIListLayout")
    if layout and gui[node.ClassName] then
        local siblings = {}
        for _, child in ipairs(parent._children) do if gui[child.ClassName] and child.Visible then siblings[#siblings + 1] = child end end
        table.sort(siblings, function(a, b) return a.LayoutOrder == b.LayoutOrder and a._id < b._id or a.LayoutOrder < b.LayoutOrder end)
        local horizontal = layout.FillDirection == Enum.FillDirection.Horizontal
        x, y = 0, 0
        for _, child in ipairs(siblings) do
            if child == node then break end
            if horizontal then x += child.AbsoluteSize.X + layout.Padding.Offset else y += child.AbsoluteSize.Y + layout.Padding.Offset end
        end
        local c = content(parent)
        if horizontal then
            if layout.HorizontalAlignment == Enum.HorizontalAlignment.Right then x += width - c.X end
            if layout.VerticalAlignment == Enum.VerticalAlignment.Center then y = (height - own.Y) / 2 end
        elseif layout.HorizontalAlignment == Enum.HorizontalAlignment.Right then x = width - own.X end
    end
    return Vector2.new(base.X + left + x, base.Y + top + y)
end
local instanceMeta = {
    __index = function(node, key)
        if Methods[key] then return Methods[key] end
        if key == "AbsoluteSize" then return absoluteSize(node) end
        if key == "AbsolutePosition" then return node.ClassName == "ScreenGui" and Vector2.zero or absolutePosition(node) end
        if key == "AbsoluteContentSize" then return node.Parent and content(node.Parent) or Vector2.zero end
        if node._properties[key] ~= nil then return node._properties[key] end
        if events[key] then
            node._events[key] = node._events[key] or signal()
            return node._events[key]
        end
        if key == "TextBounds" then return Vector2.new(#tostring(node.Text) * node.TextSize * 0.5, node.TextSize) end
        return nil
    end,
    __newindex = function(node, key, value)
        if key:match('Color3$') then assert(typeof(value) == 'Color3', 'Unresolved color on ' .. node.Name .. ': ' .. key) end
        if key == 'FontFace' then assert(typeof(value) == 'Font', 'Unresolved font on ' .. node.Name) end
        if key == "Parent" then
            local old = node._properties.Parent
            if old then local i = table.find(old._children, node); if i then table.remove(old._children, i) end end
            if value then value._children[#value._children + 1] = node end
        end
        local previous = node._properties[key]
        node._properties[key] = value
        if (key == 'ImageColor3' or key == 'ImageTransparency') and node._events[key] then node._events[key]:Fire() end
        if key == 'ViewportSize' and previous ~= value and node._events[key] then node._events[key]:Fire() end
    end,
}
function Instance.new(class)
    local node = setmetatable({__kind = "Instance", _properties = {}, _children = {}, _events = {}, _id = #all + 1}, instanceMeta)
    node.ClassName = class; node.Name = class
    node.Size = UDim2.fromOffset(0, 0); node.Position = UDim2.fromOffset(0, 0); node.AnchorPoint = Vector2.zero
    if class == 'Frame' then node.Size = UDim2.fromOffset(100, 100) end
    node.Visible = true; node.BackgroundTransparency = 0; node.TextTransparency = 0; node.ImageTransparency = 0
    node.BackgroundColor3 = Color3.new(1, 1, 1); node.TextColor3 = Color3.new(0, 0, 0)
    node.ImageColor3 = Color3.new(1, 1, 1)
    node.Text = ""; node.TextSize = 14; node.LayoutOrder = 0; node.ZIndex = 1
    node.BorderSizePixel = 0; node.BorderColor3 = Color3.new(0, 0, 0)
    node.PaddingLeft = UDim.new(); node.PaddingRight = UDim.new(); node.PaddingTop = UDim.new(); node.PaddingBottom = UDim.new(); node.Padding = UDim.new()
    all[#all + 1] = node
    return node
end
function Methods:IsA(class) return self.ClassName == class or class == "GuiObject" and gui[self.ClassName] or class == "Instance" end
function Methods:GetChildren() return table.clone(self._children) end
function Methods:FindFirstChild(name) for _, child in ipairs(self._children) do if child.Name == name then return child end end end
function Methods:FindFirstChildOfClass(class) return childOf(self, class) end
function Methods:GetDescendants()
    local result = {}
    for _, child in ipairs(self._children) do
        result[#result + 1] = child
        for _, nested in ipairs(child:GetDescendants()) do result[#result + 1] = nested end
    end
    return result
end
function Methods:GetPropertyChangedSignal(name) self._events[name] = self._events[name] or signal(); return self._events[name] end
function Methods:Destroy()
    self.Destroying:Fire()
    local parent = self.Parent
    while parent do parent.DescendantRemoving:Fire(self); parent = parent.Parent end
    for _, child in ipairs(self:GetChildren()) do child:Destroy() end
    self.Parent = nil
end
function Methods:CaptureFocus() self.Focused:Fire() end
function Methods:ReleaseFocus() self.FocusLost:Fire(false) end

local files, folders, jsonCache = {}, {}, {}
local getcustomasset
local function isfile(path) return files[path] ~= nil end
local function isfolder(path) return folders[path] == true end
local function makefolder(path) folders[path] = true end
local function writefile(path, value) files[path] = value end
local function readfile(path) assert(files[path], "Missing file"); return files[path] end
local function delfile(path) files[path] = nil end
local function listfiles(path)
    local found = {}
    for file in pairs(files) do if file:sub(1, #path + 1) == path .. "/" then found[#found + 1] = file end end
    return found
end
local function clonefunction(value) return value end
local function json(value)
    if type(value) == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
    elseif type(value) == "number" or type(value) == "boolean" then return tostring(value)
    elseif value == nil then return "null" end
    local out = {}
    if #value > 0 then
        for _, item in ipairs(value) do out[#out + 1] = json(item) end
        return '[' .. table.concat(out, ',') .. ']'
    end
    for key, item in pairs(value) do out[#out + 1] = json(tostring(key)) .. ':' .. json(item) end
    return '{' .. table.concat(out, ',') .. '}'
end
local services = {}
local HttpService = {}
function HttpService:JSONEncode(value) local text = json(value); jsonCache[text] = value; return text end
function HttpService:JSONDecode(text)
    if jsonCache[text] then return jsonCache[text] end
    local value = {}
    for key, item in text:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do value[key] = item end
    return value
end
services.HttpService = HttpService
local player = Instance.new("Player")
player.Name = "ExamplePlayer"
function player:GetMouse() return {X = 400, Y = 300} end
player.PlayerGui = Instance.new("PlayerGui")
services.Players = Instance.new("Players"); services.Players.LocalPlayer = player
function services.Players:GetPlayers() return {player} end
services.CoreGui = Instance.new("CoreGui")
services.RunService = Instance.new("RunService")
function services.RunService:IsStudio() return false end
function services.RunService:BindToRenderStep() end
function services.RunService:UnbindFromRenderStep() end
services.TweenService = {Create = function(_, node, _, values)
    return {Play = function() for key, value in pairs(values) do node[key] = value end end, Cancel = function() end}
end}
services.TextService = {GetTextBoundsAsync = function(_, params)
    local length = #params.Text:gsub('<[^>]+>', '') * params.Size * 0.5
    local width = params.Width and math.max(params.Width, 1) or math.huge
    return Vector2.new(math.min(length, width), params.Size * math.max(1, math.ceil(length / width)))
end}
services.UserInputService = Instance.new("UserInputService")
function services.UserInputService:GetPlatform() return Enum.Platform.Windows end
function services.UserInputService:GetFocusedTextBox() return nil end
services.UserInputService.MouseEnabled = true
services.Teams = Instance.new("Teams")
services.SoundService = Instance.new("SoundService")
workspace = Instance.new('Workspace')
workspace.CurrentCamera = Instance.new('Camera')
workspace.CurrentCamera.ViewportSize = Vector2.new(1440, 1000)
local game = {GetService = function(_, name) return assert(services[name], name) end}
function game:HttpGet() return "return {GetAsset = function() return nil end}" end
local environment = {}
local function getgenv() return environment end
local shared = {}
local function tick() return 1 end
local function warn(message) print('WARNING ' .. tostring(message)) end

-- @LIBRARY@
-- @THEME_MANAGER@
-- @SAVE_MANAGER@

local library = loadLibrary()({}, {})
local themeManager = loadThemeManager()
local saveManager = loadSaveManager()
