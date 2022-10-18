-- title:  voxel space
-- author: digitsensitive
-- desc:   voxel raster graphics rendering engine demo
-- script: lua

-- References:
-- https://github.com/s-macke/VoxelSpace
-- https://en.wikipedia.org/wiki/Voxel_Space

-- global game settings --------------------------------------------------------
local GS = {
	-- screen width is 240, but starts at 0
	W = 239,
	-- screen height is 136, but starts at 0
	H = 135,
}

-- game objects ----------------------------------------------------------------
local colorMap = {}
local heightMap = {}
local camera = {
	p = {
		x = GS.W / 2,
		y = GS.H / 2,
	},
	phi = 0,
	height = 80,
	horizon = -30,
	scaleHeight = 40,
	distance = 40,
}

local rndMapGen = {
	cellsAvg = 0,
	totalAvgs = 0,
	W = 239,
	H = 135,
}

-- general helper functions ----------------------------------------------------
rnd = math.random
floor = math.floor
sin = math.sin
cos = math.cos

-- specific helper functions ---------------------------------------------------
function drawVerticalLine(x, ytop, ybottom, c)
	line(x, ytop, x, ybottom, c)
end

function get2DArrayPosition(x, y)
	return y * GS.W + x
end

function getAverageValueOfSurroundingFields(x, y)
	local sum = 0
	local numbFields = 0
	local avg = 0

	if y > 0 then
		sum = sum + heightMap[y - 1][x]
		numbFields = numbFields + 1

		if x > 0 then
			sum = sum + heightMap[y - 1][x - 1]
			numbFields = numbFields + 1
		end

		if x < rndMapGen.W then
			sum = sum + heightMap[y - 1][x + 1]
			numbFields = numbFields + 1
		end
	end

	if y < rndMapGen.H then
		sum = sum + heightMap[y + 1][x]
		numbFields = numbFields + 1

		if x > 0 then
			sum = sum + heightMap[y + 1][x - 1]
			numbFields = numbFields + 1
		end

		if x < rndMapGen.W then
			sum = sum + heightMap[y + 1][x + 1]
			numbFields = numbFields + 1
		end
	end

	if x > 0 then
		sum = sum + heightMap[y][x - 1]
		numbFields = numbFields + 1
	end

	if x < rndMapGen.W then
		sum = sum + heightMap[y][x + 1]
		numbFields = numbFields + 1
	end

	avg = sum / numbFields

	rndMapGen.totalAvgs = rndMapGen.totalAvgs + avg

	return floor(avg)
end

-- Simple Random Map Generation
-- Generating 2D height maps the easy way
-- https://dxprog.com/files/randmaps.html
function generateRandomMap()
	for y = 0, rndMapGen.H do
		heightMap[y] = {}
		colorMap[y] = {}
		for x = 0, rndMapGen.W do
			heightMap[y][x] = rnd(0, 10)
			colorMap[y][x] = 0
		end
	end

	for y = 0, rndMapGen.H do
		for x = 0, rndMapGen.W do
			heightMap[y][x] = getAverageValueOfSurroundingFields(x, y)
			colorMap[y][x] = heightMap[y][x]
		end
	end

	-- for y=1,rndMapGen.H do
	--     for x=1,rndMapGen.W do
	--         if heightMap[y][x] <= 30 then
	--             colorMap[y][x]=10
	--         elseif heightMap[y][x] > 30 and heightMap[y][x] <= 35 then
	--              colorMap[y][x]=6
	--         elseif heightMap[y][x] > 35 and heightMap[y][x] <= 55 then
	--             colorMap[y][x]=7
	--        elseif heightMap[y][x] > 55 and heightMap[y][x] <= 60 then
	--            colorMap[y][x]=12
	--         end
	--     end
	-- end
end

function floorNumber(v)
	return floor(v)
end

-- point -----------------------------------------------------------------------
local point = {}
function point:new(x, y)
	self.__index = self
	o = setmetatable({}, self)
	o.x = x
	o.y = y
	return o
end

-- init ------------------------------------------------------------------------
function init()
	generateRandomMap()
end

-- main ------------------------------------------------------------------------
init()
function TIC()
	update()
	draw()
end

-- update ----------------------------------------------------------------------
function update()
	if btn(2) then
		camera.phi = camera.phi + 0.01
	elseif btn(3) then
		camera.phi = camera.phi - 0.01
	end

	if btn(0) then
		camera.p.y = camera.p.y + 1
	elseif btn(1) then
		camera.p.y = camera.p.y - 1
	end
end

-- draw ------------------------------------------------------------------------
function draw()
	cls(0)

	-- Call the render function with the camera parameters:
	-- position, height, horizon line position,
	-- scaling factor for the height, the largest distance
	renderAlgorithm(
		point:new(camera.p.x, camera.p.y),
		camera.phi,
		camera.height,
		camera.horizon,
		camera.scaleHeight,
		camera.distance
	)
end

function renderAlgorithm(p, phi, height, horizon, scaleHeight, distance)
	-- precalculate viewing angle parameters
	local sinphi = sin(phi)
	local cosphi = cos(phi)

	-- draw from back to front (painter algorithm)
	for z = distance, 1, -1 do
		-- find horizontal line on map, corresponding to the same optical
		-- distance from the observer (field of view and perspective projection)
		-- as further away from observer, the smaller the x and y
		local leftPoint = point:new((-cosphi * z - sinphi * z) + p.x, (sinphi * z - cosphi * z) + p.y)
		-- as further away from observer, the higher the x and smaller the y
		local rightPoint = point:new((cosphi * z - sinphi * z) + p.x, (-sinphi * z - cosphi * z) + p.y)

		-- segment the line
		local dx = (rightPoint.x - leftPoint.x) / GS.W
		local dy = (rightPoint.y - leftPoint.y) / GS.W
		-- top: 1
		-- ... 0.5
		-- bottom:0

		-- Raster the line so that it matches the number of columns of the screen
		-- Retrieve the height and color from the 2D maps corresponding of the segment of the line.
		-- Perform the perspective projection for the height coordinate.
		-- Draw a vertical line with the corresponding color with the height retrieved from the perspective projection.
		for x = 0, GS.W, 1 do
			-- heightOnScreen = (135-55)/40+30=80/40+30=2+30=32
			local heightOnScreen = (
				(height - heightMap[floorNumber(leftPoint.y)][floorNumber(leftPoint.x)])
				/ z
				* scaleHeight
			) + horizon
			-- line(x,ytop,ybottom,c)
			drawVerticalLine(x, heightOnScreen, GS.H, colorMap[floorNumber(leftPoint.y)][floorNumber(leftPoint.x)])
			leftPoint.x = leftPoint.x + dx
			leftPoint.y = leftPoint.y + dy
		end
	end
end
