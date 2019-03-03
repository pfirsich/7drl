local comp = require("components")
local shaders = require("shaders")
local LevelSystem = require("systems.level")

local LookatMarkerSystem = {}

local mesh = kaun.newSphereMesh(0.5, 32, 32)
local shader = kaun.newShader(shaders.defaultVertex, shaders.defaultColorLambert)

function LookatMarkerSystem.tick(world)
    for entity in world:foreachEntity(comp.LookatMarker) do
        local lookatEntity = entity[comp.LookatMarker]
        if not lookatEntity then
            lookatEntity = world:Entity()
            lookatEntity:addComponent(comp.MeshRender, mesh, shader)
            entity[comp.LookatMarker] = lookatEntity
        end
        local markerTrafo, markerMesh = lookatEntity:getComponents(comp.Transform, comp.MeshRender)

        local trafo = entity[comp.Transform]
        local x, y, z = trafo:getPosition()
        local dx, dy, dz = trafo:getForward()
        local t = LevelSystem.castRay(world, x, y, z, dx, dy, dz)
        if t then
            markerTrafo:setPosition(x + t*dx, y + t*dy, z + t*dz)
            markerMesh.uniforms.color = {1, 0, 0, 1}
        else
            markerMesh.uniforms.color = {0.1, 0, 0, 1}
        end
    end
end

return LookatMarkerSystem
