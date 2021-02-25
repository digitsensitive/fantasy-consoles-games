-- title:  downhill
-- author: digitsensitive
-- desc:    ski downhill as far as possible
-- script: lua

-- global game settings --------------------------------------------------------
local GS = {
    W = 240,
    H = 136,
    HW = 240 / 2,
    HH = 136 / 2,
    t = 0,
    spawnTime = 10,
    scrollSpeed = 1,
    gameOver = false,
    shake = 30,
    shakeD = 4,
    cs = nil
}

-- game objects ----------------------------------------------------------------
local p = {
    id = 256,
    x = GS.HW - 4,
    y = 40,
    W = 8,
    H = 8,
    vx = 0,
    vy = 0,
    vmax = 2,
    scale = 1,
    flip = 0
}

local obj = {}

local OBJ_TYPE = {
    TREE = 1,
    TRAIL = 2
}

local SCENES = {
    LOADING = 1,
    MAIN_MENU = 2,
    GAME = 3
}

local mapArray = {}
local rndMapGen = {
    cellsAvg = 0,
    totalAvgs = 0,
    W = 240,
    H = GS.H * 2
}

-- general helper functions ----------------------------------------------------
rnd = math.random
abs = math.abs

ins = table.insert
rmv = table.remove

-- specific helper functions ---------------------------------------------------
-- simple rectangle collision
function collide(a, b)
    -- get parameters from a and b
    local ax = a.x
    local ay = a.y
    local aw = 8
    local ah = 8
    local bx = b.x
    local by = b.y
    local bw = 8
    local bh = 8

    -- check collision
    if ax < bx + bw and ax + aw > bx and ay < by + bh and ah + ay > by then
        -- collision
        return true
    end
    -- no collision
    return false
end

function shakeScreen()
    poke(0x3FF9, math.random(-GS.shakeD, GS.shakeD))
    poke(0x3FF9 + 1, math.random(-GS.shakeD, GS.shakeD))
    GS.shake = GS.shake - 1
    if GS.shake == 0 then
        memset(0x3FF9, 0, 2)
    end
end

function getAverageValueOfSurroundingFields(x, y)
    local sum = 0
    local numbFields = 0
    local avg = 0

    if y > 1 then
        sum = sum + mapArray[y - 1][x]
        numbFields = numbFields + 1

        if x > 1 then
            sum = sum + mapArray[y - 1][x - 1]
            numbFields = numbFields + 1
        end

        if x < rndMapGen.W then
            sum = sum + mapArray[y - 1][x + 1]
            numbFields = numbFields + 1
        end
    end

    if y < rndMapGen.H then
        sum = sum + mapArray[y + 1][x]
        numbFields = numbFields + 1

        if x > 1 then
            sum = sum + mapArray[y + 1][x - 1]
            numbFields = numbFields + 1
        end

        if x < rndMapGen.W then
            sum = sum + mapArray[y + 1][x + 1]
            numbFields = numbFields + 1
        end
    end

    if x > 1 then
        sum = sum + mapArray[y][x - 1]
        numbFields = numbFields + 1
    end

    if x < rndMapGen.W then
        sum = sum + mapArray[y][x + 1]
        numbFields = numbFields + 1
    end

    avg = sum / numbFields

    rndMapGen.totalAvgs = rndMapGen.totalAvgs + avg

    return avg
end

-- Print text with border
function printf(t, x, y, c1, c2)
    local x = x or 0
    local y = y or 0
    local c1 = c1 or 12
    local c2 = c2 or 0

    print(t, x - 1, y, c2)
    print(t, x, y - 1, c2)
    print(t, x + 1, y, c2)
    print(t, x, y + 1, c2)
    print(t, x, y, c1)
end

-- enum for sweetie-16 color palette
local COLOR = {
    BLACK = 0,
    PURPLE = 1,
    RED = 2,
    ORANGE = 3,
    YELLOW = 4,
    LIGHT_GREEN = 5,
    GREEN = 6,
    DARK_GREEN = 7,
    DARK_BLUE = 8,
    BLUE = 9,
    LIGHT_BLUE = 10,
    CYAN = 11,
    WHITE = 12,
    LIGHT_GREY = 13,
    GREY = 14,
    DARK_GREY = 15
}

-- init ------------------------------------------------------------------------
function init()
    GS.cs = SCENES.GAME
    generateRandomMap()
end

-- Simple Random Map Generation
-- Generating 2D height maps the easy way
-- https://dxprog.com/files/randmaps.html
function generateRandomMap()
    for y = 1, rndMapGen.H do
        mapArray[y] = {}
        for x = 1, rndMapGen.W do
            mapArray[y][x] = rnd(1, 255)
        end
    end

    for y = 1, rndMapGen.H do
        for x = 1, rndMapGen.W do
            mapArray[y][x] = getAverageValueOfSurroundingFields(x, y)
        end
    end

    rndMapGen.cellsAvg = rndMapGen.totalAvgs / (rndMapGen.H * rndMapGen.W)

    for y = 1, rndMapGen.H do
        for x = 1, rndMapGen.W do
            if mapArray[y][x] < rndMapGen.cellsAvg + 50 then
                mapArray[y][x] = 12
            elseif mapArray[y][x] >= rndMapGen.cellsAvg + 50 and mapArray[y][x] < rndMapGen.cellsAvg + 60 then
                mapArray[y][x] = 13
            else
                mapArray[y][x] = 14
            end
        end
    end
end

init()

-- main ------------------------------------------------------------------------
function TIC()
    if GS.cs == SCENES.MAIN_MENU then
        cls(8)
        mainMenuSceneUpdate()
        mainMenuSceneDraw()
    elseif GS.cs == SCENES.GAME then
        cls(12)
        gameSceneInput()
        gameSceneUpdate()
        gameSceneDraw()
    end
end

-- MAIN MENU SCENE -------------------------------------------------------------
-- update ----------------------------------------------------------------------
function mainMenuSceneUpdate()
    GS.t = GS.t + 1
end

-- draw ------------------------------------------------------------------------
function mainMenuSceneDraw()
end

-- GAME SCENE ------------------------------------------------------------------
-- input -----------------------------------------------------------------------
function gameSceneInput()
    if btn(2) then
        if abs(p.vx) < p.vmax then
            p.vx = p.vx - 0.1
        else
            p.vx = p.vmax
        end
        p.flip = 1
    end
    if btn(3) then
        if abs(p.vx) < p.vmax then
            p.vx = p.vx + 0.1
        else
            p.vx = p.vmax
        end
        p.flip = 0
    end
end

-- update ----------------------------------------------------------------------
function gameSceneUpdate()
    GS.t = GS.t + 1
    spawnNewTrails()
    spawnNewTrees()
    updateObjects()
    updatePlayer()
end

function spawnNewTrails()
    ins(obj, {type = OBJ_TYPE.TRAIL, x = p.x + 2, y = p.y + 8, c = 13, mov = true})
    ins(obj, {type = OBJ_TYPE.TRAIL, x = p.x + 5, y = p.y + 8, c = 13, mov = true})
end

function spawnNewTrees()
    if GS.t % GS.spawnTime == 0 then
        ins(
            obj,
            {
                type = OBJ_TYPE.TREE,
                id = rnd(0, 3),
                x = rnd(0, GS.W - 8),
                y = GS.H,
                mov = true
            }
        )
    end
end

function updateObjects()
    local lth = #obj
    for i = lth, 1, -1 do
        local o = obj[i]

        if o.mov then
            o.y = o.y - GS.scrollSpeed

            if o.y < -10 then
                rmv(obj, i)
            end
        end

        if o.type == OBJ_TYPE.TREE then
            if collide(o, p) then
                GS.gameOver = true
                p.scale = 1.2
            -- shakeScreen()
            end
        end
    end
end

function updatePlayer()
    -- update horizontal velocity with applied friction
    if abs(p.vx) > 0 then
        p.x = p.x + p.vx
        p.vx = p.vx * 0.9
    end

    -- check left and right screen border collision
    if p.x < 0 then
        p.x = 0
    elseif p.x > GS.W - p.W then
        p.x = GS.W - p.W
    end
end

-- draw ------------------------------------------------------------------------
function gameSceneDraw()
    drawMap()
    drawObjects()
    drawPlayer()
    drawUI()
end

function drawMap()
    for y = 1, GS.H do
        for x = 1, GS.W do
            pix(x, (y - GS.t) % GS.H, mapArray[y][x])
        end
    end
end

function drawPlayer()
    local animSpeed = 128
    local id = (time() // animSpeed) % 2
    spr(p.id + id, p.x, p.y, 0, p.scale, p.flip)
end

function drawObjects()
    local lth = #obj
    for i = 1, lth do
        if obj[i].type == OBJ_TYPE.TRAIL then
            pix(obj[i].x, obj[i].y, obj[i].c)
        elseif obj[i].type == OBJ_TYPE.TREE then
            spr(obj[i].id, obj[i].x, obj[i].y, 0)
        end
    end
end

function drawUI()
    printf("Score: " .. GS.t, 5, 5, COLOR.YELLOW, COLOR.DARK_GREY)
end
