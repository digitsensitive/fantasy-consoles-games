-- title:  pong clone
-- author: digitsensitive
-- desc:   a short written pong clone
-- script: lua

-- global game settings
local GS = {W = 240, H = 136, S = 8, p1s = 0, p2s = 0, t = 0}
local p = {
    {x = 2 * GS.S, y = 3 * GS.S, s = 4, c = 12},
    {x = 27.5 * GS.S, y = 3 * GS.S, s = 4, c = 12}
}
local b

function init()
    if math.random() < 0.5 then
        resetBall(-1)
    else
        resetBall(1)
    end
end

function resetBall(dir)
    b = {x = GS.W / 2, y = GS.H / 2, vx = 1.8 * dir, vy = 1.8, c = 12}
end

function input()
    if btn(0) and p[1].y > 0 then
        p[1].y = p[1].y - 1
    elseif btn(1) and p[1].y + (p[1].s * GS.S) < GS.H then
        p[1].y = p[1].y + 1
    end
end

function update()
    b.x = b.x + b.vx
    b.y = b.y + b.vy

    if b.y > GS.H or b.y < 0 then
        b.vy = -b.vy
    end

    if b.y > p[2].y and p[2].y + (p[2].s * GS.S) < GS.H then
        p[2].y = p[2].y + 1.6
    elseif p[2].y > 0 then
        p[2].y = p[2].y - 1.6
    end

    if b.x > GS.W then
        GS.p1s = GS.p1s + 1
        resetBall(-1)
    elseif b.x < 0 then
        GS.p2s = GS.p2s + 1
        resetBall(1)
    end
end

function collide(p)
    local b = {x = b.x + 1, y = b.y + 1}
    return b.x > p.x and b.x < p.x + 8 and b.y > p.y and b.y < p.y + (p.s * GS.S)
end

function collisionsCheck()
    if collide(p[1]) then
        p[1].c = 11
        b.vx = -b.vx
    elseif collide(p[2]) then
        p[2].c = 11
        b.vx = -b.vx
    end
end

function draw()
    cls(14)
    map()
    circ(b.x, b.y, 2, b.c)
    for i, v in pairs(p) do
        for j = 0, v.s - 1 do
            if v.c == 11 then
                GS.t = GS.t + 1
                if GS.t > 20 then
                    v.c = 12
                    GS.t = 0
                end
            end
            rect(v.x, v.y + (j * GS.S), GS.S / 2, GS.S, v.c)
        end
    end
    print(GS.p1s, 6, 6, 0)
    print(GS.p1s, 5, 5, 12)
    print(GS.p2s, 230, 6, 0)
    print(GS.p2s, 229, 5, 12)
    print("v1.0.0", 200, 130, 5)
end

init()
function TIC()
    input()
    update()
    collisionsCheck()
    draw()
end
