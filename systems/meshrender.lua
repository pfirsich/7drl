local comp = require("components")

local MeshRenderSystem = {}

function MeshRenderSystem.tick(world, cameraTransform)
    kaun.clear()
    kaun.clearDepth()

    kaun.setViewTransform(cameraTransform)

    for entity in world:foreachEntity(comp.MeshRender) do
        local meshRender = entity[comp.MeshRender]
        kaun.setModelTransform(entity[comp.Transform])
        meshRender.uniforms.cameraPosition = {cameraTransform:getPosition()}
        kaun.draw(meshRender.mesh, meshRender.shader, meshRender.uniforms)
    end

    kaun.flush()
end

return MeshRenderSystem
