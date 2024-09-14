-- title:  Snake clone
-- author: digitsensitive (digitsensitive.github.io)
-- desc:   A short written snake clone
-- script: lua

-- game settings and variables -------------------------------------------------
local GS = {
	SIZE = 8, -- block size
	score = 0, -- score
	BGC = 14 -- background color
}

local snake = {
	{ x = 11, y = 8 }, -- tail
	{ x = 12, y = 8 }, -- body
	{ x = 13, y = 8 } -- head
}

local dir = { x = 1, y = 0 } -- right

local food = {
	x = 0,
	y = 0,
	c = 5,
}

-- general definitions and functions -------------------------------------------
local rnd = math.random
local ins = table.insert
local rmv = table.remove

function newfood()
	food.x = rnd(0, 29)
	food.y = rnd(0, 16)
	for i, v in pairs(snake) do
		if v.x == food.x and v.y == food.y then
			newfood()
		end
	end
end

-- input -----------------------------------------------------------------------
function input()
	local lastDir = dir

	if btn(0) then
		dir = { x = 0, y = -1 } --up
	elseif btn(1) then
		dir = { x = 0, y = 1 } --down
	elseif btn(2) then
		dir = { x = -1, y = 0 } --left
	elseif btn(3) then
		dir = { x = 1, y = 0 } --right
	end

	if dir.x == -lastDir.x or dir.y == -lastDir.y then
		dir = lastDir
	end
end

-- update ----------------------------------------------------------------------
function update()
	updateSnake()
end

function updateSnake()
	local head = snake[#snake]

	for i, v in pairs(snake) do
		if i ~= #snake and v.x == head.x and v.y == head.y then
			trace("Game OVER!")
			trace("Score: " .. GS.score)
			exit()
		end
	end

	ins(snake, {
		x = (head.x + dir.x) % 30,
		y = (head.y + dir.y) % 17,
	})

	if head.x == food.x and head.y == food.y then
		GS.score = GS.score + 1
		newfood()
	else
		rmv(snake, 1)
	end
end

-- draw ------------------------------------------------------------------------
function draw()
	cls(GS.BGC)
	-- draw food
	rect(food.x * GS.SIZE, food.y * GS.SIZE, GS.SIZE, GS.SIZE, food.c)
	-- draw snake
	for i, v in pairs(snake) do
		rect(v.x * GS.SIZE, v.y * GS.SIZE, GS.SIZE, GS.SIZE, 4)
	end
	-- draw score
	print("Score: " .. GS.score, 6, 6, 0)
	print("Score: " .. GS.score, 5, 5, 12)
	-- draw version
	print("v1.0.2", 200, 130, 5)
end

-- init ------------------------------------------------------------------------
function init()
	t = 0
	newfood()
end

-- main ------------------------------------------------------------------------
init()
function TIC()
	input()
	t = t + 1
	if t % 10 == 0 then
		update()
	end
	draw()
end
