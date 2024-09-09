-- title:  basic platformer
-- author: digitsensitive
-- desc:   a basic platformer
-- script: lua

-- global game settings --------------------------------------------------------
local SCENES = {
	MENU = 1,
	PLAY = 2,
	GAMEOVER = 3,
}

local GS = {
	cs = SCENES.MENU,
	gameOver = false,
	W = 240,
	H = 136,
	HW = 240 / 2,
	HH = 136 / 2,
	TW = 30,
	TH = 17,
	TS = 8,
	t = 0,
	FRICTION_X = 0.9,
	GRAVITY = 0.1,
}

-- game objects ----------------------------------------------------------------
local p = {
	x = GS.HW,
	y = GS.HH,
	id = 256,
	vx = 0,
	vy = 0,
	ax = 0.1,
	mv = 0.7,
	jumpSpeed = -2,
	curFrame = 0,
	flip = 0,
	w = 7,
	h = 7,
	anim = {},
	isOnGround = false,
	hasHitCeiling = false,
}

-- general helper functions ----------------------------------------------------
sqrt = math.sqrt
sin = math.sin
cos = math.cos
rnd = math.random
tan = math.tan
rad = math.rad
min = math.min
max = math.max
abs = math.abs
del = table.remove

function clamp(v, l, h)
	return min(max(v, l), h)
end

-- specific helper functions ---------------------------------------------------

-- center text horizontally
function printhc(t, y, c, f, s)
	local f = f or false
	local s = s or 1
	local w = print(t, -8, -8) * s
	local x = (240 - w) / 2
	print(t, x, y, c, f, s)
end

-- enum for sweetie-16 color palette
local COLOR = {
	BLACK = 0,
	PURPLE = 1,
	RED = 2,
	ORANGE = 3,
	YELLOW = 4,
	LIGHT_GREEN = 5,
	GREEN = 6,
	DARK_GREEN = 7,
	DARK_BLUE = 8,
	BLUE = 9,
	LIGHT_BLUE = 10,
	CYAN = 11,
	WHITE = 12,
	LIGHT_GREY = 13,
	GREY = 14,
	DARK_GREY = 15,
}

function applyFrictionToObject(o, fx, fy)
	o.vx = o.vx * fx
	o.vy = o.vy * fy
end

function applyGravityToObject(o, g)
	o.vy = o.vy + g
	o.vy = clamp(o.vy, -3, 3)
end

function addVelocityToObject(o)
	o.x = o.x + o.vx
	o.y = o.y + o.vy
end

-- TIC main --------------------------------------------------------------------
function TIC()
	if GS.cs == SCENES.MENU then
		cls(8)
		printhc("A day to jump ahead", 50, COLOR.CYAN, false, 2)
		printhc("Press Z to Start Game", 70, COLOR.LIGHT_GREY)

		-- check if z is pressed
		if btn(4) then
			GS.gameOver = false
			GS.cs = SCENES.PLAY
		end
	elseif GS.cs == SCENES.PLAY then
		cls(0)
		if not GS.gameOver then
			map((p.x // GS.W) * GS.TW, (p.y // GS.H) * GS.TH, GS.TW, GS.TH, 0, 0, 0)
			input()
			update()
			draw()
		else
			printhc("Game Over", 50, COLOR.BLACK, false, 2)
			printhc("Press X to restart", 70, COLOR.LIGHT_GREY)

			-- check if x is pressed
			if btn(5) then
				GS.cs = SCENES.MENU
			end
		end
	end
end

-- input -----------------------------------------------------------------------
function input()
	if btn(1) or btn(5) then
		crouch(p)
	end
	if btn(0) or btn(4) then
		jump(p)
	end
	if btn(2) then
		moveLeft(p)
	end
	if btn(3) then
		moveRight(p)
	end
end

-- controller ------------------------------------------------------------------
function jump(o)
	if o.isOnGround and o.hasHitCeiling then
		o.vy = o.jumpSpeed
	end
end

function crouch(o) end

function moveLeft(o)
	o.vx = o.vx - o.ax
	if abs(o.vx) > o.mv then
		o.vx = -o.mv
	end
	o.flip = 1
end

function moveRight(o)
	o.vx = o.vx + o.ax
	if o.vx > o.mv then
		o.vx = o.mv
	end
	o.flip = 0
end

-- update ----------------------------------------------------------------------
function update()
	updatePlayer()
	GS.t = GS.t + 1
end

-- TODO: Review if no better approach exists
function updatePlayer()
	applyFrictionToObject(p, GS.FRICTION_X, 1)
	applyGravityToObject(p, GS.GRAVITY)

	collide(p, 7, 7)
	addVelocityToObject(p)

	p.x, p.y = p.x % (GS.W * GS.TS), p.y % (GS.H * GS.TS)
	p.anim = a_idle
end

-- draw ------------------------------------------------------------------------
function draw()
	spr(p.id + p.curFrame, p.x % GS.W, p.y % GS.H, 0, 1, p.flip)
end

-- collision -------------------------------------------------------------------
-- TODO: Review if no better approach exists
function collide(o, w, h)
	local hasCollided = false
	local x, vx, y, vy = o.x, o.vx, o.y, o.vy

	if
		fget(mget((x + vx) // GS.TS, y // GS.TS), 0)
		or fget(mget((x + vx) // GS.TS, (y + h) // GS.TS), 0)
		or fget(mget((x + vx + w) // GS.TS, y // GS.TS), 0)
		or fget(mget((x + vx + w) // GS.TS, (y + h) // GS.TS), 0)
	then
		o.vx = 0
	end

	local vx = o.vx

	if
		fget(mget((x + vx) // GS.TS, (y + vy) // GS.TS), 0)
		or fget(mget((x + vx + w) // GS.TS, (y + vy) // GS.TS), 0)
		or fget(mget((x + vx) // GS.TS, (y + vy + h) // GS.TS), 0)
		or fget(mget((x + vx + w) // GS.TS, (y + vy + h) // GS.TS), 0)
	then
		if o.vy > 0.6 then
			hasCollided = true
		end
		o.vy = 0
	end

	if fget(mget(x // GS.TS, (y + h + 1) // GS.TS), 0) or fget(mget((x + w) // GS.TS, (y + h + 1) // GS.TS), 0) then
		o.isOnGround = true
	else
		o.isOnGround = false
	end

	if fget(mget(x // GS.TS, (y - 1) // GS.TS), 0) or fget(mget((x + w) // GS.TS, (y - 1) // GS.TS), 0) then
		o.hasHitCeiling = false
	else
		o.hasHitCeiling = true
	end

	return hasCollided
end
