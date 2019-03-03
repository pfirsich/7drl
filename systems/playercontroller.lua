local muth = require("muth")
local comp = require("components")
local util = require("util")
local const = require("constants")
local LevelSystem = require("systems.level")

local bool2int = util.bool2int

local PlayerControllerSystem = {}

function PlayerControllerSystem.tick(world, dt)
    for entity in world:foreachEntity(comp.PlayerController) do
        local trafo = entity[comp.Transform]
        local vel = entity[comp.Velocity]
        local player = entity[comp.PlayerController]

        local pos = vec3(trafo:getPosition())

        local move = vec3(0, 0, 0)
        local lk = love.keyboard
        move.x = bool2int(lk.isDown("d")) - bool2int(lk.isDown("a"))
        --move.y = bool2int(lk.isDown("r")) - bool2int(lk.isDown("f"))
        move.z = bool2int(lk.isDown("s")) - bool2int(lk.isDown("w"))

        if move:len() > 0.5 then
            move = vec3(trafo:localDirToWorld(move.x, move.y, move.z))
            move.y = 0
            pos = pos + move:normalize() * const.player.moveSpeed * dt
        end

        vel.y = vel.y - const.player.gravity * dt
        pos = pos + vel * dt

        local height = LevelSystem.castRay(world, pos.x, pos.y, pos.z, 0, -1, 0)
        local camHeight = const.player.camHeight
        if height and height < camHeight then
            vel.y = 0
            pos.y = pos.y - height + camHeight
        end
        if pos.y < camHeight then
            vel.y = 0
            pos.y = camHeight
        end

        player.onGround = height ~= nil and height <= camHeight

        for levelEntity in world:foreachEntity(comp.Level) do
            local level = levelEntity[comp.Level]
            for _, aabb in ipairs(level.boxes) do
                local minX, minY, minZ, maxX, maxY, maxZ = unpack(aabb)
                local mtvX, mtvY, mtvZ = muth.cylinderAABBIntersection(
                    pos.x, pos.y - camHeight/2 + const.player.stepHeight, pos.z, 3, camHeight,
                    minX, minY, minZ, maxX, maxY, maxZ)
                if mtvX and mtvY and mtvZ then
                    pos = pos + vec3(mtvX, mtvY, mtvZ)
                    if mtvY > 0 and vel.y < 0
                            and math.abs(mtvY) > math.abs(mtvX)
                            and math.abs(mtvY) > math.abs(mtvZ) then
                        vel.y = 0
                    end
                end
            end
        end

        trafo:setPosition(pos:unpack())
    end
end

function PlayerControllerSystem.keyPressed(world, key)
    for entity in world:foreachEntity(comp.PlayerController) do
        local vel = entity[comp.Velocity]
        if key == "space" then
            vel.y = math.sqrt(2.0 * const.player.jumpHeight * const.player.gravity)
        end
    end
end

function PlayerControllerSystem.mouseLook(world, dx, dy, sensitivity)
    for entity in world:foreachEntity(comp.PlayerController) do
        local trafo = entity[comp.Transform]
        trafo:rotateWorld(dx * sensitivity, 0, 1, 0)
        trafo:rotate(dy * sensitivity, 1, 0, 0)
    end
end

return PlayerControllerSystem
