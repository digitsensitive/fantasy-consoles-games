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
    t = 0,
    bts = {h = 9, borderColor = 12},
    water = {mass = 1, maxCompress = 3}
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
    AIR = 0,
    SAND = 4,
    WATER = 10,
    CURSOR = 12
}

local particles = {}
local buttons = {}

-- general definitions and functions -------------------------------------------
rnd = math.random
min = math.min
max = math.max
ins = table.insert
rmv = table.remove
function clamp(v, l, h)
    return min(max(v, l), h)
end

-- grid functions --------------------------------------------------------------
function getParticle(x, y)
    return particles[y * GS.W + x]
end

function swapParticle(x1, y1, x2, y2)
    particles[y1 * GS.W + x1].prop, particles[y2 * GS.W + x2].prop =
        particles[y2 * GS.W + x2].prop,
        particles[y1 * GS.W + x1].prop
end

-- button ----------------------------------------------------------------------
local button = {}
function button:create(s, c, x, y)
    self.__index = self
    o = setmetatable({}, self)
    o.s = s
    o.x = x
    o.y = y
    o.w = print(o.s) + 3
    o.h = GS.bts.h
    o.c = c
    o.borderColor = GS.bts.borderColor
    return o
end

function button:update()
end

function button:draw()
    -- draw text
    print(self.s, self.x + 2, self.y + 2, self.c)

    -- draw border if activated
    -- this is the case, when the current particle type is the color value
    if GS.curPType == self.c then
        rectb(self.x, self.y, self.w, self.h, self.borderColor)
    end
end

function button:wasClicked(x, y)
    local clicked = false
    if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
        clicked = true
        GS.curPType = self.c
    end
    return clicked
end

-- particle --------------------------------------------------------------------
local particle = {}
function particle:new(x, y, type)
    self.__index = self
    o = setmetatable({}, self)
    o.x = x
    o.y = y
    o.prop = {}
    o.prop.type = type

    o.prop.mass = GS.water.mass

    return o
end

function particle:draw()
    pix(self.x, self.y, self.prop.type)
end

-- init ------------------------------------------------------------------------
function init()
    -- create empty air field
    for y = 0, GS.H do
        for x = 0, GS.W do
            particles[y * GS.W + x] = particle:new(x, y, P_TYPE.AIR)
        end
    end

    -- create buttons
    ins(buttons, button:create("Sand", P_TYPE.SAND, 20, 105))
    ins(buttons, button:create("Water", P_TYPE.WATER, 20, 115))
end

-- main ------------------------------------------------------------------------
init()
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

    if l and cursor.type == 0 then
        -- if left mouse clicked and cursor on field --> create new particles
        local x = cursor.x + rnd(-cursor.r, cursor.r)
        local y = cursor.y + rnd(-cursor.r, cursor.r)
        local p = getParticle(x, y)
        if p.prop.type == P_TYPE.AIR then
            p.prop.type = GS.curPType
        end
    elseif l and cursor.type == 1 then
        -- if left mouse clicked and cursor out the field --> check if button clicked
        for _, v in pairs(buttons) do
            v:wasClicked(cursor.x, cursor.y)
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
    for i = #particles, 0, -1 do
        local p = particles[i]

        -- only proceed if the particle is not air
        if p.prop.type ~= P_TYPE.AIR then
            if p.y < GS.H - 1 then
                local lowerParticle = getParticle(p.x, p.y + 1)
                local leftParticle = getParticle(p.x - 1, p.y)
                local rightParticle = getParticle(p.x + 1, p.y)
                local lowerLeftParticle = getParticle(p.x - 1, p.y + 1)
                local lowerRightParticle = getParticle(p.x + 1, p.y + 1)

                -- apply gravity
                if lowerParticle.prop.type == P_TYPE.AIR then
                    swapParticle(p.x, p.y, p.x, p.y + 1)
                end

                -- sand
                if lowerParticle.prop.type == P_TYPE.SAND then
                    if GS.t % 2 == 0 then
                        if lowerLeftParticle.prop.type == P_TYPE.AIR then
                            swapParticle(p.x, p.y, p.x - 1, p.y + 1)
                        end
                    else
                        if lowerRightParticle.prop.type == P_TYPE.AIR then
                            swapParticle(p.x, p.y, p.x + 1, p.y + 1)
                        end
                    end
                end

                -- water
                if p.prop.type == P_TYPE.WATER then
                    if GS.t % 2 == 0 then
                        if leftParticle.prop.type == P_TYPE.AIR then
                            swapParticle(p.x, p.y, p.x - 1, p.y)
                        end
                    else
                        if rightParticle.prop.type == P_TYPE.AIR then
                            swapParticle(p.x, p.y, p.x + 1, p.y)
                        end
                    end
                end
            end
        end
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
        if v.prop.type ~= P_TYPE.AIR then
            v:draw()
        end
    end
end

function drawUI()
    -- draw border of field
    rectb(0, 0, GS.W, GS.H, 15)

    for _, v in pairs(buttons) do
        v:draw()
    end

    print(#particles, 100, 115, 13)
end

function drawCursor()
    if cursor.type == 0 then
        circb(cursor.x, cursor.y, cursor.r, cursor.c)
    else
        pix(cursor.x, cursor.y, cursor.c)
    end
end
