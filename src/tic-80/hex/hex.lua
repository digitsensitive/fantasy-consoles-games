-- title:   Hex (Qix Remake)
-- author:  digitsensitive (digitsensitive.github.io)
-- desc:    Remake of the famous Qix Gameboy Game released in 1981
-- script:  lua


-- global game settings --------------------------------------------------------
local GS = {
    time = 0,
    fps = 20,
    score = 0,    -- total player score
    pf_is = 0,    -- percent pf current
    PF_GOAL = 75, -- percent pf goal
    PF = {        -- play field
        X = 39,   -- x offset
        Y = 25,   -- y offset
        W = 160,  -- width
        H = 106,  -- height
    },
    pixels = {}   -- pixels array
}

local dirs = {
    [0] = { x = 0, y = 0 },  --none
    [1] = { x = 0, y = -1 }, --up
    [2] = { x = 0, y = 1 },  --down
    [3] = { x = -1, y = 0 }, --left
    [4] = { x = 1, y = 0 }   --right
}

local KEY = {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    A = 4
}

local p = {
    x = 80,
    y = 106,
    lx = 80,  -- last position x
    ly = 106, -- last position y
    dir = dirs[0],
    ldir = dirs[0],
    c = 6,
    s = 1,
    isDrawing = false,
    hit = {
        gotHit = false,
        p = { x = 0, y = 0 },
        r = 0
    }
}

-- the flying enemy HEX
local hex = {
    points = {},
    lines = {},
    props = {
        c = 2,
        s = { cur = 15, min = 8, max = 15 },
        max_lines = 8,
        ang = { x = 0, y = 0, min = 1, max = 8 },
        f = 0
    }
}

-- the moving enemies ZIPS
local zipsSpawn = { x = 80, y = 1 }
local zips = {}

-- pixel types with the corresponding colors
local TYPE = {
    EMPTY = 12,
    BORDER = 0,
    FILL = 14
}

local tempDraw = {
    startPos = { x = 0, y = 0 },
    startDirectionDrawing = { x = 0, y = 0 },
    edgeCases = {}
}

-- scene manager ---------------------------------------------------------------
local function sceneManager()
    return {
        scenes = {},
        current_scene = nil,
        register = function(self, s, n) self.scenes[n] = s end,
        switch = function(self, n)
            self.current_scene = n
            self.scenes[n]:init()
        end,
        init = function(self) self.scenes[self.current_scene]:init() end,
        update = function(self) self.scenes[self.current_scene]:update() end,
        draw = function(self) self.scenes[self.current_scene]:draw() end
    }
end

local sMgr = sceneManager()

-- general definitions and functions -------------------------------------------
local flr = math.floor
local rnd = math.random
local sqr = math.sqrt
local abs = math.abs
local ins = table.insert
local rmv = table.remove

local function rndF(min, max)
    return min + (max - min) * rnd()
end

local function printhc(t, y, c, f, s)
    local f = f or false
    local s = s or 1
    local w = print(t, -8, -8) * s
    local x = (240 - w) / 2
    print(t, x, y, c, f, s)
end

local function copyTable(o)
    local type = type(o)
    local copy
    if type == 'table' then
        copy = {}
        for k, v in next, o, nil do
            copy[copyTable(k)] = copyTable(v)
        end
        setmetatable(copy, copyTable(getmetatable(o)))
    else -- number, string, boolean, etc
        copy = o
    end
    return copy
end

-- vec2 class ------------------------------------------------------------------
local Vec2d = {}
function Vec2d:new(x, y)
    self.__index = self
    o = setmetatable({}, self)
    o.x = x
    o.y = y
    return o
end

function Vec2d:length()
    return sqr(self.x * self.x + self.y * self.y)
end

function Vec2d:normalize()
    local length = self.length(self)
    if length == 0 then
        return { x = 0, y = 0 }
    else
        return {
            x = self.x / length,
            y = self.y / length
        }
    end
end

-- 2d collision detection ------------------------------------------------------
function linePoint(x1, y1, x2, y2, px, py)
    local d1 = dist(px, py, x1, y1);
    local d2 = dist(px, py, x2, y2);
    local lineLen = dist(x1, y1, x2, y2);
    local buffer = 0.1;

    if d1 + d2 >= lineLen - buffer and d1 + d2 <= lineLen + buffer then
        return true
    end

    return false
end

function dist(x1, y1, x2, y2)
    return sqr((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- menu scene ------------------------------------------------------------------
function Menu()
    local s = {}
    local cSel = 0

    function s:init()
        GS.time = 0
    end

    function s:update()
        GS.time = GS.time + 0.05
        if btnp(KEY.UP) then
            cSel = cSel - 1
            if cSel < 0 then cSel = 0 end
        end
        if btnp(KEY.DOWN) then
            cSel = cSel + 1
            if cSel > 1 then cSel = 1 end
        end

        if btnp(KEY.A) then
            if cSel == 0 then
                sMgr:switch("Game")
            elseif cSel == 1 then
                sMgr:switch("Readme")
            end
        end
    end

    function s:draw()
        cls(12)

        -- Calculate the Y position using sine wave
        local y_offset = math.sin(GS.time) * 2
        local title_y = 20 + y_offset
        printhc("Hex", title_y, 0, false, 3)
        printhc("Hex", title_y - 1, 6, false, 3)
        rect(80, 60 + cSel * 15, 5, 5, 6)
        printhc("Play Game", 60, 0, false, 1)
        printhc("Readme", 75, 0, false, 1)
        rect(104, 98, 9, 9, 6)
        printhc("Press A to Select", 100, 0, false, 1)
        printhc("(c) digitsensitive.github.io", 120, 14, false, 1)
    end

    return s
end

-- readme scene ----------------------------------------------------------------
function Readme()
    local s = {}

    function s:init()
        GS.time = 0
    end

    function s:update()
        GS.time = GS.time + 0.05

        if btnp(KEY.LEFT) then
            sMgr:switch("Menu")
        end
    end

    function s:draw()
        cls(12)

        -- Calculate the Y position using sine wave
        local y_offset = math.sin(GS.time) * 2
        local title_y = 20 + y_offset
        printhc("Readme", title_y, 0, false, 3)
        printhc("Readme", title_y - 1, 6, false, 3)
        rect(67, 58, 18, 9, 6)
        rect(102, 98, 9, 9, 6)
        printhc("Remake of Qix by Randy & Sandy Pfeiffer", 60, 0, false, 1)
        printhc("Published by Taito America in 1981", 70, 0, false, 1)
        printhc("Move with Arrow Keys, Draw with A&B", 80, 0, false, 1)
        printhc("Press < to go back", 100, 0, false, 1)
    end

    return s
end

-- game scene ------------------------------------------------------------------
function Game()
    local s = {}

    function s:init()
        GS.time = 0
        GS.score = 0
        GS.pf_is = 0

        s:resetPlayer()

        -- Init Playfield with Border
        GS.pixels = {}
        for y = 1, GS.PF.H do
            GS.pixels[y] = {}
            for x = 1, GS.PF.W do
                if y == 1 or y == GS.PF.H or x == 1 or x == GS.PF.W then
                    GS.pixels[y][x] = { x = x, y = y, type = TYPE.BORDER, isWalkable = true }
                else
                    GS.pixels[y][x] = { x = x, y = y, type = TYPE.EMPTY, isWalkable = false }
                end
            end
        end

        -- Init hex enemy
        -- 1. Generate two random points
        for i = 1, 2 do
            hex.points[i] = generateRandomPoint()
        end
        -- 2. Update Line Angle
        updateLineAngle()
        -- 3. Create the eight lines
        for i = 1, hex.props.max_lines do
            evaluateIfNewSegment()
            ins(hex.lines, createNewLine())
        end

        -- Init zips enemies
        ins(zips, {
            x = zipsSpawn.x,
            y = zipsSpawn.y,
            lx = zipsSpawn.x,
            ly = zipsSpawn.y
        })
        ins(zips, {
            x = zipsSpawn.x,
            y = zipsSpawn.y,
            lx = zipsSpawn.x,
            ly = zipsSpawn.y
        })
    end

    function s:update()
        GS.time = GS.time + 1

        if not p.hit.gotHit then
            -- save player last position and direction before doing anything else
            p.lx = p.x
            p.ly = p.y
            p.ldir = p.dir

            -- input -----------------------------------------------------------
            s:input()

            if p.isDrawing and p.ldir ~= p.dir then
                ins(tempDraw.edgeCases, { x = p.lx, y = p.ly })
            end

            -- update  ---------------------------------------------------------
            if GS.time % 2 == 0 then
                s:updatePlayer()
                s:updateHex()
                s:updateZips()
                s:detectCollisions()
            end
        else
            p.hit.r = p.hit.r + 2
            if p.hit.r == 200 then
                s:resetPlayer()
                p.x = tempDraw.startPos.x
                p.y = tempDraw.startPos.y
                p.lx = tempDraw.startPos.x
                p.ly = tempDraw.startPos.y

                -- delete unfinished areas
                for y = 1, #GS.pixels do
                    for x = 1, #GS.pixels[y] do
                        local pixel = GS.pixels[y][x]

                        if pixel.type == TYPE.BORDER and
                            not pixel.isWalkable then
                            pixel.type = TYPE.EMPTY
                        end
                    end
                end
            end
        end
    end

    function s:input()
        if btnp(4) and not p.isDrawing then
            p.isDrawing = true
        end

        if btn(3) then
            p.dir = dirs[4]
            -- left
        elseif btn(2) then
            p.dir = dirs[3]
            -- up
        elseif btn(0) then
            p.dir = dirs[1]
            -- down
        elseif btn(1) then
            p.dir = dirs[2]
        else
            p.dir = dirs[0]
        end
    end

    function s:updatePlayer()
        p.x = p.x + p.dir.x * p.s
        p.y = p.y + p.dir.y * p.s

        if p.x < 1 or p.x > GS.PF.W or p.y > GS.PF.H or p.y < 1 then
            p.x = p.lx
            p.y = p.ly
        end

        if p.isDrawing then
            if getPixel(GS.pixels, p.x, p.y).type == TYPE.EMPTY and not playerTouchBorders(p.x, p.y) then
                if tempDraw.startDirectionDrawing.x == 0 and tempDraw.startDirectionDrawing.y == 0 then
                    tempDraw.startPos = { x = p.lx, y = p.ly }
                    tempDraw.startDirectionDrawing = { x = p.dir.x, y = p.dir.y }
                end
                GS.pixels[p.y][p.x].type = TYPE.BORDER
                GS.pixels[p.y][p.x].isWalkable = false
            else
                if getPixel(GS.pixels, p.x, p.y).type == TYPE.BORDER and
                    getPixel(GS.pixels, p.x, p.y).isWalkable then
                    p.isDrawing = false
                    ins(tempDraw.edgeCases, { x = p.lx, y = p.ly })
                    evaluateDrawing()
                    updateScoreAndPlayField()
                else
                    p.x = p.lx
                    p.y = p.ly
                end
            end
        else
            -- walk on the border pixels
            if not getPixel(GS.pixels, p.x, p.y).isWalkable then
                p.x = p.lx
                p.y = p.ly
            end
        end
    end

    function s:updateHex()
        if GS.time % hex.props.s.cur == 0 then
            -- remove first line
            rmv(hex.lines, 1)
            evaluateIfNewSegment()
            ins(hex.lines, createNewLine())
        end
    end

    function s:updateZips()
        for i, v in ipairs(zips) do
            local surr = getSurrounding(GS.pixels, v.x, v.y)

            v.lx = v.x
            v.ly = v.y
            for i, field in ipairs(surr) do
                -- TODO: must find only the new fields that were been drawing
                if field.type == TYPE.BORDER and
                    field.isWalkable then
                    v.x = field.x
                    v.y = field.y
                end
            end
        end
    end

    function s:detectCollisions()
        -- check if player collides with hex
        if p.isDrawing then
            for i = 1, hex.props.max_lines do
                local l = hex.lines[i]
                for y = 1, #GS.pixels do
                    for x = 1, #GS.pixels[y] do
                        local pixel = GS.pixels[y][x]
                        if pixel.type == TYPE.BORDER and not pixel.isWalkable then
                            if linePoint(l.x0, l.y0, l.x1, l.y1, pixel.x, pixel.y) then
                                p.hit.gotHit = true
                                p.hit.p.x = pixel.x
                                p.hit.p.y = pixel.y
                            end
                        end
                    end
                end
            end
        end
    end

    function s:draw()
        cls(12)

        -- draw UI -------------------------------------------------------------
        print("HEX", 40, 10, 6, false, 2)
        print(GS.pf_is .. "%", 105, 10, 0, false, 2)
        local w = print(GS.score, -8, -8) * 2
        print(GS.score, 200 - w, 10, 0, false, 2)

        -- draw playfield ------------------------------------------------------
        -- The Gameboy has a screen size of
        -- 160 x 144 pixels.
        -- The Gamescreen-Size of Qiz is
        -- 160 x 136 pixels (TIC-80 has max.
        -- 136 pixels screen height.
        -- So Top-Left is @  x=39,y=0.
        -- Since I need some space for score
        -- and more at the top, the play field
        -- is 30 pixels less in height (106).
        for y = 1, #GS.pixels do
            for x = 1, #GS.pixels[y] do
                local pixel = GS.pixels[y][x]

                if pixel.type == TYPE.FILL then
                    pix(GS.PF.X + pixel.x, GS.PF.Y + pixel.y, pixel.type)
                elseif pixel.type == TYPE.BORDER then
                    pix(GS.PF.X + pixel.x, GS.PF.Y + pixel.y, pixel.type)
                end
            end
        end

        -- draw player
        rect(GS.PF.X + p.x - 1, GS.PF.Y + p.y - 1, 3, 3, 7)
        pix(GS.PF.X + p.x, GS.PF.Y + p.y, p.c)

        -- draw dead circle
        if p.hit.gotHit then
            circb(GS.PF.X + p.hit.p.x, GS.PF.Y + p.hit.p.y, p.hit.r, p.c)
        end

        -- hex
        for i = 1, hex.props.max_lines do
            local l = hex.lines[i]
            line(GS.PF.X + l.x0, GS.PF.Y + l.y0, GS.PF.X + l.x1, GS.PF.Y + l.y1, hex.props.c)
        end

        -- zips
        for i, v in ipairs(zips) do
            pix(GS.PF.X + v.x, GS.PF.Y + v.y, 10)
        end
    end

    function s:resetPlayer()
        p = {
            x = 80,
            y = 106,
            lx = 80,  -- last position x
            ly = 106, -- last position y
            dir = dirs[0],
            ldir = dirs[0],
            c = 6,
            s = 1,
            isDrawing = false,
            hit = {
                gotHit = false,
                p = { x = 0, y = 0 },
                r = 0
            }
        }
    end

    return s
end

-- specific definitions and functions ------------------------------------------
function playerTouchBorders(x, y)
    if p.dir.y ~= 0 then
        -- up or down
        if GS.pixels[y + p.dir.y][x - 1].type == TYPE.BORDER or
            GS.pixels[y + p.dir.y][x + 1].type == TYPE.BORDER
        then
            if GS.pixels[y + p.dir.y][x].isWalkable then
                GS.pixels[p.y][p.x].type = TYPE.BORDER
                GS.pixels[p.y][p.x].isWalkable = false
                p.y = p.y + p.dir.y
            end
            return true
        end
    elseif p.dir.x ~= 0 then
        -- left or right
        if GS.pixels[y - 1][x + p.dir.x].type == TYPE.BORDER or
            GS.pixels[y + 1][x + p.dir.x].type == TYPE.BORDER
        then
            if GS.pixels[y][x + p.dir.x].isWalkable then
                GS.pixels[p.y][p.x].type = TYPE.BORDER
                GS.pixels[p.y][p.x].isWalkable = false
                p.x = p.x + p.dir.x
            end
            return true
        end
    end

    return false
end

function getPixel(array, x, y)
    if y >= 1 and y <= #array and x >= 1 and x <= #array[y] then
        return array[y][x]
    else
        return nil
    end
end

function getSurrounding(array, x, y)
    local surr = {}
    ins(surr, getPixel(array, x + 1, y))
    ins(surr, getPixel(array, x - 1, y))
    ins(surr, getPixel(array, x, y + 1))
    ins(surr, getPixel(array, x, y - 1))
    return surr
end

function getFillPercentage(array)
    local count = 0
    local total_pixels = 0
    for y = 1, #array do
        for x = 1, #array[y] do
            local pixel = array[y][x]

            if pixel.type == TYPE.FILL then
                count = count + 1
            end

            total_pixels = total_pixels + 1
        end
    end

    return (count / total_pixels)
end

function evaluateDrawing()
    local temp_pixels_left = copyTable(GS.pixels)
    local temp_pixels_right = copyTable(GS.pixels)

    -- temp flood fill
    local dir = { x = tempDraw.startDirectionDrawing.x, y = tempDraw.startDirectionDrawing.y }

    if dir.x ~= 0 then
        -- move left or right
        floodFillArray(temp_pixels_left, tempDraw.startPos.x + dir.x, tempDraw.startPos.y - 1)  -- left
        floodFillArray(temp_pixels_right, tempDraw.startPos.x + dir.x, tempDraw.startPos.y + 1) -- right
    elseif dir.y ~= 0 then
        -- move up or down
        floodFillArray(temp_pixels_left, tempDraw.startPos.x - 1, tempDraw.startPos.y + dir.y)  -- left
        floodFillArray(temp_pixels_right, tempDraw.startPos.x + 1, tempDraw.startPos.y + dir.y) -- right
    end

    local percentage_fill_left = getFillPercentage(temp_pixels_left)
    local percentage_fill_right = getFillPercentage(temp_pixels_right)

    if percentage_fill_left < percentage_fill_right then
        if dir.x ~= 0 then
            floodFill(tempDraw.startPos.x + dir.x, tempDraw.startPos.y - 1)
        elseif dir.y ~= 0 then
            floodFill(tempDraw.startPos.x - 1, tempDraw.startPos.y + dir.y)
        end
    else
        if dir.x ~= 0 then
            floodFill(tempDraw.startPos.x + dir.x, tempDraw.startPos.y + 1)
        elseif dir.y ~= 0 then
            floodFill(tempDraw.startPos.x + 1, tempDraw.startPos.y + dir.y)
        end
    end

    tempDraw.startDirectionDrawing = { x = 0, y = 0 }
    tempDraw.startPos = { x = 0, y = 0 }

    for i, v in ipairs(tempDraw.edgeCases) do
        if not v.isWalkable then
            GS.pixels[v.y][v.x].isWalkable = true
        end
    end
    tempDraw.edgeCases = {}
end

function floodFillArray(array, x, y)
    local pixel = getPixel(array, x, y)

    if pixel.type == TYPE.BORDER then
        return
    end


    if pix(x, y) == 4 or pixel.type == TYPE.FILL then
        return
    end

    pixel.type = TYPE.FILL
    pixel.isWalkable = false

    floodFillArray(array, x + 1, y)
    floodFillArray(array, x - 1, y)
    floodFillArray(array, x, y + 1)
    floodFillArray(array, x, y - 1)
end

function floodFill(x, y)
    local pixel = getPixel(GS.pixels, x, y)

    if pixel.type == TYPE.BORDER then
        pixel.isWalkable = not pixel.isWalkable
        return
    end

    if pix(x, y) == 4 or pixel.type == TYPE.FILL then
        return
    end

    pixel.type = TYPE.FILL
    pixel.isWalkable = false

    floodFill(x + 1, y)
    floodFill(x - 1, y)
    floodFill(x, y + 1)
    floodFill(x, y - 1)
end

function updateScoreAndPlayField()
    local empty = 0
    local filled = 0
    for y = 1, #GS.pixels do
        for x = 1, #GS.pixels[y] do
            local pixel = GS.pixels[y][x]
            if pixel.type == TYPE.FILL then
                filled = filled + 1
            elseif pixel.type == TYPE.EMPTY then
                empty = empty + 1
            end
        end
    end

    GS.score = flr(filled * 0.2)
    GS.pf_is = flr(100 * (filled / (empty + filled)))
end

function updateLineAngle()
    hex.props.ang.x = rndF(hex.props.ang.min, hex.props.ang.max)
    hex.props.ang.y = rndF(hex.props.ang.min, hex.props.ang.max)
end

function generateRandomPoint()
    local newPoint = { x = 0, y = 0 }
    local newPointFound = false

    while not newPointFound do
        newPoint.x = rnd(1, GS.PF.W - 1)
        newPoint.y = rnd(1, GS.PF.H - 1)
        local p = getPixel(GS.pixels, newPoint.x, newPoint.y)

        if p.type == TYPE.EMPTY then
            newPointFound = true
        end
    end

    return newPoint
end

function evaluateIfNewSegment()
    -- check if already over the line between point 1 and point 2
    if hex.props.f > 1 then
        hex.props.f = 0 -- reset position to beginning of line
        hex.props.s.cur = rnd(hex.props.s.min, hex.props.s.max)
        updateLineAngle()
        rmv(hex.points, 1)                     -- remove first point
        ins(hex.points, generateRandomPoint()) -- generate a new point
    end
end

function createNewLine()
    local p1 = hex.points[1]
    local p2 = hex.points[2]
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local x0 = p1.x + dx * hex.props.f + hex.props.ang.x * hex.props.f
    local y0 = p1.y + dy * hex.props.f + hex.props.ang.y * hex.props.f
    local x1 = p1.x + dx * hex.props.f - hex.props.ang.x * hex.props.f
    local y1 = p1.y + dy * hex.props.f - hex.props.ang.y * hex.props.f

    -- update position on the vector
    hex.props.f = hex.props.f + (1 / 7) -- add 1/7

    return { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
end

-- init ------------------------------------------------------------------------
function init()
    sMgr:register(Menu(), "Menu")
    sMgr:register(Readme(), "Readme")
    sMgr:register(Game(), "Game")
    sMgr:switch("Menu")
end

-- main ------------------------------------------------------------------------
init()
function TIC()
    sMgr:update() -- update scene
    sMgr:draw()   -- draw scene
end
