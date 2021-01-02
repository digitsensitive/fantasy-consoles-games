-- title:  powder
-- author: digitsensitive
-- desc:   powder
-- script: lua

-- global game settings --------------------------------------------------------
local GS = {
    -- screen height is 136, but starts at 0
    H = 100,
    -- screen width is 240, but starts at 0
    W = 240,
    curPType = 4,
    t = 0,
    bts = {h = 9, bgColor = 0},
    water = {mass = 1, maxCompress = 3}
}

-- game objects ----------------------------------------------------------------
local cursor = {
    x = 0,
    y = 0,
    r = {c = 1, min = 1, max = 1},
    c = 12
}

local P_TYPE = {
    AIR = 0,
    POWDER = 4,
    WATER = 10,
    CURSOR = 12,
    STONE = 13,
    METAL = 14
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
    o.bgColor = GS.bts.bgColor
    return o
end

function button:draw()
    -- draw background if activated
    -- this is the case, when the current particle type is the color value
    if GS.curPType == self.c then
        rect(self.x, self.y, self.w, self.h, self.bgColor)
    end

    -- draw text
    print(self.s, self.x + 2, self.y + 2, self.c)
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
function particle:new(x, y, type, mov, sink)
    self.__index = self
    o = setmetatable({}, self)
    o.x = x
    o.y = y
    o.prop = {}
    o.prop.type = type
    o.prop.sinkable = sink
    o.prop.movable = mov
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
            particles[y * GS.W + x] = particle:new(x, y, P_TYPE.AIR, true, false)
        end
    end

    -- create buttons
    ins(buttons, button:create("Powder", P_TYPE.POWDER, 20, 105))
    ins(buttons, button:create("Water", P_TYPE.WATER, 20, 115))
    ins(buttons, button:create("Stone", P_TYPE.STONE, 20, 125))
    ins(buttons, button:create("Metal", P_TYPE.METAL, 60, 105))
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
    cursor.r.c = clamp(cursor.r.c + sy, cursor.r.min, cursor.r.max)

    if l then
        -- if left mouse clicked
        if isOnPlayfield(cursor.x, cursor.y, cursor.r.c) then
            -- create new particles
            local x = cursor.x + rnd(-cursor.r.c, cursor.r.c)
            local y = cursor.y + rnd(-cursor.r.c, cursor.r.c)
            local p = getParticle(x, y)
            if p.prop.type == P_TYPE.AIR then
                p.prop.type = GS.curPType

                -- set sinkable parameter
                if GS.curPType == P_TYPE.WATER then
                    p.prop.sinkable = true
                end

                -- set movable parameter
                if GS.curPType == P_TYPE.METAL then
                    p.prop.movable = false
                end
            end
        else
            -- evaluate if a button was clicked
            for _, v in pairs(buttons) do
                v:wasClicked(cursor.x, cursor.y)
            end
        end
    end
end

function isOnPlayfield(x, y)
    return x > 0 and x < GS.W-1 and y > 0 and y< GS.H-1
end

-- update ----------------------------------------------------------------------
function update()
    GS.t = GS.t + 1
    updateParticles()
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

                -- apply gravity for movable objects if lower particle air or sinkable
                if lowerParticle.prop.type == P_TYPE.AIR and p.prop.movable or lowerParticle.prop.sinkable then
                    swapParticle(p.x, p.y, p.x, p.y + 1)
                end

                -- powder
                if lowerParticle.prop.type == P_TYPE.POWDER then
                    if GS.t % 2 == 0 then
                        if
                            lowerLeftParticle.prop.type == P_TYPE.AIR and leftParticle.prop.type == P_TYPE.AIR or
                                lowerLeftParticle.prop.sinkable and leftParticle.prop.sinkable
                         then
                            swapParticle(p.x, p.y, p.x - 1, p.y + 1)
                        end
                    else
                        if
                            lowerRightParticle.prop.type == P_TYPE.AIR and rightParticle.prop.type == P_TYPE.AIR or
                                lowerRightParticle.prop.sinkable and rightParticle.prop.sinkable
                         then
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

-- draw ------------------------------------------------------------------------
function draw()
    cls(15)

    -- hide system mouse cursor
    poke(0x3FFB, 0)

    drawUI()
    drawParticles()
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
    rect(0,0,GS.W,GS.H,0)
    line(0,GS.H,GS.W,GS.H,14)
    --rectb(0, 0, GS.W, GS.H, 14)

    for _, v in pairs(buttons) do
        v:draw()
    end
end

function drawCursor()
    if isOnPlayfield(cursor.x, cursor.y, cursor.r.c) then
        -- draw circle when on field
        circb(cursor.x, cursor.y, cursor.r.c, cursor.c)
    else
        -- draw only a point if out of field
        pix(cursor.x, cursor.y, cursor.c)
    end
end
