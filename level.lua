local log = require("log")

local rooms = {}

local vertexFormat = kaun.newVertexFormat({"POSITION", 3, "F32"},
                                          {"NORMAL", 3, "F32"},
                                          {"TEXCOORD0", 2, "F32"})

local REVERSE_DIR = {n = "s", s = "n", o = "e", e = "o"}

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

    return {startX, 0, startY, x + 1, sr, y + 1}
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
                local aabb = expandAABB(imageData, x, y, visited)
                if aabb[5] > 0 then -- maxY
                    table.insert(aabbs, aabb)
                end
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

local function imageFromAABBs(room)
    local imgData = love.image.newImageData(room.aabb[4] - room.aabb[1] + 1, room.aabb[6] - room.aabb[3] + 1)
    for _, aabb in ipairs(room.boxes) do
        local r, g, b, a = love.math.random(), love.math.random(), love.math.random(), 1.0
        for y = aabb[3], aabb[6] do
            for x = aabb[1], aabb[4] do
                imgData:setPixel(x, y, r, g, b, a)
            end
        end
    end
    return imgData
end

local function getRoomsMesh(room)
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

    for _, box in ipairs(room.boxes) do
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

local function parseMetaData(imgData, heightImgData)
    local meta = {
        meta.doors = {},
    }
    local w, h = imgData:getDimensions()
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local side
            if x == 0 then
                side = "w"
            elseif y == 0 then
                side = "n"
            elseif x == w - 1 then
                side = "e"
            elseif y == h - 1 then
                side = "s"
            end
            if side then -- on outside edge
                local r, g, b, a = imgData:getPixel(x, y)
                if r == 0 and g == 1 and b == 0 and a == 0 then
                    local h = heightImgData:getPixel(x, y)
                    meta.doors[side] = {x = x, y = h, z = y}
                end
            end
        end
    end
    return meta
end

local function isFile(path)
    return love.filesystem.getInfo(path, "file") ~= nil
end

function rooms.new(name, xScale, yScale, zScale)
    local lf = love.filesystem
    log.debug("Loading room '%s'", name)

    local room = {}
    local roomPath = ("assets/rooms/%s/"):format(name)
    if isFile(roomPath .. "height.png") then
        room.heightImgData = love.image.newImageData(roomPath .. "height.png")
    else
        log.error("No height map for room!")
        return nil
    end
    local imgSize = {room.heightImgData:getDimensions()}
    room.boxes = splitImageIntoAABB(room.heightImgData)

    if isFile(roomPath .. "meta.png") then
        room.metaImgData = love.image.newImageData(roomPath .. "meta.png")
        if not util.equal({room.metaImgData:getDimensions()}, imgSize) then
            log.error("Metadata image size mismatched!")
        else
            room.metaData = parseMetaData(room.metaImgData, room.heightImgData)
        end
    end

    xScale = xScale or 1
    yScale = yScale or xScale
    zScale = zScale or xScale
    -- rescale boxes here
    for _, aabb in ipairs(room.boxes) do
        aabb[1] = aabb[1] * xScale
        aabb[2] = aabb[2] * yScale
        aabb[3] = aabb[3] * zScale
        aabb[4] = aabb[4] * xScale
        aabb[5] = aabb[5] * yScale
        aabb[6] = aabb[6] * zScale
    end

    room.xScale = xScale
    room.yScale = yScale
    room.zScale = zScale

    room.aabb = getSurroundingAABB(room.boxes)
    room.mesh = getRoomsMesh(room)
    return room
end

function rooms.load()
    local lf = love.filesystem
    local files = lf.getDirectoryItems("assets/rooms")
    for _, file in ipairs(files) do
        local info = lf.getInfo(file, "directory")
        if info then
            rooms.map[file] = rooms.new(file, 2, 12, 2)
        end
    end
end

-- pick an exit, pick a single room and if it doesn't fit, return false
local function addRoom(level, roomIndex)
    local room = level[roomIndex]

    local pos = {0, 0, 0}
    if room then
        local exitDirs = {}
        for door, v in pairs(room.room.doors) do
            if not room.usedDoors[door] then
                table.insert(exitDirs, door)
            end
        end
        local exitDir = util.randomChoice(exits)
        local entryDir = REVERSE_DIR[exitDir]

        local name = nil
        local names = util.keys(rooms.map)
        util.shuffleList(names)
        -- there must be a room that has the exit we want
        for i = 1, #names do
            if rooms.map[names[i]].doors[entryDir] then
                name = names[i]
                break
            end
        end

        local exit = room.room.doors[exitDir]
        local newRoom = rooms.map[name]
        local entry = newRoom.doors[entryDir]

        local position = util.tableDeepCopy(room.position)

        local nsOff = exit.x * room.room.xScale - entry.x * newRoom.xScale
        local yOff = exit.y * room.room.yScale - entry.y * newRoom.yScale
        local ewOff = exit.z * room.room.zScale - entry.z * newRoom.zScale
        local offset = nil
        if exitDir == "n" then
            offset = {nsOff, yOff, -newRoom.aabb[6]}
        elseif exitDir == "s" then
            offset = {nsOff, yOff, room.room.aabb[6]}
        elseif exitDir == "e" then
            offset = {-newRoom.aabb[4], yOff, ewOff}
        elseif exitDir == "w" then 
            offset = {room.room.aabb[4], yOff, ewOff}
        end
        assert(offset)

        local position = {}
        for i = 1, 3 do
            position[i] = room.position[i] + offset[i]
        end

        local aabb = {muth.translateAABB(position[1], position[2], position[3], unpack(newRoom.aabb))}

        for _, other in ipairs(level) do
            if muth.aabbIntersection(aabb[1], aabb[2], aabb[3], aabb[4], aabb[5], aabb[6],
                    other.aabb[1], other.aabb[2], other.aabb[3], other.aabb[4], other.aabb[5], other.aabb[6],
                    1e-6) then 
                return false 
            end
        end

        local newRoom = {
            room = newRoom,
            position = position,
            aabb = aabb,
            usedDoors = {entryDir = true},
        }
    else
        
    end
end

function rooms.generateLevel(roomCount)
    

    local level = {}
    local names = util.keys(rooms.map)

    local lastRoom = nil
    local lastExit = nil
    while #level < roomCount do
        local entryDir = reverseDir[lastExit]

        local name = nil
        while not name do
            name = util.randomChoice(names)
            local hasEntry = lastExit == nil or rooms.map[name].doors[entryDir] ~= nil
            if not hasEntry then
                name = nil
            end
        end
        local newRoom = rooms.map[name]

        local offset = {0, 0}
        if lastRoom then
        end
    end
end

-- there is a significant difference between adding a new room to the most recently added room
-- (the level becomes sort of a crooked snake) and adding a new room to a random room already in
-- the level (similar to a 2D random walk - ends up as a gaussian blob). There are various
-- interpolations between this and also arbitrarily strange schemes (i.e. every third room should
-- have exactly two branches of the same length).
-- Therefore I decide to not make this data-driven but rather try to encapsulate common functionality
-- and the generator functions represent "generator scripts" for levels.

function rooms.linearGenerator(level, roomCount)
    local function linearAppendRooms(level, roomCount)
        if roomCount > 0 then
            return addRoom(level, #level) and linearAppendRooms(level, roomCount - 1)
        else
            return true
        end
    end

    if linearAppendRooms(level, roomCount) then
        -- construct entities
    else
        log.error("Could not generate level")
    end
end

function rooms.saveDebugAABBImage(room, path)
    imageFromAABBs(room):encode("png", path or "rooms_debug.png")
end

return rooms
