-- title:  powder
-- author: digitsensitive
-- desc:   powder
-- script: lua

-- global game settings --------------------------------------------------------
local GS = {
    -- screen height is 136, but starts at 0
    H = 100,
    -- screen width is 240, but starts at 0
    W = 239,
    curPType = 4,
    t = 0
}

-- game objects ----------------------------------------------------------------
local cursor = {
    type = 0,
    x = 0,
    y = 0,
    r = 1,
    c = 12,
    minR = 3,
    maxR = 20
}

local P_TYPE = {
    EMPTY = 0,
    SAND = 4,
    WATER = 10,
    CURSOR = 12
}

local particles = {}

-- general helper functions ----------------------------------------------------
rnd = math.random
min = math.min
max = math.max
ins = table.insert
function clamp(v, l, h)
    return min(max(v, l), h)
end

-- particle --------------------------------------------------------------------
local particle = {}
function particle:new(x, y, type)
    self.__index = self
    o = setmetatable({}, self)
    o.x = x
    o.y = y
    o.type = type
    return o
end

function particle:update()
    local lowerPix = pix(self.x, self.y + 1)
    local lowerLeftPix = pix(self.x - 1, self.y + 1)
    local lowerRightPix = pix(self.x + 1, self.y + 1)

    if lowerPix == P_TYPE.EMPTY and self.y < GS.H then
        self.y = self.y + 1
    else
        if lowerPix == P_TYPE.SAND then
            -- do not move
            if GS.t % 2 == 0 then
                if lowerLeftPix == P_TYPE.EMPTY then
                    self.x = self.x - 1
                    self.y = self.y + 1
                end
            else
                if lowerRightPix == P_TYPE.EMPTY then
                    self.x = self.x + 1
                    self.y = self.y + 1
                end
            end
        end
    end
end

function particle:draw()
    pix(self.x, self.y, self.type)
end

-- main ------------------------------------------------------------------------

function TIC()
    input()
    update()
    draw()
end

-- input -----------------------------------------------------------------------
function input()
    -- get mouse parameters (null = not used)
    local x, y, l, null, r, null, sy = mouse()

    -- update cursor position and radius
    cursor.x = x
    cursor.y = y
    cursor.r = clamp(cursor.r + sy, cursor.minR, cursor.maxR)

    -- if left mouse clicked, create new particles
    if l and cursor.type == 0 then
        local x = cursor.x + rnd(-cursor.r, cursor.r)
        local y = cursor.y + rnd(-cursor.r, cursor.r)
        if pix(x,y)== P_TYPE.EMPTY then
        table.insert(particles, particle:new(x, y, GS.curPType))
        end
    end
end

-- update ----------------------------------------------------------------------
function update()
    GS.t = GS.t + 1
    updateParticles()
    updateCursor()
end

function updateParticles()
    for _, v in pairs(particles) do
        v:update()
    end
end

function updateCursor()
    local r = cursor.r
    if cursor.x - r <= 0 or cursor.x + r >= GS.W or cursor.y - r <= 0 or cursor.y + r >= GS.H then
        cursor.type = 1
    else
        cursor.type = 0
    end
end

-- draw ------------------------------------------------------------------------
function draw()
    -- clear screen
    cls(0)

    -- hide system mouse cursor
    poke(0x3FFB, 0)

    drawParticles()
    drawUI()
    drawCursor()
end

function drawParticles()
    for _, v in pairs(particles) do
        v:draw()
    end
end

function drawUI()
    rectb(0, 0, GS.W, GS.H, 15)
    print("Sand", 20, 105, P_TYPE.SAND)
    print("Water", 20, 115, P_TYPE.WATER)
    print(#particles, 100,115,13)
end

function drawCursor()
    if cursor.type == 0 then
        circb(cursor.x, cursor.y, cursor.r, cursor.c)
    else
        pix(cursor.x, cursor.y, cursor.c)
    end
end
