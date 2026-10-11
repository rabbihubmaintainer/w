-- language: Lua, file: src/core/game_client.lua, target: Roblox Executor
-- Rogue Lineage / Deepwoken game state queries, race detection, player name formatting, and mod detection

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local cheat_client = ctx.cheat_client
    local utility = ctx.utility

    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local rps = Services.ReplicatedStorage
    local cg = Services.CoreGui
    local deb = Services.Debris

    local FindFirstChild = game.FindFirstChild

    -- Race detection
    local player_races = {}
    local race_colors = {}
    if FindFirstChild(rps, 'Info') and FindFirstChild(rps.Info, 'Races') then
        for _, v in next, rps.Info.Races:GetChildren() do
            if v:FindFirstChild("EyeColor") and v:FindFirstChild("SkinColor") then
                race_colors[#race_colors + 1] = {tostring(v.EyeColor.Value), tostring(v.SkinColor.Value), v.Name}
            end
        end
    end

    utility:Connection(plrs.PlayerRemoving, function(player)
        player_races[player] = nil
    end)

    function cheat_client:get_race(player)
        if player_races[player] and tick() - player_races[player].lastUpdateAt <= 5 then
            return player_races[player].name
        end

        local head = player.Character and FindFirstChild(player.Character, 'Head')
        local face = head and FindFirstChild(head, 'RLFace')
        local scroomHead = player.Character and FindFirstChild(player.Character, 'ScroomHead')
        local raceFound = 'Unknown'

        if not face then return raceFound end

        if scroomHead then
            if scroomHead.Material.Name == 'DiamondPlate' then
                raceFound = 'Metascroom'
            else
                raceFound = 'Scroom'
            end
        end

        if raceFound == 'Unknown' then
            for _, v2 in next, race_colors do
                local eyeColor, skinColor, raceName = v2[1], v2[2], v2[3]
                if tostring(head.Color) == skinColor and tostring(face.Color3) == eyeColor then
                    raceFound = raceName
                    break
                end
            end
        end

        player_races[player] = {
            lastUpdateAt = tick(),
            name = raceFound
        }
        return raceFound
    end

    -- Name and Uber Title resolver
    local function is_empty(s) return s == nil or s == "" end

    function cheat_client:get_name(player)
        if game.PlaceId == 5208655184 or game.PlaceId == 109732117428502 then
            if not player:GetAttribute("FirstName") or player:GetAttribute("FirstName") == "" then
                return "nil"
            end
            local firstName = player:GetAttribute('FirstName')
            local lastName = player:GetAttribute("LastName")
            local uberTitle = player:GetAttribute("UberTitle")
            local fullName = (lastName and lastName ~= "") and (firstName .. " " .. lastName) or firstName
            return not is_empty(uberTitle) and (fullName .. ", " .. uberTitle) or fullName
        elseif game.PlaceId == 3541987450 or game.PlaceId == 14341521240 then
            local leaderstats = FindFirstChild(player, "leaderstats")
            if not leaderstats or not FindFirstChild(leaderstats, "FirstName") then
                return "nil"
            end
            local firstName = leaderstats.FirstName.Value
            local lastName = FindFirstChild(leaderstats, "LastName") and leaderstats.LastName.Value or ""
            local uberTitle = FindFirstChild(leaderstats, "UberTitle") and leaderstats.UberTitle.Value or ""
            local fullName = (lastName ~= "") and (firstName .. " " .. lastName) or firstName
            return not is_empty(uberTitle) and (fullName .. ", " .. uberTitle) or fullName
        else
            return "nil"
        end
    end

    -- Friendly / Ally Resolver
    function cheat_client:is_friendly(player)
        local Toggles = getgenv().Toggles
        local ignore_friendly = Toggles and Toggles.ignore_friendly
        if ignore_friendly and ignore_friendly.Value then return false end

        local auto_housemate_ally = Toggles and Toggles.auto_housemate_ally and Toggles.auto_housemate_ally.Value or false
        local auto_friend_ally = Toggles and Toggles.auto_friend_ally and Toggles.auto_friend_ally.Value or false

        if game.PlaceId == 5208655184 then
            local lastName1 = player:GetAttribute("LastName")
            local lastName2 = plr:GetAttribute("LastName")
            local is_housemate = lastName1 and lastName1 ~= "" and lastName1 == lastName2
            local is_friend = plr:IsFriendsWith(player.UserId)
            local is_manual_friend = cheat_client and cheat_client.friends and table.find(cheat_client.friends, player.UserId) ~= nil
            return (auto_housemate_ally and is_housemate) or (auto_friend_ally and is_friend) or is_manual_friend
        elseif game.PlaceId == 3541987450 or game.PlaceId == 14341521240 then
            local stats1 = FindFirstChild(player, "leaderstats")
            local stats2 = FindFirstChild(plr, "leaderstats")
            if not stats1 or not stats2 then return false end
            local lastName1 = FindFirstChild(stats1, "LastName")
            local lastName2 = FindFirstChild(stats2, "LastName")
            local is_housemate = lastName1 and lastName2 and lastName1.Value == lastName2.Value
            local is_friend = plr:IsFriendsWith(player.UserId)
            local is_manual_friend = table.find(cheat_client.friends, player.UserId) ~= nil
            return (auto_housemate_ally and is_housemate) or (auto_friend_ally and is_friend) or is_manual_friend
        end

        local is_friend = plr:IsFriendsWith(player.UserId)
        local is_manual_friend = table.find(cheat_client.friends, player.UserId) ~= nil
        return (auto_friend_ally and is_friend) or is_manual_friend
    end

    function utility:sound(Id, Removal)
        local Toggles = getgenv().Toggles
        if cheat_client and shared and Toggles and Toggles.notifications and Toggles.notifications.Value then
            local volume = cheat_client.config.notification_volume or 5
            local Sound = utility:Instance("Sound", {
                SoundId = Id,
                Volume = volume,
                Parent = cg
            })
            Sound:Play()
            deb:AddItem(Sound, Removal)
        end
    end

    ctx.game_client = cheat_client
    return cheat_client
end
