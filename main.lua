kaun = require("kaun")
cpml = require("libs.cpml")
inspect = require("libs.inspect")
vec3 = cpml.vec3
mat4 = cpml.mat4

local shaders = require("shaders")
local rooms = require("rooms")
local util = require("util")
local world = require("world")
local comp = require("components")

local PlayerControllerSystem = require("systems.playercontroller")
local MeshRenderSystem = require("systems.meshrender")
local LookatMarkerSystem = require("systems.lookatmarker")

-- RESOURCES
local shader = kaun.newShader(shaders.defaultVertex, shaders.defaultTexturedLambert)
local colorShader = kaun.newShader(shaders.defaultVertex, shaders.defaultColorLambert)

local texture = kaun.newCheckerTexture(512, 512, 64)
texture:setWrap("repeat", "repeat")

-- INIT ENTITIES
rooms.load()
local levelEntities = room.generateLevel(6)
local levelInstance = level.new("testlevel.png", 2, 12, 2)

local levelEntity = world:Entity()
levelEntity:addComponent(comp.MeshRender, levelInstance.mesh, shader, {
    color = {1, 1, 1, 1},
    baseTexture = texture,
})
levelEntity:addComponent(comp.Level, levelInstance.aabb, levelInstance.boxes)

local player = world:Entity()
player:addComponent(comp.Transform):setPosition(
    levelInstance.aabb[1] + levelInstance.aabb[4] / 2,
    levelInstance.aabb[5],
    levelInstance.aabb[3] + levelInstance.aabb[6] / 2)
player:addComponent(comp.PlayerController, {})
player:addComponent(comp.LookatMarker)

function love.resize(w, h)
    kaun.setProjection(45, w/h, 0.1, 1000.0)
    kaun.setWindowDimensions(w, h)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    PlayerControllerSystem.keyPressed(world, key)
end

function love.mousemoved(x, y, dx, dy)
    local winW, winH = love.graphics.getDimensions()
    if love.mouse.isDown(1) then
        PlayerControllerSystem.mouseLook(world, dx / winW, dy / winH, 5.0)
    end
end

function love.update(dt)
    PlayerControllerSystem.tick(world, dt)
    LookatMarkerSystem.tick(world)
end

function love.draw()
    MeshRenderSystem.tick(world, player:getComponent(comp.Transform))
end
