-- language: Lua, file: src/features/automation/auto_bag.lua, target: Roblox Executor
-- Auto Bag and Perflora Pebble auto equip loop

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local cs = Services.CollectionService

    local auto_bag_active = false

    function cheat_client.start_auto_bag()
        if auto_bag_active then return end
        auto_bag_active = true

        task.spawn(function()
            while auto_bag_active and shared and not shared.is_unloading do
                local Toggles = getgenv().Toggles
                local Options = getgenv().Options
                if not (Toggles and Toggles.auto_bag and Toggles.auto_bag.Value) then break end

                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local myHrp = plr.Character.HumanoidRootPart
                    local range = Options and Options.bag_range and Options.bag_range.Value or 80

                    for _, target in ipairs(plrs:GetPlayers()) do
                        if target ~= plr and target.Character and not cheat_client:is_friendly(target) then
                            local tHrp = target.Character:FindFirstChild("HumanoidRootPart")
                            local hum = target.Character:FindFirstChild("Humanoid")
                            if tHrp and hum and (cs:HasTag(target.Character, "Knocked") or hum.Health <= 0) then
                                local dist = (myHrp.Position - tHrp.Position).Magnitude
                                if dist <= range then
                                    local sack = plr.Backpack:FindFirstChild("Burlap Sack") or plr.Character:FindFirstChild("Burlap Sack") or plr.Backpack:FindFirstChild("Bag")
                                    if sack and sack.Parent == plr.Backpack then
                                        hum:EquipTool(sack)
                                    end
                                    local click = target.Character:FindFirstChildWhichIsA("ClickDetector", true)
                                    if click then fireclickdetector(click) end
                                end
                            end
                        end
                    end
                end
                task.wait(0.2)
            end
        end)
    end

    function cheat_client.stop_auto_bag()
        auto_bag_active = false
    end
end
