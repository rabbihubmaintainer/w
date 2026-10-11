-- language: Lua, file: src/features/combat/parry.lua, target: Roblox Executor
-- Auto Parry and Auto Perfect Block runtime engine (Owlslash, Shadowrush, Verdien, Viribus, Grapple)

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local vim = Services.VirtualInputManager
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local ws = Services.Workspace

    local FindFirstChild = game.FindFirstChild
    local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA

    local DETECTION_RANGE = 75
    local EARTH_PILLAR_PARRY_DISTANCE = 40
    local EARTH_PILLAR_BLOCK_DURATION = 0.35

    local AUTO_PARRY_SOUNDS = {
        ["OwlSlash"] = { delay = 0.25, blockDuration = 0.4, requiresVisibility = true },
        ["Shadowrush"] = { delay = 0.18, blockDuration = 0.35, requiresVisibility = true },
        ["ShadowrushCharge"] = { delay = 0.18, blockDuration = 0.35, requiresVisibility = true },
        ["PerfectCast"] = { delay = 0.1, blockDuration = 0.4, requiresVisibility = true }
    }

    local function block_f(duration)
        vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(duration or 0.3)
        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end

    local function performAutoParry(delayTime, duration, isSpell, attackingPlayer)
        local Options = getgenv().Options
        local Toggles = getgenv().Toggles

        if attackingPlayer and cheat_client:is_friendly(attackingPlayer) then return end
        if Toggles and Toggles.ParryDisableWhenUnfocused and Toggles.ParryDisableWhenUnfocused.Value and not shared.windowActive then return end

        local actualDelay = delayTime
        if Toggles and Toggles.ParryCustomDelay and Toggles.ParryCustomDelay.Value and Options and Options.ParryCustomDelayMs then
            actualDelay = actualDelay + (Options.ParryCustomDelayMs.Value / 1000)
        end

        if actualDelay > 0 then task.wait(actualDelay) end
        block_f(duration)
    end

    -- Hook sound listener for players
    local function handle_character(character)
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        utility:Connection(root.ChildAdded, function(child)
            if child:IsA("Sound") and AUTO_PARRY_SOUNDS[child.Name] then
                local Toggles = getgenv().Toggles
                local Options = getgenv().Options
                if not (Toggles and Toggles.AutoPerfectBlock and Toggles.AutoPerfectBlock.Value) then return end

                local player = plrs:GetPlayerFromCharacter(character)
                local soundInfo = AUTO_PARRY_SOUNDS[child.Name]
                task.spawn(function()
                    performAutoParry(soundInfo.delay, soundInfo.blockDuration, false, player)
                end)
            end
        end)
    end

    for _, player in ipairs(plrs:GetPlayers()) do
        if player ~= plr and player.Character then
            handle_character(player.Character)
        end
    end

    utility:Connection(plrs.PlayerAdded, function(player)
        if player ~= plr then
            player.CharacterAdded:Connect(handle_character)
        end
    end)
end
