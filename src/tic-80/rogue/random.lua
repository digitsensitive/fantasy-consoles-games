-- title: procedural content generation
-- author: digitsensitive (digit.sensitivee@gmail.com)
-- desc: a roguelike procedural dungeon generator
-- licence: MIT License
-- version: 0.1
-- script: lua

-- each dungeon has a size of 30 x 17 tiles
-- each tile is 8x8 pixels in size

-- PCG variables ---------------------------------------------------------------
local PCG = {}

--- 2d Point -------------------------------------------------------------------
local Point2D = {
	new = function(self, x, y)
		self.__index = self
		return setmetatable({ x = x, y = y }, self)
	end,
}

--- Room -----------------------------------------------------------------------
local rooms = {}
local Room = {
	new = function(self, x, y, width, height)
		self.__index = self
		return setmetatable({ x = x, y = y, width = width, height = height }, self)
	end,
}

-- general helper functions ----------------------------------------------------
local rnd = math.random
local abs = math.abs

local ins = table.insert
local rmv = table.remove

-- this function returns a Point2D with a random offset
local function get_random_offset(x_min, x_max, y_min, y_max)
	-- generate a random offset
	return Point2D:new(rnd(x_min, x_max), rnd(y_min, y_max))
end

--[[ this function generates a random room.
	 a room is defined by its position (upper-left corner), a width and a height
	 some variables are predefined like the grid size where the room will be
	 placed and the minimum room size ]]
local minimum_room_size = 4
local grid_area = { w = 25, h = 7 }

local function generate_room(upper_left_room_corner)
	-- generate random width between minimum room size and grid area width
	local width = rnd(minimum_room_size, grid_area.w)

	-- generate random height between minimum room size and grid area height
	local height = rnd(minimum_room_size, grid_area.h)

	-- get a random offset Point2D
	local offset = get_random_offset(0, grid_area.w - width, 0, grid_area.h - height)

	-- calculate the x and y position of the room
	local x_room = upper_left_room_corner.x + offset.x
	local y_room = upper_left_room_corner.y + offset.y

	return Room:new(x_room, y_room, width, height)
end

-- function to generate a 3x3 grid with rooms
local function generate_rooms()
	-- three rooms are labeled as "gone", meaning they are only one tile big
	local number_of_gone_rooms = 3
	local gone_rooms_created = 0
	local number_of_rooms = 9

	for y = 0, 2 do
		for x = 0, 2 do
			local is_gone_room = false

			if gone_rooms_created < 3 then
				-- randomly evaluate if the current room is labeled as "gone"
				local current_room = x + (y * 3)
				local left_rooms_to_create = number_of_rooms - current_room

				if rnd(1, 2) == 1 or left_rooms_to_create <= (number_of_gone_rooms - gone_rooms_created) then
					is_gone_room = true
					gone_rooms_created = gone_rooms_created + 1
				end
			end

			-- define the upper left room corner position
			-- adapt upper left room corner point depending on the size of the grid area
			local upper_left_room_corner = Point2D:new(x * grid_area.w, y * grid_area.h)

			if is_gone_room then
				-- get a random offset Point2D
				local offset = get_random_offset(0, 3, 0, 3)

				-- calculate the x and y position of the room
				local x_room = upper_left_room_corner.x + offset.x
				local y_room = upper_left_room_corner.y + offset.y

				-- in this case of a gone room the size is 1x1
				ins(rooms, Room:new(x_room, y_room, 1, 1))
			else
				-- generate a room randomly and add it to our rooms array
				ins(rooms, generate_room(upper_left_room_corner))
			end
		end
	end
end

local function draw_rooms()
	for i, room in ipairs(rooms) do
		for y = 1, room.height do
			for x = 1, room.width do
				mset(room.x + x, room.y + y, 16)
			end
		end
	end
end

local function generate_corridors()
	-- loop through rooms, starting from 0, 1, 2, ...
	-- room layout:
	-- 0, 1, 2
	-- 3, 4, 5
	-- 6, 7, 8
	-- each time decide with 50:50 chance if corridor is created
end

local function init()
	generate_rooms()
	draw_rooms()
	generate_corridors()
end

init()

function TIC()
	-- clear the screen black
	cls(0)

	-- draw the map
	map()
end
