return setmetatable({}, {__index = function(tbl, name)
    return assert(love.filesystem.read(("assets/shaders/%s.glsl"):format(name)))
end})
