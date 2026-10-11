-- language: Lua, file: src/features/visuals/world_esp.lua, target: Roblox Executor
-- World ESP runtime engine: Trinkets, Ores, Ingredients, NPCs, and Fallions

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local ws = Services.Workspace
    local rs = Services.RunService

    cheat_client.trinket_esp_objects = cheat_client.trinket_esp_objects or {}
    cheat_client.ore_esp_objects = cheat_client.ore_esp_objects or {}
    cheat_client.ingredient_esp_objects = cheat_client.ingredient_esp_objects or {}
    cheat_client.npc_esp_objects = cheat_client.npc_esp_objects or {}

    local function create_label_esp(part, labelText, color)
        local text = Drawing.new("Text")
        text.Size = 13
        text.Center = true
        text.Outline = true
        text.Color = color or Color3.fromRGB(255, 255, 255)
        text.Visible = false

        local esp = {
            part = part,
            text = text,
            labelText = labelText
        }

        function esp:update(maxRange)
            if not self.part or not self.part.Parent then
                self:destruct()
                return
            end

            local pos, onScreen = ws.CurrentCamera:WorldToViewportPoint(self.part.Position)
            local dist = (ws.CurrentCamera.CFrame.Position - self.part.Position).Magnitude

            if onScreen and dist <= (maxRange or 1000) then
                self.text.Position = Vector2.new(pos.X, pos.Y)
                self.text.Text = string.format("%s [%dm]", self.labelText, math.floor(dist))
                self.text.Visible = true
            else
                self.text.Visible = false
            end
        end

        function esp:destruct()
            self.text:Remove()
        end

        return esp
    end

    function cheat_client:identify_trinket(part)
        local idVal = part:FindFirstChild("ID")
        local name = idVal and idVal.Value or "Trinket"
        return name, Color3.fromRGB(255, 200, 50), 1
    end

    function cheat_client:add_trinket_esp(part, name, color)
        local esp = create_label_esp(part, name, color)
        cheat_client.trinket_esp_objects[part] = esp
        return esp
    end

    local trinket_connection = nil
    function cheat_client.esp_rendering.start_trinket_esp()
        if trinket_connection then return end
        trinket_connection = utility:Connection(rs.RenderStepped, function()
            local Options = getgenv().Options
            local range = Options and Options.TrinketRange and Options.TrinketRange.Value or 1000
            for part, esp in pairs(cheat_client.trinket_esp_objects) do
                if esp and esp.update then esp:update(range) end
            end
        end)
    end

    function cheat_client.esp_rendering.stop_trinket_esp()
        if trinket_connection then
            trinket_connection:Disconnect()
            trinket_connection = nil
        end
        for _, esp in pairs(cheat_client.trinket_esp_objects) do
            if esp and esp.destruct then esp:destruct() end
        end
        cheat_client.trinket_esp_objects = {}
    end
end
