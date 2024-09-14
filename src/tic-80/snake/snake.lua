-- title:  Anake clone
-- author: digitsensitive (digitsensitive.github.io)
-- desc:   A short written snake clone
-- script: lua

-- global game settings
local GS = {
	SIZE = 8, -- block size
	score = 0, -- score
	BGC = 14 -- background color
}

local dirs = {
	[0] = { x = 0, y = -1 }, --up
	[1] = { x = 0, y = 1 }, --down
	[2] = { x = -1, y = 0 }, --left
	[3] = { x = 1, y = 0 }, --right
}

local snake = {
	{ x = 11, y = 8 }, -- tail
	{ x = 12, y = 8 }, -- body
	{ x = 13, y = 8 }, -- head
}

local dir = dirs[3]

local food = {
	x = 0,
	y = 0,
	color = 5,
}

-- general definitions and functions -------------------------------------------
local rnd = math.random
local ins = table.insert
local rmv = table.remove

-- input -----------------------------------------------------------------------
function input()
	local lastDir = dir

	if btn(0) then
		dir = dirs[0]
	elseif btn(1) then
		dir = dirs[1]
	elseif btn(2) then
		dir = dirs[2]
	elseif btn(3) then
		dir = dirs[3]
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
		newFood()
	else
		rmv(snake, 1)
	end
end

-- draw ------------------------------------------------------------------------
function draw()
	cls(GS.BGC)
	drawFood()
	drawSnake()
	drawScore()
	print("v1.0.1", 200, 130, 5)
end

function drawFood()
	rect(food.x * GS.SIZE, food.y * GS.SIZE, GS.SIZE, GS.SIZE, food.color)
end

function drawSnake()
	for i, v in pairs(snake) do
		rect(v.x * GS.SIZE, v.y * GS.SIZE, GS.SIZE, GS.SIZE, 4)
	end
end

function drawScore()
	print("Score: " .. GS.score, 6, 6, 0)
	print("Score: " .. GS.score, 5, 5, 12)
end

function newFood()
	food.x = rnd(0, 29)
	food.y = rnd(0, 16)
	for i, v in pairs(snake) do
		if v.x == food.x and v.y == food.y then
			newFood()
		end
	end
end

-- init ------------------------------------------------------------------------
function init()
	t = 0
	newFood()
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
