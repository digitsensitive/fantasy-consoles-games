--the cats list and all their variables
cats = {}
cats[1] = {
    x = hw,
    y = hh,
    idx = 272,
    vx = 0,
    vy = 0,
    mv = .08,
    mvup = -1.4,
    frm = 0,
    flp = 0,
    w = 7,
    h = 7
}

--the dust list for managing
--the particles
dust = {}

function draw()
    --draw the particles
    for i, d in pairs(dust) do
        if onscreen(d) then
            circ(d.x % 240, d.y % 136, d.r, d.c)
        end
    end

    --draw the player
    spr(p.idx + p.frm, p.x % 240, p.y % 136, 0, 1, p.flp)

    --draw the cats
    for i, c in pairs(cats) do
        if onscreen(c) then
            spr(c.idx + c.frm, c.x % 240, c.y % 136, 0, 1, c.flp)
        end
    end
end

----- UPDATES ------------------------

function update()
    update_player()
    update_bot()

    particles()
end

function update_player()
    --applies physics to the player
    py(p, frict, 1, grav)

    --applies collision to the player
    if collide(p, 7, 7) then
        new_dust(p.x + 4, p.y + 7, 2.5)
        sfx(0)
    end

    --moves the player
    move(p)
    --checks if the player is falling or going up
    checkanim(p)
    --animates the prayer
    p.anim(p)

    --reset all variables
    p.x, p.y = p.x % (240 * 8), p.y % (136 * 8)
    p.down = false
    p.anim = a_idle
end

function update_bot()
    --for all cats in the list of cats
    for i, c in pairs(cats) do
        --if there's a block in front, jump
        if fget(mget((c.x + 8) // 8, (c.y + 3) // 8), 0) or fget(mget((c.x - 1) // 8, (c.y + 3) // 8), 0) then
            c_jump(c)
        end

        --if the player is far, follow
        if p.x < c.x - 8 then
            c_left(c)
        end
        if p.x > c.x + 8 then
            c_right(c)
        end

        --the same stuff from the update_player
        py(c, frict, 1, grav)
        collide(c, 7, 7)
        move(c)

        checkanim(c)
        c.anim(c)

        c.anim = a_idle
    end
end

--updates the particles
function particles()
    for i, d in pairs(dust) do
        --applies physics and movement
        py(d, .95, .95, 0)
        move(d)

        --changes its color overtime
        if d.t < 5 then
            d.c = 15
        else
            d.c = 14
        end

        --when the timer ends, gets tiny and then deleted
        d.t = d.t - 1 + rnd()
        if d.t < 1 then
            d.r = d.r / 1.1
        end
        if d.r < 1 then
            del(dust, i)
        end
    end
end

----- NEEDED FUNCTIONS ---------------

--checks if something is on the same map area of the player
function onscreen(o)
    return p.x // 240 == o.x // 240 and p.y // 136 == o.y // 136
end

--checks if an object is in the air to apply the right animation
function checkanim(o)
    if o.vy > 0 then
        o.anim = a_fall
    elseif o.vy < 0 then
        o.anim = a_jump
    end
end

--plays a sfx if the object has the "player" tag
function psfx(o, i)
    if o.type == "player" then
        sfx(i)
    end
end

--creates 10 new dust particles and put the in the dust list
function new_dust(x_, y_, r_)
    for i = 0, 10 do
        table.insert(
            dust,
            {
                x = x_,
                y = y_,
                vx = cos(rnd(30)) / 2,
                vy = -sin(rad(rnd(180))) * (rnd() * 2) / 5,
                r = rnd() * r_,
                t = r_ * 5
            }
        )
    end
end

--stop an object of passing through blocks
--and returns true if it just hit the ground
function collide(o, w, h)
    local r = false
    local x, vx, y, vy = o.x, o.vx, o.y, o.vy

    if
        fget(mget((x + vx) // 8, (y) // 8), 0) or fget(mget((x + vx) // 8, (y + h) // 8), 0) or
            fget(mget((x + vx + w) // 8, (y) // 8), 0) or
            fget(mget((x + vx + w) // 8, (y + h) // 8), 0)
     then
        o.vx = 0
    end

    local vx = o.vx

    if
        fget(mget((x + vx) // 8, (y + vy) // 8), 0) or fget(mget((x + vx + w) // 8, (y + vy) // 8), 0) or
            fget(mget((x + vx) // 8, (y + vy + h) // 8), 0) or
            fget(mget((x + vx + w) // 8, (y + vy + h) // 8), 0)
     then
        if o.vy > .6 then
            r = true
        end
        o.vy = 0
    end

    --checks if the object is on the ground
    if fget(mget(x // 8, (y + h + 1) // 8), 0) or fget(mget((x + w) // 8, (y + h + 1) // 8), 0) then
        o.grnd = true
    else
        o.grnd = false
    end

    --checks if the object is below something
    if fget(mget(x // 8, (y - 1) // 8), 0) or fget(mget((x + w) // 8, (y - 1) // 8), 0) then
        o.ceil = false
    else
        o.ceil = true
    end

    return r
end





----- ANIMATIONS ---------------------

function a_idle(o)
    if t % 8 == 0 then
        o.frm = o.frm + 1
    end

    if o.frm > 3 then
        o.frm = 0
    end
end

function a_walk(o)
    if t % 14 == 0 then
        psfx(o, 2)
    end

    if t % 6 == 0 then
        o.frm = o.frm + 1
    end

    if o.frm < 4 or o.frm > 7 then
        o.frm = 4
    end
end

function a_down(o)
    o.frm = 10
end

function a_jump(o)
    o.frm = 8
end

function a_fall(o)
    o.frm = 9
end
