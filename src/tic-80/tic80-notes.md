# TIC-80

## Table of Contents

Table of contents generated with [markdown-toc](http://ecotrust-canada.github.io/markdown-toc).

- [Basic setup](#basic-setup)
- [Game loop](#game-loop)
- [General helper functions](#general-helper-functions)
- [Specific helper functions](#specific-helper-functions)
  - [Color palette](#color-palette)
  - [Physics](#physics)
    - [Simple collision](#simple-collision)
    - [Add velocity to object](#add-velocity-to-object)
    - [Apply friction to object](#apply-friction-to-object)
    - [Apply gravity to object](#apply-gravity-to-object)
  - [Sprite Animations](#sprite-animations)
  - [Print text](#print-text)
    - [With a border](#with-a-border)
    - [With a shadow at the top](#with-a-shadow-at-the-top)
    - [Horizontally centered](#horizontally-centered)
    - [Vertically centered](#vertically-centered)
    - [Centered](#centered)
- [Simple Scene Manager](#simple-scene-manager)
- [Finite state machine](#finite-state-machine)
- [Simple particle system](#simple-particle-system)

## Basic setup

```lua
function init()
end

init()

function TIC()
 -- here lies our game loop
end
```

## Game loop

```lua
function TIC()
	global.time=global.time+1
	input()
	if global.time%global.updateSpeed==0 then
		update()
	end
	draw()
end
```

## General helper functions

```lua
function cos(x) return math.cos(x) end
function sin(x) return math.sin(x) end
function tan(x) return math.tan(x) end

function rnd(x,y) return math.random(x,y) end
function rndArray(a) return a[math.random(#a)] end

function ins(t,e) return table.insert(t,e) end
function rmv(t,e) return table.remove(t,e) end

-- get maximum of two numbers
function max(n1,n2) return math.max(n1,n2) end
function clamp(v,l,h) return math.min(math.max(v,l),h) end
```

It might be even easier to use the following shortcuts:

```lua
cos = math.cos
sin = math.sin
tan = math.tan
rnd = math.random
sqrt = math.sqrt
rad = math.rad
min = math.min
max = math.max
abs = math.abs
```

## Specific helper functions

### Color palette

For the standard color palette `SWEETIE-16`.

```lua
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
```

### Physics

```lua
function
end
```

#### Simple collision

```lua
-- simple rectangle collision
function collide(a, b)
    -- get parameters from a and b
    local ax = a.x
    local ay = a.y
    local aw = 8
    local ah = 8
    local bx = b.x
    local by = b.y
    local bw = 8
    local bh = 8

    -- check collision
    if ax < bx + bw and ax + aw > bx and ay < by + bh and ah + ay > by then
        -- collision
        return true
    end
    -- no collision
    return false
end
```

#### Add velocity to object

```lua
function addVelocityToObject(o)
	o.x = o.x + o.vx
	o.y = o.y + o.vy
end
```

#### Apply friction to object

```lua
function applyFrictionToObject(o,fx,fy)
	o.vx = o.vx * fx
	o.vy = o.vy * fy
end

```

#### Apply gravity to object

```lua
function applyGravityToObject(o, g)
	o.vy = o.vy + g
	o.vy = min(max(o.vy, -3), 3)
end
```

### Sprite Animations

```lua
-- time returns the number of milliseconds elapsed since the application began
-- // will auto round the result
-- as higher the animSpeed, as slower the animation will be
local animSpeed = 128
local spriteID = (time()//animSpeed)%2
```

### Print text

#### With a border

c1 defines the inner color.
c2 defines the border color.

```lua
-- Print text with border
function printf(t,x,y,c1,c2)
	local x=x or 0
	local y=y or 0
	local c1=c1 or 12
	local c2=c2 or 0

	print(t,x-1,y,c2)
	print(t,x,y-1,c2)
	print(t,x+1,y,c2)
	print(t,x,y+1,c2)
	print(t,x,y,c1)
end
```

#### With a shadow at the top

c1 defines the shadow color at the top.
c2 defines the color of the text.

```lua
function printf(t,x,y,c1,c2)
	local x=x or 0
	local y=y or 0
	local c1=c1 or 12
	local c2=c2 or 0

	print(t,x,y,c1)
	print(t,x,y+1,c2)
end
```

#### Horizontally centered

f defines the flag indicating whether fixed width printing is required.
s defines the scale.

```lua
function printhc(t,y,c,f,s)
	local f=f or false
	local s=s or 1
	local w=print(t,-8,-8)*s
	local x=(240-w)/2
	print(t,x,y,c,f,s)
end
```

#### Vertically centered

f defines the flag indicating whether fixed width printing is required.
s defines the scale.

```lua
function printvc(t,x,c,f,s)
	local f=f or false
	local s=s or 1
	local w=print(t,-8,-8)*s
	local y=(136-6)/2
	print(t,x,y,c,f,s)
end
```

#### Centered

f defines the flag indicating whether fixed width printing is required.
s defines the scale.

```lua
function printc(t,c,f,s)
	local f=f or false
	local s=s or 1
	local w=print(t,-8,-8)*s
	local x=(240-w)/2
	local y=(136-6)/2
	print(t,x,y,c,f,s)
end
```

## Simple Scene Manager

```lua
-- global game table
G={
	runtime=0,
	SM={}
}

-- SCENE CLASS
local scene={}
function scene:new(o)
	o=o or {}
	self.__index=self
	setmetatable(o,self)
	o.timePassed=0
	return o
end

function scene:onExit() end
function scene:onEnter() end

-- SCENE MANAGER CLASS
local sceneManager={}
function sceneManager:create()
	self.__index=self
	o=setmetatable({},self)
	o.currentScene={}
	o.scenes={}
	return o
end

function sceneManager:addScene(s)
	table.insert(self.scenes,s)
end

function sceneManager:setCurrentScene(s)
	self.currentScene=s
end

function sceneManager:switchScene(s)
	if self.currentScene~=s then
		self.currentScene:onExit()
		self.currentScene=s
		self.currentScene:onEnter()
	end
end

-- main
local bootScene=scene:new({})
local mainMenuScene=scene:new({})

function init()
 	G.SM=sceneManager:create()
	G.SM:addScene(bootScene)
	G.SM:addScene(mainMenuScene)
	G.SM:setCurrentScene(bootScene)
end

init()

function TIC()
 if btnp(6) then
		if G.SM.currentScene==bootScene then
				G.SM:switchScene(mainMenuScene)
		else
			G.SM:switchScene(bootScene)
		end
	end
	G.SM.currentScene:update()
  G.SM.currentScene:draw()
	G.runtime=G.runtime+1
	printhc("Press A to change the scene",100,4)
	rectb(0,0,240,130,4)
end

-- Boot Scene
bootScene.update=function()
	bootScene.timePassed=
		bootScene.timePassed+1
end

bootScene.draw=function()
 cls()
	printhc("Boot Scene",40,5)
	printhc("Scene time: " .. bootScene.timePassed,50,13)
	printhc("Global time: " .. G.runtime,60,14)
end

-- Main Menu Scene
mainMenuScene.update=function()
	mainMenuScene.timePassed=
		mainMenuScene.timePassed+1
end

mainMenuScene.draw=function()
 cls()
	printhc("Main Menu Scene",40,10)
	printhc("Scene time: " .. mainMenuScene.timePassed,50,13)
	printhc("Global time: " .. G.runtime,60,14)
end

-- short general helper functions
function max(n1,n2) return math.max(n1,n2) end
function printhc(t,y,c)
	local w=print(t,-8,-8)
	local x=(240-w)/2
	print(t,x,y,c)
end
```

## Finite state machine

```lua
-- FINITE STATE MACHINE

-- Machine
local fsmBase={}

function fsmBase:new()
	self.__index=self
	o=setmetatable({},self)
	o.states={}
	o.curState=nil
	return o
end

function fsmBase:addState(s)
	self.states[s.name]=s
end

function fsmBase:setCurrentState(s)
	self.curState=s
end

function fsmBase:update()
	self.curState:onUpdate()
end

function fsmBase:switch(n)
	if self.curState.name~=n then
		self.curState:onExit()
		self.curState=self.states[n]
		self.curState:onEnter()
	end
end

-- Base State
local baseState={}

function baseState:new(n)
	self.__index=self
	o=setmetatable({},self)
	o.name=n
	return o
end

function baseState:onEnter() end
function baseState:onUpdate() end
function baseState:onExit() end
```

## Simple particle system

```lua
-- SIMPLE PARTICLE CLASS
local particles = {}

local particle = {}
function particle:new(x,y)
	self.__index=self
	o = setmetatable({}, self)
	o.x = x
	o.y = y
	o.dx = rnd(-8,8)
	o.dy = rnd(0,0)
	o.life = rnd(2,40)
	o.color = rnd(0,15)
	return o
end

function particle:update()
		self.x = self.x + self.dx
		self.y = self.y + self.dy
		self.life = self.life - 1
		if self.life < 0 then
		 local i = tblFind(particles,self)
			table.remove(particles,i)
		end
end

function particle:draw()
		pix(self.x,self.y,self.color)
end

-- main
function TIC()
  ins(particles,particle:new(118,58))
  updateParticles()
  drawParticles()
end

function updateParticles()
	for _,v in pairs(particles) do
		v:update()
	end
end

function drawParticles()
	for _,v in pairs(particles) do
		v:draw()
	end
end
```

# Unfinished Notes

## Berzerk

-- ROOM GENERATOR START
-- 256*256=65'536 rooms
-- 8 pillar, 4 directions
-- --> 4x4x4x4x4x4x4x4=65'536!
-- only 1024 maze layouts
-- at start you are played in a room
-- 251-123(vertical-horizontal)*
-- 17*30
-- 3*5
-- 13\*26
-- --> 4 and 3
-- --> 26 and 13

EID=S

-- Animations for each entity id
ANIM={
[EID.EN.ROBOT]={S.EN.ROBOT,273}
}
