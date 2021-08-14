-- title:  downhill
-- author: digitsensitive
-- desc:   ski downhill as far as possible
-- script: lua

-- global game settings --------------------------------------------------------
local GS = {
    W = 240,
    H = 136,
    HW = 240 / 2,
    HH = 136 / 2,
    t = 0,
    spawn_time = 10,
    SCROLL_SPEED = 1,
    gameOver = false,
    shake = 30,
    SHAKE_D = 4,
    cs = nil,
    GROUND_FRICTION = 0.9
}

-- game objects ----------------------------------------------------------------
local SPR = {
    PLR = {
        MOVE = 256,
        STAND = 258
    }
}

local plr = {
    cur_s = SPR.PLR.STAND,
    x = GS.HW - 4,
    y = 40,
    W = 8,
    H = 8,
    vx = 0,
    vy = 0,
    V_MAX = 2,
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

-- general helper functions ----------------------------------------------------
rnd = math.random
abs = math.abs

ins = table.insert
rmv = table.remove

-- specific helper functions ---------------------------------------------------

-- center text horizontally
function printhc(t, y, c, f, s)
    local f = f or false
    local s = s or 1
    local w = print(t, -8, -8) * s
    local x = (240 - w) / 2
    print(t, x, y, c, f, s)
end

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
    poke(0x3FF9, math.random(-GS.SHAKE_D, GS.SHAKE_D))
    poke(0x3FF9 + 1, math.random(-GS.SHAKE_D, GS.SHAKE_D))
    GS.shake = GS.shake - 1
    if GS.shake == 0 then
        memset(0x3FF9, 0, 2)
    end
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
        if not GS.gameOver then
            gameSceneInput()
            gameSceneUpdate()
            gameSceneDraw()
        else
            printhc("Game Over", 50, COLOR.BLACK, false, 2)
            printhc("Press X to restart", 70, COLOR.LIGHT_GREY)

            -- control screen shake
            if GS.shake > 0 then
                shakeScreen()
            else
                -- check if x is pressed
                if btn(5) then
                    GS.cs = SCENES.MAIN_MENU
                end
            end
        end
    end
end

-- MAIN MENU SCENE -------------------------------------------------------------
-- update ----------------------------------------------------------------------
function mainMenuSceneUpdate()
    GS.t = GS.t + 1
end

-- draw ------------------------------------------------------------------------
function mainMenuSceneDraw()
    printhc("Downhill", 50, COLOR.BLACK, false, 2)
    printhc("Press Z to Start Game", 70, COLOR.LIGHT_GREY)

    -- check if z is pressed
    if btn(4) then
        local lth = #obj
        for i = lth, 1, -1 do
            rmv(obj, i)
        end
        GS.gameOver = false
        GS.t = 0
        GS.shake = 30
        GS.spawn_time = 10
        GS.cs = SCENES.GAME
    end
end

-- GAME SCENE ------------------------------------------------------------------
-- input -----------------------------------------------------------------------
function gameSceneInput()
    if btn(2) then
        if abs(plr.vx) < plr.V_MAX then
            plr.vx = plr.vx - 0.1
        else
            plr.vx = plr.V_MAX
        end
        plr.flip = 1
    end
    if btn(3) then
        if abs(plr.vx) < plr.V_MAX then
            plr.vx = plr.vx + 0.1
        else
            plr.vx = plr.V_MAX
        end
        plr.flip = 0
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
    ins(obj, {type = OBJ_TYPE.TRAIL, x = plr.x + 2, y = plr.y + 8, c = COLOR.LIGHT_GREY, mov = true})
    ins(obj, {type = OBJ_TYPE.TRAIL, x = plr.x + 5, y = plr.y + 8, c = COLOR.LIGHT_GREY, mov = true})
end

function spawnNewTrees()
    if GS.t % 1000 == 0 then
        GS.spawn_time = GS.spawn_time - 1
    end

    if GS.t % GS.spawn_time == 0 then
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
            o.y = o.y - GS.SCROLL_SPEED

            if o.y < -10 then
                rmv(obj, i)
            end
        end

        if o.type == OBJ_TYPE.TREE then
            if collide(o, plr) then
                GS.gameOver = true
            end
        end
    end
end

function updatePlayer()
    -- update horizontal velocity with applied friction
    if abs(plr.vx) > 0 then
        plr.cur_s = SPR.PLR.MOVE
        plr.x = plr.x + plr.vx
        plr.vx = plr.vx * GS.GROUND_FRICTION

        if abs(plr.vx) < 0.05 then
            plr.vx = 0
        end
    else
        plr.cur_s = SPR.PLR.STAND
    end

    -- check left and right screen border collision
    if plr.x < 0 then
        plr.x = 0
    elseif plr.x > GS.W - plr.W then
        plr.x = GS.W - plr.W
    end
end

-- draw ------------------------------------------------------------------------
function gameSceneDraw()
    drawObjects()
    drawPlayer()
    drawUI()
end

function drawPlayer()
    local animSpeed = 128
    local id = (time() // animSpeed) % 2
    spr(plr.cur_s + id, plr.x, plr.y, 0, plr.scale, plr.flip)
    spr(plr.cur_s + id + 16, plr.x, plr.y + 8, 0, plr.scale, plr.flip)
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
