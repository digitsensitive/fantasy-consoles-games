-- title:  tetris
-- author: digitsensitive
-- desc:   a short written tetris clone
-- script: lua

g = {
    bgColor = 0,
    t = 0,
    w = 12,
    h = 18,
    size = 6,
    speed = 40,
    score = 0,
    nextType = 0,
    go = false
}

tetromino = {
    type = 0,
    r = 0,
    x = 0,
    y = 0
}

tetrominoes = {
	{
		0,0,1,0,
		0,0,1,0,
		0,0,1,0,
		0,0,1,0
	},
	{
		0,0,1,0,
		0,1,1,0,
		0,0,1,0,
		0,0,0,0
	},
	{
		0,0,0,0,
		0,1,1,0,
		0,1,1,0,
		0,0,0,0
	},
	{
		0,0,1,0,
		0,1,1,0,
		0,1,0,0,
		0,0,0,0
	},
	{
		0,1,0,0,
		0,1,1,0,
		0,0,1,0,
		0,0,0,0
	},
	{
		0,1,0,0,
		0,1,0,0,
		0,1,1,0,
		0,0,0,0
	},
	{
		0,1,1,0,
		0,1,0,0,
		0,1,0,0,
		0,0,0,0
	}
}

field = {}

function init()
    -- reset variables
    g.speed = 40
    g.score = 0

    -- tetromino
    tetromino.x = math.floor(g.w / 2)
    g.nextType = math.random(7)

    -- create empty field with walls
    -- index=y*width+x
    for x = 0, g.w do
        for y = 0, g.h do
            if x == 0 or x == g.w or y == g.h then
                field[y * g.w + x] = 8
            else
                field[y * g.w + x] = 0
            end
        end
    end

    -- get random tetromino
    tetromino.type = math.random(7)
end

init()

function TIC()
    if not g.go then
        g.t = g.t + 1
        input()
        if g.t % g.speed == 0 then
            update()
        end
        draw()
    else
        cls(g.bgColor)
        print("Game Over", 80, 50, 12)
        print("Score: " .. g.score, 80, 60, 12)
        print("Press X to restart", 80, 80, 12)
        if btnp(5) then
            g.go = false
            init()
        end
    end
end

function input()
    -- save tetromino state
    local lastX = tetromino.x
    local lastY = tetromino.y
    local lastRot = tetromino.r

    if btnp(1) then
        tetromino.y = tetromino.y + 1
    end
    if btnp(2) then
        tetromino.x = tetromino.x - 1
    end
    if btnp(3) then
        tetromino.x = tetromino.x + 1
    end
    if btnp(5) then
        tetromino.r = tetromino.r + 1
    end

    -- revert move, if not valid
    if not canMove(tetromino.type, tetromino.r, tetromino.x, tetromino.y) then
        tetromino.x = lastX
        tetromino.y = lastY
        tetromino.r = lastRot
    end
end

function update()
    -- move tetromino down
    if canMove(tetromino.type, tetromino.r, tetromino.x, tetromino.y + 1) then
        tetromino.y = tetromino.y + 1
    else
        -- fix in place and spawn new one
        for x = 0, 3 do
            for y = 0, 3 do
                -- get tetromino index
                -- we need to +1,because
                -- lua uses 1-based arrays
                local ti = rotate(x, y, tetromino.r) + 1

                -- get field index
                local fi = (tetromino.y + y) * g.w + (tetromino.x + x)

                -- current tetromino type
                local type = tetromino.type

                if tetrominoes[type][ti] == 1 then
                    field[fi] = type
                end
            end
        end

        checkForGameOver()
        checkForCompleteLine()

        -- spawn new one
        tetromino.type = g.nextType
        tetromino.x = math.floor(g.w / 2)
        tetromino.y = 0
        g.nextType = math.random(7)
    end
end

function draw()
    cls(g.bgColor)
    drawField()
    drawTetromino()
    drawGUI()
end

function drawField()
    for x = 0, g.w do
        for y = 0, g.h do
            local id = field[y * g.w + x]
            spr(id, x * g.size, y * g.size, 0)
        end
    end
end

function drawTetromino()
    for x = 0, 3 do
        for y = 0, 3 do
            local id = rotate(x, y, tetromino.r)
            local type = tetromino.type

            if tetrominoes[type][id + 1] == 1 then
                spr(tetromino.type, (tetromino.x + x) * g.size, (tetromino.y + y) * g.size, 0)
            end
        end
    end
end

function drawGUI()
    for x = 0, 10 do
        for y = 0, 18 do
            spr(8, x * g.size + 90, y * g.size)
        end
    end
    rect(97, 14, 53, 17, 13)
    rect(98, 15, 51, 15, 0)
    print("Score", 108, 20, 12)

    rect(97, 34, 53, 17, 13)
    rect(98, 35, 51, 15, 0)
    print(g.score, 108, 40, 12)

    rect(97, 54, 53, 47, 13)
    rect(98, 55, 51, 45, 0)

    for x = 0, 3 do
        for y = 0, 3 do
            local id = y * 4 + x

            if tetrominoes[g.nextType][id + 1] == 1 then
                spr(g.nextType, 110 + (x * g.size), 68 + (y * g.size), 0)
            end
        end
    end

    print("by digitsensitive - v0.1", 38, 121, 14)
    print("by digitsensitive - v0.1", 38, 120, 12)
end

function rotate(x, y, r)
    -- type rotation
    local type = r % 4

    -- select rotation function
    if type == 0 then
        return y * 4 + x
    elseif type == 1 then
        return 12 + y - (x * 4)
    elseif type == 2 then
        return 15 - (y * 4) - x
    elseif type == 3 then
        return 3 - y + (x * 4)
    else
        return 0
    end
end

function canMove(id, rot, posX, posY)
    for x = 0, 3 do
        for y = 0, 3 do
            -- get tetromino index
            -- we need to +1,because
            -- lua uses 1-based arrays
            local ti = rotate(x, y, rot) + 1

            -- get field index
            local fi = (posY + y) * g.w + (posX + x)

            if tetrominoes[id][ti] ~= 0 and field[fi] ~= 0 then
                -- we have a collision!
                return false
            end
        end
    end

    -- we have no collision!
    return true
end

function checkForGameOver()
    for x = 1, g.w - 1 do
        if field[g.w + x] ~= 0 then
            g.go = true
        end
    end
end

function checkForCompleteLine()
    local linesToErase = {}
    -- loop through lines
    -- begin from last line
    for y = g.h - 1, 0, -1 do
        for x = g.w - 1, 1, -1 do
            if field[y * g.w + x] == 0 then
                break
            end

            if x == 1 and field[y * g.w + x] ~= 0 then
                -- add line to array
                table.insert(linesToErase, y)

                -- erase line
                for x = g.w - 1, 1, -1 do
                    field[y * g.w + x] = 0
                end
            end
        end
    end

    -- loop backwards through
    -- the lines to erase
    for i = #linesToErase, 1, -1 do
        local l = linesToErase[i]
        for y = l - 1, 0, -1 do
            for x = g.w - 1, 1, -1 do
                field[(1 + y) * g.w + x] = field[y * g.w + x]
            end
        end
    end

    -- add score
    local score = g.score + 2 ^ #linesToErase - 1
    g.score = math.floor(score)
end
