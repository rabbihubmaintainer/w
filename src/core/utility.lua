-- language: Lua, file: src/core/utility.lua, target: Roblox Executor
-- Binary serialization (BitBuffer/crypt), drawing wrapper, server hopping, and math/connection utils

return function(ctx)
    local Services = ctx.Services
    local shared = ctx.shared
    local cheat_client = ctx.cheat_client
    local ws = Services.Workspace
    local plrs = Services.Players
    local plr = plrs.LocalPlayer
    local uis = Services.UserInputService
    local rps = Services.ReplicatedStorage
    local tps = Services.TeleportService
    local mem = Services.MemStorageService
    local cs = Services.CollectionService

    local is_gaia = game.PlaceId == 5208655184
    local is_khei = game.PlaceId == 3541987450 or game.PlaceId == 14341521240

    local join_server = game.PlaceId == 14341521240 and nil or rps:WaitForChild("Requests"):WaitForChild("JoinPublicServer")
    local mana_remote = nil

    local utility = {
        day_cache = 0,
    }

    -- Fast table removal
    local function fast_remove(tbl, value)
        for i = #tbl, 1, -1 do
            if tbl[i] == value then
                tbl[i] = tbl[#tbl]
                tbl[#tbl] = nil
                return true
            end
        end
        return false
    end

    local function ToBase(n, b)
        local floor, insert = math.floor, table.insert
        n = floor(n)
        if not b or b == 10 then return tostring(n) end
        local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local t = {}
        local sign = ""
        if n < 0 then
            sign = "-"
            n = -n
        end
        repeat
            local d = (n % b) + 1
            n = floor(n / b)
            insert(t, 1, digits:sub(d, d))
        until n == 0
        return sign .. table.concat(t, "")
    end

    -- BitBuffer
    local BitBuffer = {}
    do
        local NumberToBase64 = {}
        local Base64ToNumber = {}
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        for i = 1, #chars do
            local ch = chars:sub(i, i)
            NumberToBase64[i-1] = ch
            Base64ToNumber[ch] = i-1
        end

        local PowerOfTwo = {}
        for i = 0, 64 do
            PowerOfTwo[i] = 2^i
        end

        local BrickColorToNumber = {}
        local NumberToBrickColor = {}
        for i = 0, 63 do
            local color = BrickColor.palette(i)
            BrickColorToNumber[color.Number] = i
            NumberToBrickColor[i] = color
        end

        local floor = math.floor
        local abs, sqrt = math.abs, math.sqrt
        local max, min, ceil = math.max, math.min, math.ceil

        function BitBuffer.Create()
            local this = {}
            local mBitPtr = 0
            local mBitBuffer = {}

            function this:ResetPtr() mBitPtr = 0 end
            function this:Reset() mBitBuffer = {}; mBitPtr = 0 end
            function this:FromString(str)
                this:Reset()
                for i = 1, #str do
                    local b = str:byte(i)
                    for j = 7, 0, -1 do
                        mBitBuffer[#mBitBuffer + 1] = (b >= PowerOfTwo[j]) and 1 or 0
                        if b >= PowerOfTwo[j] then b = b - PowerOfTwo[j] end
                    end
                end
            end
            function this:ToString()
                local t = {}
                for i = 1, #mBitBuffer, 8 do
                    local b = 0
                    for j = 0, 7 do
                        if mBitBuffer[i + j] == 1 then b = b + PowerOfTwo[7 - j] end
                    end
                    t[#t + 1] = string.char(b)
                end
                return table.concat(t)
            end
            function this:FromBase64(str)
                this:Reset()
                for i = 1, #str do
                    local b = Base64ToNumber[str:sub(i, i)] or 0
                    for j = 5, 0, -1 do
                        mBitBuffer[#mBitBuffer + 1] = (b >= PowerOfTwo[j]) and 1 or 0
                        if b >= PowerOfTwo[j] then b = b - PowerOfTwo[j] end
                    end
                end
            end
            function this:ToBase64()
                local t = {}
                for i = 1, #mBitBuffer, 6 do
                    local b = 0
                    for j = 0, 5 do
                        if mBitBuffer[i + j] == 1 then b = b + PowerOfTwo[5 - j] end
                    end
                    t[#t + 1] = NumberToBase64[b] or "A"
                end
                return table.concat(t)
            end

            local function writeBit(v)
                mBitPtr = mBitPtr + 1
                mBitBuffer[mBitPtr] = (v == 1 or v == true) and 1 or 0
            end
            local function readBit()
                mBitPtr = mBitPtr + 1
                return mBitBuffer[mBitPtr] or 0
            end

            function this:WriteUnsigned(w, value)
                value = math.floor(value)
                for i = w - 1, 0, -1 do
                    if value >= PowerOfTwo[i] then
                        writeBit(1)
                        value = value - PowerOfTwo[i]
                    else
                        writeBit(0)
                    end
                end
            end
            function this:ReadUnsigned(w)
                local value = 0
                for i = w - 1, 0, -1 do
                    if readBit() == 1 then value = value + PowerOfTwo[i] end
                end
                return value
            end
            function this:WriteSigned(w, value)
                if value < 0 then
                    writeBit(1)
                    this:WriteUnsigned(w - 1, -value)
                else
                    writeBit(0)
                    this:WriteUnsigned(w - 1, value)
                end
            end
            function this:ReadSigned(w)
                local sign = readBit()
                local val = this:ReadUnsigned(w - 1)
                return sign == 1 and -val or val
            end
            function this:WriteString(s)
                this:WriteUnsigned(16, #s)
                for i = 1, #s do this:WriteUnsigned(8, s:byte(i)) end
            end
            function this:ReadString()
                local len = this:ReadUnsigned(16)
                local t = {}
                for i = 1, len do t[i] = string.char(this:ReadUnsigned(8)) end
                return table.concat(t)
            end
            function this:WriteBool(v) writeBit(v) end
            function this:ReadBool() return readBit() == 1 end

            return this
        end
    end

    -- Drawing wrappers
    function utility:Create(instanceType, instanceProperties, container)
        local instance = Drawing.new(instanceType)
        local parent = instanceProperties["Parent"] or instanceProperties["parent"]
        instanceProperties["parent"] = nil
        instanceProperties["Parent"] = nil

        for property, value in pairs(instanceProperties) do
            if property and value ~= nil then
                if property == "Size" then
                    if instanceType == "Text" then
                        instance.Size = value
                    else
                        local xSize = (value.X.Scale * ((parent and parent.Size) or ws.CurrentCamera.ViewportSize).X) + value.X.Offset
                        local ySize = (value.Y.Scale * ((parent and parent.Size) or ws.CurrentCamera.ViewportSize).Y) + value.Y.Offset
                        instance.Size = Vector2.new(xSize, ySize)
                    end
                elseif property == "Position" then
                    if instanceType == "Text" then
                        local xPos = ((((parent and parent.Position) or Vector2.new(0, 0)).X) + (value.X.Scale * ((typeof(parent.Size) == "number" and parent.TextBounds) or parent.Size).X)) + value.X.Offset
                        local yPos = ((((parent and parent.Position) or Vector2.new(0, 0)).Y) + (value.Y.Scale * ((typeof(parent.Size) == "number" and parent.TextBounds) or parent.Size).Y)) + value.Y.Offset
                        instance.Position = Vector2.new(xPos, yPos)
                    else
                        local xPos = ((((parent and parent.Position) or Vector2.new(0, 0)).X) + value.X.Scale * ((parent and parent.Size) or ws.CurrentCamera.ViewportSize).X) + value.X.Offset
                        local yPos = ((((parent and parent.Position) or Vector2.new(0, 0)).Y) + value.Y.Scale * ((parent and parent.Size) or ws.CurrentCamera.ViewportSize).Y) + value.Y.Offset
                        instance.Position = Vector2.new(xPos, yPos)
                    end
                elseif property == "Color" then
                    if typeof(value) == "string" then
                        instance["Color"] = shared.theme[value]
                        if value == "accent" then
                            shared.accents[#shared.accents + 1] = instance
                        end
                    else
                        instance[property] = value
                    end
                else
                    instance[property] = value
                end
            end
        end
        if container and shared.drawing_containers[container] then
            shared.drawing_containers[container][#shared.drawing_containers[container] + 1] = instance
        end
        return instance
    end

    function utility:Connection(connectionType, connectionCallback, skip_tracking)
        local connection = connectionType:Connect(connectionCallback)
        if shared.connections and not skip_tracking then
            shared.connections[#shared.connections + 1] = connection
        end
        return connection
    end

    function utility:RemoveConnection(connection)
        if not shared or not shared.connections then return end
        for index = #shared.connections, 1, -1 do
            if shared.connections[index] == connection then
                connection:Disconnect()
                table.remove(shared.connections, index)
                break
            end
        end
    end

    function utility:Instance(class_name, properties)
        local object = Instance.new(class_name)
        for i, v in next, properties do
            object[i] = v
        end
        return object
    end

    function utility:plain_webhook(content)
        if cheat_client.config.webhook and cheat_client.config.webhook ~= "" then
            pcall(function()
                HXD_SEND_WEBHOOK(cheat_client.config.webhook, {
                    username = cheat_client.config.webhook_username or "bladee",
                    content = content
                })
            end)
        end
    end

    -- Server hop history & functions
    local ROBLOX_GAMES_API = "https://games.roblox.com/v1/games/%s/servers/0"
    local SERVER_HISTORY_KEY = "RecentServers_" .. game.PlaceId
    local MAX_HISTORY_SIZE = 15

    local function get_server_history()
        local success, stored = pcall(function()
            return mem:GetItem(SERVER_HISTORY_KEY)
        end)
        if success and stored then
            local decode_success, history = pcall(function()
                return Services.HttpService:JSONDecode(stored)
            end)
            if decode_success and type(history) == "table" then
                return history
            end
        end
        return {}
    end

    function utility:add_server_to_history(jobId)
        local history = get_server_history()
        table.insert(history, 1, jobId)
        while #history > MAX_HISTORY_SIZE do
            table.remove(history)
        end
        pcall(function()
            mem:SetItem(SERVER_HISTORY_KEY, Services.HttpService:JSONEncode(history))
        end)
    end

    function utility:clear_server_history()
        pcall(function()
            mem:SetItem(SERVER_HISTORY_KEY, Services.HttpService:JSONEncode({}))
        end)
    end

    function utility:Serverhop()
        if join_server then
            join_server:FireServer()
        else
            tps:Teleport(game.PlaceId, plr)
        end
    end

    ctx.utility = utility
    return utility
end
