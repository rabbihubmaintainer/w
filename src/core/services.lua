-- language: Lua, file: src/core/services.lua, target: Roblox Executor
-- Service proxy wrapper with cloneref

local cloneref = cloneref or function(v) return v end

local Services = setmetatable({}, {
    __index = function(self, name)
        local success, result = pcall(game.GetService, game, name)
        if success then
            local service = cloneref(result)
            rawset(self, name, service)
            return service
        end
    end
})

return Services
