-- title:  pong clone
-- author: digitsensitive
-- desc:   a short written pong clone
-- script: lua

-- global game settings
local GS = {W = 240, H = 136, S = 8, p1s = 0, p2s = 0, t = 0}

-- paddles
local p = {
    {x = 2 * GS.S, y = 3 * GS.S, s = 4, c = 12},
    {x = 27.5 * GS.S, y = 3 * GS.S, s = 4, c = 12}
}
-- ball
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
    if btn(0) then
        if p[1].y > 0 then
            p[1].y = p[1].y - 1
        end -- up
    elseif btn(1) then
        if p[1].y + (p[1].s * GS.S) < GS.H then
            p[1].y = p[1].y + 1
        end -- down
    end
end

function update()
    -- update ball
    b.x = b.x + b.vx
    b.y = b.y + b.vy

    if b.y + 3 > GS.H or b.y < 0 then
        b.vy = -b.vy
    end

    -- update enemy paddle
    if b.y > p[2].y then
        if p[2].y + (p[2].s * GS.S) < GS.H then
            p[2].y = p[2].y + 1.6
        end -- down
    else
        if p[2].y > 0 then
            p[2].y = p[2].y - 1.6
        end -- up
    end

    if b.x > GS.W then
        GS.p1s = GS.p1s + 1
        resetBall(-1)
    elseif b.x < 0 then
        GS.p2s = GS.p2s + 1
        resetBall(1)
    end
end

function collisionsCheck()
    local px = b.x + 1
    local py = b.y + 1

    if px > p[1].x and px < p[1].x + 8 and py > p[1].y and py < p[1].y + (p[1].s * GS.S) then
        p[1].c = 11
        b.vx = -b.vx
    elseif px > p[2].x and px < p[2].x + 8 and py > p[2].y and py < p[2].y + (p[2].s * GS.S) then
        p[2].c = 11
        b.vx = -b.vx
    end
end

function draw()
    cls(14)
    map()

    -- draw ball
    circ(b.x, b.y, 2, b.c)

    -- draw paddles
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

    -- draw score and game version
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
