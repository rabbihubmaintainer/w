-- language: Lua, file: src/features/movement/flight.lua, target: Roblox Executor
-- Flight and Better Flight locomotion engine

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local utility = ctx.utility
    local cheat_client = ctx.cheat_client
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local ws = Services.Workspace
    local rs = Services.RunService
    local uis = Services.UserInputService

    local flight_body_velocity = nil
    local flight_body_gyro = nil
    local flight_connection = nil
    local better_flight_connection = nil

    -- Standard Flight
    function cheat_client.start_flight_rendering()
        if flight_connection then return end
        local char = plr.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart

        flight_body_velocity = Instance.new("BodyVelocity")
        flight_body_velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flight_body_velocity.Velocity = Vector3.zero
        flight_body_velocity.Parent = hrp

        flight_body_gyro = Instance.new("BodyGyro")
        flight_body_gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flight_body_gyro.CFrame = hrp.CFrame
        flight_body_gyro.Parent = hrp

        flight_connection = utility:Connection(rs.RenderStepped, function()
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
            local cam = ws.CurrentCamera
            local moveDir = Vector3.zero
            local Options = getgenv().Options
            local speed = Options and Options.flight_speed and Options.flight_speed.Value or 100

            if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            if moveDir.Magnitude > 0 then
                flight_body_velocity.Velocity = moveDir.Unit * speed
            else
                flight_body_velocity.Velocity = Vector3.zero
            end
            flight_body_gyro.CFrame = cam.CFrame
        end)
    end

    function cheat_client.stop_flight_rendering()
        if flight_connection then
            flight_connection:Disconnect()
            flight_connection = nil
        end
        if flight_body_velocity then flight_body_velocity:Destroy(); flight_body_velocity = nil end
        if flight_body_gyro then flight_body_gyro:Destroy(); flight_body_gyro = nil end
    end

    -- Better Flight
    function cheat_client.start_better_flight()
        if better_flight_connection then return end
        better_flight_connection = utility:Connection(rs.RenderStepped, function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local cam = ws.CurrentCamera
            local Options = getgenv().Options
            local speed = (Options and Options.flight_speed and Options.flight_speed.Value or 100) / 60

            local moveVector = Vector3.zero
            if uis:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end

            if moveVector.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (moveVector.Unit * speed)
                hrp.Velocity = Vector3.zero
            end
        end)
    end

    function cheat_client.stop_better_flight()
        if better_flight_connection then
            better_flight_connection:Disconnect()
            better_flight_connection = nil
        end
    end
end
