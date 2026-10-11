-- language: Lua, file: src/features/visuals/chams.lua, target: Roblox Executor
-- Highlight and Chams engine (Player Chams, Friendly Chams, Low Health, Racial)

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer

    local chams_instances = {}

    local function apply_cham(target)
        if target == plr or not target.Character then return end
        local char = target.Character
        local isFriendly = cheat_client:is_friendly(target)

        local highlight = char:FindFirstChild("RabbiCham")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "RabbiCham"
            highlight.Adornee = char
            highlight.Parent = char
        end

        local Toggles = getgenv().Toggles
        if not (Toggles and Toggles.PlayerChams and Toggles.PlayerChams.Value) then
            highlight.Enabled = false
            return
        end

        highlight.Enabled = true
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0

        if isFriendly and Toggles.PlayerFriendlyChams and Toggles.PlayerFriendlyChams.Value then
            highlight.FillColor = Color3.fromRGB(0, 255, 120)
            highlight.OutlineColor = Color3.fromRGB(0, 200, 80)
        else
            highlight.FillColor = Color3.fromRGB(255, 60, 60)
            highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
        end
    end

    function cheat_client.esp_rendering.update_chams()
        for _, player in ipairs(plrs:GetPlayers()) do
            if player ~= plr then apply_cham(player) end
        end
    end

    utility:Connection(plrs.PlayerAdded, function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            apply_cham(player)
        end)
    end)
end
