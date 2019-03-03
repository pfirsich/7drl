local muth = require("muth")
local comp = require("components")

local LevelSystem = {}

function LevelSystem.castRay(world, x, y, z, dx, dy, dz)
    local minT
    for levelEntity in world:foreachEntity(comp.Level) do
        local level = levelEntity[comp.Level]
        for _, aabb in ipairs(level.boxes) do
            local minX, minY, minZ, maxX, maxY, maxZ = unpack(aabb)
            local t = muth.castRayIntoAABB(x, y, z, dx, dy, dz,
                minX, minY, minZ, maxX, maxY, maxZ)
            if t and t > 0 and (not minT or t < minT) then
                minT = t
            end
        end
    end
    return minT
end

return LevelSystem
