-- language: Lua, file: src/features/visuals/player_esp.lua, target: Roblox Executor
-- 2D Drawing Player ESP (Box, Health Bar, Name, Tags, Intent, Mana, and Observe)

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local ws = Services.Workspace
    local rs = Services.RunService

    cheat_client.player_esp_objects = cheat_client.player_esp_objects or {}
    cheat_client.esp_rendering = cheat_client.esp_rendering or {}

    local function create_esp(target)
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Visible = false

        local name = Drawing.new("Text")
        name.Size = 13
        name.Center = true
        name.Outline = true
        name.Visible = false

        local healthBar = Drawing.new("Line")
        healthBar.Thickness = 2
        healthBar.Visible = false

        local intent = Drawing.new("Text")
        intent.Size = 12
        intent.Center = true
        intent.Outline = true
        intent.Visible = false

        local esp = {
            target = target,
            box = box,
            name = name,
            healthBar = healthBar,
            intent = intent
        }

        function esp:update()
            local Toggles = getgenv().Toggles
            local Options = getgenv().Options
            if not (Toggles and Toggles.PlayerEsp and Toggles.PlayerEsp.Value) then
                self:hide()
                return
            end

            local char = self.target.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
                self:hide()
                return
            end

            local root = char.HumanoidRootPart
            local hum = char.Humanoid
            local pos, onScreen = ws.CurrentCamera:WorldToViewportPoint(root.Position)

            local maxRange = Options and Options.PlayerRange and Options.PlayerRange.Value or 2000
            local dist = (ws.CurrentCamera.CFrame.Position - root.Position).Magnitude
            if not onScreen or dist > maxRange or hum.Health <= 0 then
                self:hide()
                return
            end

            local size = Vector2.new(2000 / pos.Z, 3000 / pos.Z)
            local topLeft = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)

            local isFriendly = cheat_client:is_friendly(self.target)
            local espColor = isFriendly and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)

            -- Box
            if Toggles.PlayerBox and Toggles.PlayerBox.Value then
                self.box.Size = size
                self.box.Position = topLeft
                self.box.Color = espColor
                self.box.Visible = true
            else
                self.box.Visible = false
            end

            -- Name & Distance
            if Toggles.PlayerName and Toggles.PlayerName.Value then
                self.name.Text = string.format("%s [%dm]", cheat_client:get_name(self.target), math.floor(dist))
                self.name.Position = Vector2.new(pos.X, topLeft.Y - 16)
                self.name.Color = Color3.fromRGB(255, 255, 255)
                self.name.Visible = true
            else
                self.name.Visible = false
            end

            -- Health Bar
            if Toggles.PlayerHealth and Toggles.PlayerHealth.Value then
                local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                self.healthBar.From = Vector2.new(topLeft.X - 4, topLeft.Y + size.Y)
                self.healthBar.To = Vector2.new(topLeft.X - 4, topLeft.Y + size.Y - (size.Y * healthPct))
                self.healthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
                self.healthBar.Visible = true
            else
                self.healthBar.Visible = false
            end

            -- Intent
            if Toggles.PlayerIntent and Toggles.PlayerIntent.Value then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    self.intent.Text = tool.Name
                    self.intent.Position = Vector2.new(pos.X, topLeft.Y + size.Y + 2)
                    self.intent.Color = Color3.fromRGB(255, 220, 100)
                    self.intent.Visible = true
                else
                    self.intent.Visible = false
                end
            else
                self.intent.Visible = false
            end
        end

        function esp:hide()
            self.box.Visible = false
            self.name.Visible = false
            self.healthBar.Visible = false
            self.intent.Visible = false
        end

        function esp:destruct()
            self.box:Remove()
            self.name:Remove()
            self.healthBar:Remove()
            self.intent:Remove()
        end

        return esp
    end

    function cheat_client:add_player_esp(target)
        local esp = create_esp(target)
        cheat_client.player_esp_objects[target] = esp
        return esp
    end

    local esp_connection = nil
    function cheat_client.esp_rendering.start_player_esp()
        if esp_connection then return end
        esp_connection = utility:Connection(rs.RenderStepped, function()
            for player, esp in pairs(cheat_client.player_esp_objects) do
                if esp and esp.update then esp:update() end
            end
        end)
    end

    function cheat_client.esp_rendering.stop_player_esp()
        if esp_connection then
            esp_connection:Disconnect()
            esp_connection = nil
        end
        for _, esp in pairs(cheat_client.player_esp_objects) do
            if esp and esp.hide then esp:hide() end
        end
    end
end
