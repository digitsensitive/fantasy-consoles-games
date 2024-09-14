-- title:  Breakout
-- author: digitsensitive (digitsensitive.github.io)
-- desc:   A short written breakout clone
-- script: lua

function init()
	-- variables
	bgColor = 0
	score = 0
	lives = 3

	-- our player
	player = {
		x = (240 / 2) - 12,
		y = 120,
		width = 24,
		height = 4,
		color = 3,
		speed = {
			x = 0,
			max = 4,
		},
	}

	-- ball
	ball = {
		x = player.x + (player.width / 2) - 1.5,
		y = player.y - 5,
		width = 3,
		height = 3,
		color = 14,
		deactive = true,
		speed = {
			x = 0,
			y = 0,
			max = 1.5,
		},
	}

	-- bricks
	bricks = {}
	brickCountWidth = 19
	brickCountHeight = 12

	-- create bricks
	for i = 0, brickCountHeight, 1 do
		for j = 0, brickCountWidth, 1 do
			local brick = {
				x = 10 + j * 11,
				y = 10 + i * 5,
				width = 10,
				height = 4,
				color = i + 1,
			}
			table.insert(bricks, brick)
		end
	end
end

init()

function TIC()
	cls(backgroundColor)
	input()
	if lives > 0 then
		update()
		collisions()
		draw()
	elseif lives == 0 then
		gameOver()
	end
end

function input()
	local sx = player.speed.x
	local smax = player.speed.max

	-- move to left
	if btn(2) then
		if sx > -smax then
			sx = sx - 2
		else
			sx = -smax
		end
	end

	-- move to right
	if btn(3) then
		if sx < smax then
			sx = sx + 2
		else
			sx = smax
		end
	end

	player.speed.x = sx
	player.speed.max = smax

	if ball.deactive then
		ball.x = player.x + (player.width / 2) - 1.5
		ball.y = player.y - 5

		if btn(5) then
			ball.speed.x = math.floor(math.random()) * 2 - 1
			ball.speed.y = -1.5
			ball.deactive = false
		end
	end
end

function update()
	local px = player.x
	local psx = player.speed.x
	local smax = player.speed.max

	-- update player position
	px = px + psx

	-- reduce player speed
	if psx ~= 0 then
		if psx > 0 then
			psx = psx - 1
		else
			psx = psx + 1
		end
	end

	player.x = px
	player.speed.x = psx
	player.speed.max = smax

	-- update ball position
	ball.x = ball.x + ball.speed.x
	ball.y = ball.y + ball.speed.y

	-- check max ball speed
	if ball.speed.x > ball.speed.max then
		ball.speed.x = ball.speed.max
	end
end

function collisions()
	-- player <-> wall collision
	playerWallCollision()

	-- ball <-> wall collision
	ballWallCollision()

	-- ball <-> ground collision
	ballGroundCollision()

	-- player <-> ball collision
	playerBallCollision()

	-- ball <-> brick collision
	ballBrickCollision()
end

function playerWallCollision()
	if player.x < 0 then
		player.x = 0
	elseif player.x + player.width > 240 then
		player.x = 240 - player.width
	end
end

function ballWallCollision()
	if ball.y < 0 then
		-- top
		ball.speed.y = -ball.speed.y
	elseif ball.x < 0 then
		-- left
		ball.speed.x = -ball.speed.x
	elseif ball.x > 240 - ball.width then
		-- right
		ball.speed.x = -ball.speed.x
	end
end

function ballGroundCollision()
	if ball.y > 136 - ball.width then
		-- reset ball
		ball.deactive = true
		-- loss a life
		if lives > 0 then
			lives = lives - 1
		elseif lives == 0 then
			-- game over
			gameOver()
		end
	end
end

function playerBallCollision()
	if collide(player, ball) then
		ball.speed.y = -ball.speed.y
		ball.speed.x = ball.speed.x + 0.3 * player.speed.x
	end
end

function collide(a, b)
	-- get parameters from a and b
	local ax = a.x
	local ay = a.y
	local aw = a.width
	local ah = a.height
	local bx = b.x
	local by = b.y
	local bw = b.width
	local bh = b.height

	-- check collision
	if ax < bx + bw and ax + aw > bx and ay < by + bh and ah + ay > by then
		-- collision
		return true
	end
	-- no collision
	return false
end

function ballBrickCollision()
	for i, brick in pairs(bricks) do
		-- get parameters
		local x = bricks[i].x
		local y = bricks[i].y
		local w = bricks[i].width
		local h = bricks[i].height

		-- check collision
		if collide(ball, bricks[i]) then
			-- collide left or right side
			if y < ball.y and ball.y < y + h and ball.x < x or x + w < ball.x then
				ball.speed.x = -ball.speed.x
			end
			-- collide top or bottom side
			if ball.y < y or ball.y > y and x < ball.x and ball.x < x + w then
				ball.speed.y = -ball.speed.y
			end
			table.remove(bricks, i)
			score = score + 1
		end
	end
end

function draw()
	drawGameObjects()
	drawGUI()
end

function drawGameObjects()
	-- draw player
	rect(player.x, player.y, player.width, player.height, player.color)

	-- draw ball
	rect(ball.x, ball.y, ball.width, ball.height, ball.color)

	-- draw bricks
	for i, brick in pairs(bricks) do
		rect(bricks[i].x, bricks[i].y, bricks[i].width, bricks[i].height, bricks[i].color)
	end
end

function drawGUI()
	print("Score ", 5, 1, 15)
	print(score, 40, 1, 15)
	print("Score ", 5, 0, 12)
	print(score, 40, 0, 12)
	print("Lives ", 190, 1, 15)
	print(lives, 225, 1, 15)
	print("Lives ", 190, 0, 12)
	print(lives, 225, 0, 12)
end

function gameOver()
	print("Game Over", (240 / 2) - 6 * 4.5, 136 / 2)
	spr(0, 240 / 2 - 4, 136 / 2 + 10)
	if btn(5) then
		init()
	end
end
