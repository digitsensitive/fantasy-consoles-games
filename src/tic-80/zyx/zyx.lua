-- title:   Zyx (Qix Remake)
-- author:  Eric (digitsensitive)
-- desc:    Remake of the famous Qix Gameboy Game released in 1981
-- site:    digitsensitive.github.io
-- license: MIT License
-- version: 0.1
-- script:  lua

-- global game settings --------------------------------------------------------
local GS = {
    time = 0,
    fps = 20,
    score = 1000, -- total player score
    pf_is = 40,   -- percent pf current
    PF_GOAL = 75, -- percent pf goal
    PF = {        -- play field
        X = 39,   -- x offset
        Y = 29,   -- y offset
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
    A = 6,
    S = 7
}

local p = {
    x = 80,
    y = 106,
    lx = 80,  -- last position x
    ly = 106, -- last position y
    dir = dirs[0],
    ldir = dirs[0],
    c = 4,
    s = 1,
    isDrawing = false,
}

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

-- specific definitions and functions ------------------------------------------
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
        printhc("Zyx", title_y, 6, false, 3)
        rect(80, 60 + cSel * 15, 5, 5, 6)
        printhc("Play Game", 60, 0, false, 1)
        printhc("Readme", 75, 0, false, 1)
        rect(104, 98, 9, 9, 6)
        printhc("Press A to Select", 100, 0, false, 1)
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
        printhc("Press < to go back", 100, 0, false, 1)
    end

    return s
end

-- game scene ------------------------------------------------------------------
function Game()
    local s = {}

    function s:init()
        -- Init Playfield with Border
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
    end

    function s:update()
        GS.time = GS.time + 1

        p.lx = p.x
        p.ly = p.y
        p.ldir = p.dir

        -- input ---------------------------------------------------------------
        if btn(4) and not p.isDrawing then
            p.isDrawing = true
        end

        -- right
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

        -- update --------------------------------------------------------------
        p.x = p.x + p.dir.x * p.s
        p.y = p.y + p.dir.y * p.s

        if p.x < 1 or p.x > GS.PF.W or p.y > GS.PF.H or p.y < 1 then
            p.x = p.lx
            p.y = p.ly
        end

        if p.isDrawing then
            if not onBlackPixel(p.x, p.y) then
                if tempDraw.startDirectionDrawing.x == 0 and tempDraw.startDirectionDrawing.y == 0 then
                    tempDraw.startPos = { x = p.lx, y = p.ly }
                    tempDraw.startDirectionDrawing = { x = p.dir.x, y = p.dir.y }
                end
                GS.pixels[p.y][p.x].type = TYPE.BORDER
                GS.pixels[p.y][p.x].isWalkable = false
            else
                if getPixel(GS.pixels, p.x, p.y).type == TYPE.BORDER and getPixel(GS.pixels, p.x, p.y).isWalkable then
                    p.isDrawing = false
                    table.insert(tempDraw.edgeCases, { x = p.lx, y = p.ly })
                    evaluateDrawing()
                else
                    p.x = p.lx
                    p.y = p.ly
                end
            end

            if p.ldir ~= p.dir then
                table.insert(tempDraw.edgeCases, { x = p.lx, y = p.ly })
            end
        else
            -- walk on the border pixels
            if not getPixel(GS.pixels, p.x, p.y).isWalkable then
                p.x = p.lx
                p.y = p.ly
            end
        end
    end

    function s:draw()
        cls(12)

        -- draw UI -------------------------------------------------------------
        print("ZYX", 40, 10, 0, false, 2)
        print(GS.pf_is .. "/" .. GS.PF_GOAL .. " %", 100, 15, 0, false, 1)
        print(GS.score, 160, 15, 0, false, 1)

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
        pix(GS.PF.X + p.x, GS.PF.Y + p.y, p.c)
    end

    return s
end

function onBlackPixel(x, y)
    if GS.pixels[y][x].type == TYPE.BORDER then
        return true
    end

    return false
end

function getPixel(array, x, y)
    return array[y][x]
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
