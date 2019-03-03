local level = {}

local vertexFormat = kaun.newVertexFormat({"POSITION", 3, "F32"},
                                          {"NORMAL", 3, "F32"},
                                          {"TEXCOORD0", 2, "F32"})

local function expandAABB(imageData, x, y, visited)
    local startX, startY = x, y
    local sr, sg, sb, sa = imageData:getPixel(x, y)

    while x < imageData:getWidth() - 1 do
        local r, g, b, a = imageData:getPixel(x + 1, y)
        if r == sr and g == sg and b == sb and a == sa and not visited[y][x + 1] then
            x = x + 1
        else
            break
        end
    end

    while y < imageData:getHeight() - 1 do
        local valid = true
        for cx = startX, x do
            local r, g, b, a = imageData:getPixel(cx, y + 1)
            if r ~= sr or g ~= sg or b ~= sb or a ~= sa or visited[y + 1][cx] then
                valid = false
                break
            end
        end
        if valid then
            y = y + 1
        else
            break
        end
    end

    for cy = startY, y do
        for cx = startX, x do
            visited[cy][cx] = true
        end
    end

    return {startX, 0, startY, x + 1, 1 - sr, y + 1}
end

local function splitImageIntoAABB(imageData)
    local width, height = imageData:getWidth(), imageData:getHeight()

    local visited = {}
    for y = 0, height - 1 do
        visited[y] = {}
    end

    local aabbs = {}
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if not visited[y][x] then
                table.insert(aabbs, expandAABB(imageData, x, y, visited))
            end
        end
    end
    return aabbs
end

local function getSurroundingAABB(aabbs)
    local fullAABB = {math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge}
    for _, aabb in ipairs(aabbs) do
        fullAABB[1] = math.min(fullAABB[1], aabb[1])
        fullAABB[2] = math.min(fullAABB[2], aabb[2])
        fullAABB[3] = math.min(fullAABB[3], aabb[3])
        fullAABB[4] = math.max(fullAABB[4], aabb[4])
        fullAABB[5] = math.max(fullAABB[5], aabb[5])
        fullAABB[6] = math.max(fullAABB[6], aabb[6])
    end
    return fullAABB
end

local function imageFromAABBs(lvl)
    local imgData = love.image.newImageData(lvl.aabb[4] - lvl.aabb[1] + 1, lvl.aabb[6] - lvl.aabb[3] + 1)
    for _, aabb in ipairs(lvl.boxes) do
        local r, g, b, a = love.math.random(), love.math.random(), love.math.random(), 1.0
        for y = aabb[3], aabb[6] do
            for x = aabb[1], aabb[4] do
                imgData:setPixel(x, y, r, g, b, a)
            end
        end
    end
    return imgData
end

local function getLevelMesh(lvl)
    local vertices = {}

    local function pushVertex(x, y, z, nx, ny, nz, uAxis, vAxis)
        local texScale = 0.1
        local p = {x, y, z}
        table.insert(vertices, {x, y, z, nx, ny, nz, p[uAxis] * texScale, p[vAxis] * texScale})
    end

    -- four corners xn, yn, zn
    local function pushPlane(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, nx, ny, nz, uAxis, vAxis)
        pushVertex(x1, y1, z1, nx, ny, nz, uAxis, vAxis)
        pushVertex(x2, y2, z2, nx, ny, nz, uAxis, vAxis)
        pushVertex(x3, y3, z3, nx, ny, nz, uAxis, vAxis)

        pushVertex(x3, y3, z3, nx, ny, nz, uAxis, vAxis)
        pushVertex(x2, y2, z2, nx, ny, nz, uAxis, vAxis)
        pushVertex(x4, y4, z4, nx, ny, nz, uAxis, vAxis)
    end

    for _, box in ipairs(lvl.boxes) do
        local minX, minY, minZ, maxX, maxY, maxZ = unpack(box)
        pushPlane(minX, minY, minZ,   minX, minY, maxZ,   minX, maxY, minZ,   minX, maxY, maxZ,  -1,  0,  0,   3, 2) -- minX
        pushPlane(maxX, minY, maxZ,   maxX, minY, minZ,   maxX, maxY, maxZ,   maxX, maxY, minZ,   1,  0,  0,   3, 2) -- maxX
        pushPlane(minX, minY, minZ,   maxX, minY, minZ,   minX, minY, maxZ,   maxX, minY, maxZ,   0, -1,  0,   1, 3) -- minY
        pushPlane(minX, maxY, maxZ,   maxX, maxY, maxZ,   minX, maxY, minZ,   maxX, maxY, minZ,   0,  1,  0,   1, 3) -- maxY
        pushPlane(maxX, minY, minZ,   minX, minY, minZ,   maxX, maxY, minZ,   minX, maxY, minZ,   0,  0, -1,   1, 2) -- minZ
        pushPlane(minX, minY, maxZ,   maxX, minY, maxZ,   minX, maxY, maxZ,   maxX, maxY, maxZ,   0,  0,  1,   1, 2) -- maxZ
    end

    return kaun.newMesh("triangles", vertexFormat, vertices)
end

function level.new(imagePath, xScale, yScale, zScale)
    local lvl = {}
    lvl.imageData = love.image.newImageData(imagePath)
    lvl.boxes = splitImageIntoAABB(lvl.imageData)

    xScale = xScale or 1
    yScale = yScale or xScale
    zScale = zScale or xScale
    -- rescale boxes here
    for _, aabb in ipairs(lvl.boxes) do
        aabb[1] = aabb[1] * xScale
        aabb[2] = aabb[2] * yScale
        aabb[3] = aabb[3] * zScale
        aabb[4] = aabb[4] * xScale
        aabb[5] = aabb[5] * yScale
        aabb[6] = aabb[6] * zScale
    end

    lvl.aabb = getSurroundingAABB(lvl.boxes)
    lvl.mesh = getLevelMesh(lvl)
    return lvl
end

function level.saveDebugAABBImage(lvl, path)
    imageFromAABBs(lvl):encode("png", path or "level_debug.png")
end

return level
