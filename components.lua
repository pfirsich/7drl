local ecs = require("libs.naw")

local m = {}

m.Transform = ecs.Component(function()
    return kaun.newTransform()
end)

m.MeshRender = ecs.Component(function(mesh, shader, uniforms)
    assert(mesh and shader)
    ensureComponent(m.Transform)
    return {
        mesh = mesh,
        shader = shader,
        uniforms = uniforms or {},
    }
end, m.Transform)

m.Velocity = ecs.Component(function()
    return vec3(0, 0, 0)
end)

m.Level = ecs.Component(function(aabb, boxes)
    return {
        aabb = aabb,
        boxes = boxes,
    }
end)

m.PlayerController = ecs.Component(function(controller)
    ensureComponent(m.Transform)
    ensureComponent(m.Velocity)
    return {
        controller = controller,
        onGround = false,
    }
end, m.Transform, m.Velocity)

m.LookatMarker = ecs.Component(function()
    return nil
end, m.Transform)

return m
