-- language: Lua, file: src/features/combat/silent_aim.lua, target: Roblox Executor
-- Silent Aim runtime engine: FOV calculation, closest target picker, and GetMouse remote redirector

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local uis = Services.UserInputService
    local rs = Services.RunService
    local ws = Services.Workspace
    local rps = Services.ReplicatedStorage

    local mouse = plr:GetMouse()
    local get_mouse_remote = game.PlaceId ~= 14341521240 and rps:FindFirstChild("Requests") and rps.Requests:FindFirstChild("GetMouse") or nil

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 36
    fov_circle.Radius = 80
    fov_circle.Filled = false
    fov_circle.Visible = false
    fov_circle.Color = Color3.fromRGB(255, 255, 255)

    cheat_client.feature_connections = cheat_client.feature_connections or {}

    local function get_nearest_target()
        local Options = getgenv().Options
        local Toggles = getgenv().Toggles
        local maxFov = Options and Options.SilentAimFov and Options.SilentAimFov.Value or 80
        local mousePos = uis:GetMouseLocation()
        local nearest, shortestDistance = nil, maxFov

        for _, player in ipairs(plrs:GetPlayers()) do
            if player ~= plr and player.Character and not cheat_client:is_friendly(player) then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 then
                    local screenPos, onScreen = ws.CurrentCamera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            nearest = player
                        end
                    end
                end
            end
        end
        return nearest
    end

    local function start_silent_aim()
        if cheat_client.feature_connections.silent_aim then return end

        cheat_client.feature_connections.silent_aim = utility:Connection(rs.Heartbeat, function()
            local Toggles = getgenv().Toggles
            local Options = getgenv().Options
            local hideFov = Toggles and Toggles.HideFovCircle and Toggles.HideFovCircle.Value or false
            local mousePos = uis:GetMouseLocation()

            fov_circle.Position = mousePos
            fov_circle.Radius = Options and Options.SilentAimFov and Options.SilentAimFov.Value or 80
            fov_circle.Visible = not hideFov and (Toggles and Toggles.SilentAim and Toggles.SilentAim.Value or false)

            local target = get_nearest_target()
            if cheat_client.aimbot then
                cheat_client.aimbot.current_target = target
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    cheat_client.aimbot.silent_vector = target.Character.HumanoidRootPart.Position
                else
                    cheat_client.aimbot.silent_vector = nil
                end
            end

            if get_mouse_remote then
                get_mouse_remote.OnClientInvoke = function()
                    if cheat_client.aimbot and cheat_client.aimbot.silent_vector then
                        local camera = ws.CurrentCamera
                        local screenPoint = camera:WorldToScreenPoint(cheat_client.aimbot.silent_vector)
                        return {
                            Hit = CFrame.new(cheat_client.aimbot.silent_vector),
                            Target = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") or mouse.Target,
                            X = screenPoint.X,
                            Y = screenPoint.Y,
                            UnitRay = Ray.new(camera.CFrame.Position, (cheat_client.aimbot.silent_vector - camera.CFrame.Position).Unit)
                        }
                    end
                    return {
                        Hit = mouse.Hit,
                        Target = mouse.Target,
                        UnitRay = mouse.UnitRay,
                        X = mouse.X,
                        Y = mouse.Y
                    }
                end
            end
        end)
    end

    local function stop_silent_aim()
        if cheat_client.feature_connections.silent_aim then
            cheat_client.feature_connections.silent_aim:Disconnect()
            cheat_client.feature_connections.silent_aim = nil
        end
        fov_circle.Visible = false
        if cheat_client.aimbot then
            cheat_client.aimbot.current_target = nil
            cheat_client.aimbot.silent_vector = nil
        end
    end

    cheat_client.start_silent_aim_rendering = start_silent_aim
    cheat_client.stop_silent_aim_rendering = stop_silent_aim
end
