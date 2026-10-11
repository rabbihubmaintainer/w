-- language: Lua, file: src/ui/tabs/visuals.lua, target: Roblox Executor
-- Visuals tab UI controls: Player ESP, Chams, Overlays, World ESP, Ingredient ESP, and Ore ESP

return function(ctx)
    local Tabs = ctx.Tabs
    local cheat_client = ctx.cheat_client
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local ws = Services.Workspace
    local Options = getgenv().Options
    local Toggles = getgenv().Toggles
    local is_khei = game.PlaceId == 3541987450 or game.PlaceId == 14341521240
    local FindFirstChild = game.FindFirstChild
    local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA
    local FindFirstChildOfClass = game.FindFirstChildOfClass

    local group_player = Tabs.Visuals:AddLeftGroupbox("Player ESP")
    local group_chams = Tabs.Visuals:AddRightGroupbox("Chams")

    group_player:AddToggle("PlayerEsp", {
        Text = "Player ESP",
        Default = cheat_client.config.player_esp
    }):AddKeyPicker("PlayerEspKeybind", {
        Default = cheat_client.config.player_esp_keybind,
        Text = "Player ESP Toggle",
        Mode = "Toggle",
        SyncToggleState = true,
    })

    Toggles.PlayerEsp:OnChanged(function()
        cheat_client.config.player_esp = Toggles.PlayerEsp.Value
        if Toggles.PlayerEsp.Value then
            cheat_client.player_esp_objects = cheat_client.player_esp_objects or {}
            for _, player in pairs(plrs:GetPlayers()) do
                if player ~= plr and not cheat_client.player_esp_objects[player] then
                    if cheat_client.add_player_esp then
                        cheat_client.player_esp_objects[player] = cheat_client:add_player_esp(player)
                    end
                end
            end
            if cheat_client.esp_rendering and cheat_client.esp_rendering.start_player_esp then
                cheat_client.esp_rendering.start_player_esp()
            end
        else
            if cheat_client.esp_rendering and cheat_client.esp_rendering.stop_player_esp then
                cheat_client.esp_rendering.stop_player_esp()
            end
            local chams_enabled = Toggles and Toggles.PlayerChams and Toggles.PlayerChams.Value
            local esp_still_needed = chams_enabled and ((Toggles and Toggles.PlayerAimbotChams and Toggles.PlayerAimbotChams.Value) or
                                      (Toggles and Toggles.PlayerFriendlyChams and Toggles.PlayerFriendlyChams.Value) or
                                      (Toggles and Toggles.PlayerLowHealth and Toggles.PlayerLowHealth.Value) or
                                      (Toggles and Toggles.PlayerRacialChams and Toggles.PlayerRacialChams.Value))

            if not esp_still_needed then
                for player, esp in pairs(cheat_client.player_esp_objects or {}) do
                    if esp and esp.destruct then esp:destruct() end
                    if cheat_client.player_esp_objects then cheat_client.player_esp_objects[player] = nil end
                end
            end
        end
    end)

    Options.PlayerEspKeybind:OnChanged(function()
        cheat_client.config.player_esp_keybind = Options.PlayerEspKeybind.Value
    end)

    group_player:AddToggle("PlayerName", { Text = "Name", Default = cheat_client.config.player_name })
    group_player:AddToggle("PlayerBox", { Text = "Box", Default = cheat_client.config.player_box })
    group_player:AddToggle("PlayerHealth", { Text = "Health", Default = cheat_client.config.player_health })
    group_player:AddToggle("PlayerTags", { Text = "Tags", Default = cheat_client.config.player_tags })
    group_player:AddToggle("PlayerIntent", { Text = "Intent", Default = cheat_client.config.player_intent })
    group_player:AddToggle("PlayerMana", { Text = "Mana", Default = cheat_client.config.player_mana })
    group_player:AddToggle("PlayerManaText", { Text = "Mana Text", Default = cheat_client.config.player_mana_text })
    group_player:AddToggle("PlayerRacial", { Text = "Racial", Default = cheat_client.config.player_racial })
    group_player:AddToggle("PlayerObserve", { Text = "Observe Block", Default = cheat_client.config.player_observe })
    group_player:AddToggle("PlayerHoverDetails", { Text = "Fade Away", Default = cheat_client.config.player_hover_details })
    group_player:AddSlider("PlayerRange", { Text = "Range", Default = cheat_client.config.player_range, Min = 0, Max = 9000, Rounding = 1 })

    -- Chams
    group_chams:AddToggle("PlayerChams", { Text = "Player Highlights", Tooltip = "Also known as Chams", Default = cheat_client.config.player_chams })
    group_chams:AddDivider()
    group_chams:AddToggle("PlayerFriendlyChams", { Text = "Friendly Chams", Default = cheat_client.config.player_friendly_chams })
    group_chams:AddToggle("PlayerLowHealth", { Text = "Low Health Chams", Default = cheat_client.config.player_low_health })
    group_chams:AddToggle("PlayerAimbotChams", { Text = "Player Aimbot Chams", Default = cheat_client.config.player_aimbot_chams })
    group_chams:AddToggle("PlayerRacialChams", { Text = "Racial Chams", Default = cheat_client.config.player_racial_chams })
    group_chams:AddToggle("PlayerChamsPulse", { Text = "Chams Pulse", Default = cheat_client.config.player_chams_pulse })
    group_chams:AddToggle("PlayerChamsOccluded", { Text = "Chams Occluded", Default = cheat_client.config.player_chams_occluded })

    Toggles.PlayerChams:OnChanged(function()
        cheat_client.config.player_chams = Toggles.PlayerChams.Value
        if cheat_client.esp_rendering and cheat_client.esp_rendering.update_chams then cheat_client.esp_rendering.update_chams() end
    end)
    Toggles.PlayerFriendlyChams:OnChanged(function() if cheat_client.esp_rendering and cheat_client.esp_rendering.update_chams then cheat_client.esp_rendering.update_chams() end end)
    Toggles.PlayerLowHealth:OnChanged(function() if cheat_client.esp_rendering and cheat_client.esp_rendering.update_chams then cheat_client.esp_rendering.update_chams() end end)
    Toggles.PlayerAimbotChams:OnChanged(function() if cheat_client.esp_rendering and cheat_client.esp_rendering.update_chams then cheat_client.esp_rendering.update_chams() end end)
    Toggles.PlayerRacialChams:OnChanged(function() if cheat_client.esp_rendering and cheat_client.esp_rendering.update_chams then cheat_client.esp_rendering.update_chams() end end)

    -- Healthview & Intent
    group_player:AddDivider()
    local hv_connection = nil
    group_player:AddToggle("PlayerHealthview", { Text = "Player Healthview", Default = cheat_client.config.player_healthview })
    Toggles.PlayerHealthview:OnChanged(function()
        local state = Toggles.PlayerHealthview.Value
        cheat_client.config.player_healthview = state
        if state then
            for _, v in pairs(ws.Live:GetChildren()) do
                if v ~= plr.Character then
                    local z = FindFirstChildWhichIsA(v, "Humanoid")
                    if z then
                        z.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                        if FindFirstChild(v, "MonsterInfo") then z.NameDisplayDistance = 0 end
                        z.HealthDisplayDistance = 80
                        z.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                    end
                end
            end
            hv_connection = utility:Connection(ws.Live.ChildAdded, function(ch)
                if ch ~= plr.Character then
                    local z = ch:WaitForChild("Humanoid", 3)
                    if z then
                        z.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                        if FindFirstChild(ch, "MonsterInfo") then z.NameDisplayDistance = 0 end
                        z.HealthDisplayDistance = 80
                        z.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                    end
                end
            end)
        else
            if plr.Character and plr.Backpack and FindFirstChild(plr.Backpack, "HealerVision") then return end
            for _, v in pairs(ws.Live:GetChildren()) do
                if v ~= plr.Character then
                    local z = FindFirstChildWhichIsA(v, "Humanoid")
                    if z then
                        z.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                        if FindFirstChild(v, "MonsterInfo") then z.NameDisplayDistance = 0 end
                        z.HealthDisplayDistance = 0
                        z.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                    end
                end
            end
            if hv_connection then hv_connection:Disconnect(); hv_connection = nil end
        end
    end)

    group_player:AddToggle("LegitIntent", { Text = "Seer Intent", Default = cheat_client.config.legit_intent })
    Toggles.LegitIntent:OnChanged(function(enabled)
        if enabled and cheat_client.legit_intent_setup then cheat_client.legit_intent_setup()
        elseif not enabled and cheat_client.legit_intent_cleanup then cheat_client.legit_intent_cleanup() end
    end)

    -- Overlays
    local group_overlays = Tabs.Visuals:AddRightGroupbox("Overlays")
    group_overlays:AddToggle("mana_overlay", {
        Text = "Mana Overlay",
        Default = cheat_client.config.mana_overlay,
        Callback = function(state)
            cheat_client.config.mana_overlay = state
            if cheat_client.handle_toggle then cheat_client:handle_toggle(state) end
        end
    })

    group_overlays:AddToggle("better_leaderboard", {
        Text = "Better Leaderboard",
        Default = cheat_client.config.better_leaderboard,
        Callback = function(state)
            cheat_client.config.better_leaderboard = state
            if ctx.playerLabels then
                for label, player in pairs(ctx.playerLabels) do
                    if label and label:IsA("TextLabel") and player then
                        if state then
                            label.TextColor3 = Color3.fromRGB(255, 214, 81)
                        else
                            label.TextColor3 = Color3.new(1, 1, 1)
                        end
                    end
                end
            end
        end
    })

    -- World ESP (Trinkets, NPCs, Ores, Ingredients)
    local group_misc_esp = Tabs.Visuals:AddLeftGroupbox("World ESP")
    local group_ingredient_esp = Tabs.Visuals:AddRightGroupbox("Ingredient ESP")
    local group_ore_esp = Tabs.Visuals:AddLeftGroupbox("Ore ESP")

    group_misc_esp:AddToggle("TrinketEsp", { Text = "Trinket ESP", Default = cheat_client.config.trinket_esp })
    Toggles.TrinketEsp:OnChanged(function()
        if Toggles.TrinketEsp.Value then
            cheat_client.trinket_esp_objects = cheat_client.trinket_esp_objects or {}
            for _, object in pairs(ws:GetChildren()) do
                if object.Name == "Part" and FindFirstChild(object, "ID") and not cheat_client.trinket_esp_objects[object] then
                    if cheat_client.identify_trinket and cheat_client.add_trinket_esp then
                        local trinket_name, trinket_color, trinket_zindex = cheat_client:identify_trinket(object)
                        cheat_client:add_trinket_esp(object, trinket_name, trinket_color, trinket_zindex)
                    end
                end
            end
            if cheat_client.esp_rendering and cheat_client.esp_rendering.start_trinket_esp then
                cheat_client.esp_rendering.start_trinket_esp()
            end
        else
            if cheat_client.esp_rendering and cheat_client.esp_rendering.stop_trinket_esp then
                cheat_client.esp_rendering.stop_trinket_esp()
            end
            for trinket, esp in pairs(cheat_client.trinket_esp_objects or {}) do
                if esp and esp.destruct then esp:destruct() end
            end
            cheat_client.trinket_esp_objects = {}
        end
    end)

    group_misc_esp:AddToggle("TrinketShowArea", { Text = "Show Area", Default = cheat_client.config.trinket_show_area })
    group_misc_esp:AddDropdown("TrinketTypes", {
        Text = "Show Types",
        Values = {"Common", "Rare", "Mythic", "Artifact", "Event"},
        Default = {1, 2, 3, 4, 5},
        Multi = true,
        Callback = function(value) cheat_client.config.trinket_types = value end
    })
    group_misc_esp:AddDropdown("TrinketIgnoreRangeTypes", {
        Text = "Unlimited Range For",
        Values = {"Common", "Rare", "Mythic", "Artifact", "Event"},
        Default = {3, 4, 5},
        Multi = true,
        Callback = function(value) cheat_client.config.trinket_ignore_range_types = value end
    })
    group_misc_esp:AddSlider("TrinketRange", { Text = "Range", Default = cheat_client.config.trinket_range, Min = 0, Max = 2000, Rounding = 1 })

    group_chams:AddToggle("ShriekerChams", { Text = "Shrieker Chams", Default = cheat_client.config.shrieker_chams })
    group_misc_esp:AddToggle("FallionEsp", { Text = "Fallion ESP", Default = cheat_client.config.fallion_esp })
    group_misc_esp:AddToggle("NpcEsp", { Text = "NPC ESP", Default = cheat_client.config.npc_esp })

    group_ingredient_esp:AddToggle("IngredientEsp", { Text = "Ingredient ESP", Default = cheat_client.config.ingredient_esp })
    group_ingredient_esp:AddSlider("IngredientRange", { Text = "Range", Default = cheat_client.config.ingredient_range, Min = 0, Max = 2000, Rounding = 1 })

    if game.PlaceId ~= 14341521240 then
        group_ore_esp:AddToggle("ore_esp", {
            Text = "Ore ESP",
            Default = cheat_client.config.ore_esp,
            Callback = function(value) cheat_client.config.ore_esp = value end
        })
        group_ore_esp:AddToggle("mythril_esp", { Text = "Mythril", Default = cheat_client.config.mythril_esp, Callback = function(v) cheat_client.config.mythril_esp = v end })
        group_ore_esp:AddToggle("copper_esp", { Text = "Copper", Default = cheat_client.config.copper_esp, Callback = function(v) cheat_client.config.copper_esp = v end })
        group_ore_esp:AddToggle("iron_esp", { Text = "Iron", Default = cheat_client.config.iron_esp, Callback = function(v) cheat_client.config.iron_esp = v end })
        group_ore_esp:AddToggle("tin_esp", { Text = "Tin", Default = cheat_client.config.tin_esp, Callback = function(v) cheat_client.config.tin_esp = v end })
        group_ore_esp:AddSlider("ore_range", { Text = "Range", Default = cheat_client.config.ore_range, Min = 0, Max = 12000, Rounding = 1, Callback = function(v) cheat_client.config.ore_range = v end })
    end
end
