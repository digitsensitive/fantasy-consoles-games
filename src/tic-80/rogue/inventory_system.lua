-- title:  inventory system
-- author: digitsensitive
-- desc:   MISSING
-- script: lua

local inventory = {}

-- general helper functions ----------------------------------------------------
ins = table.insert
rmv = table.remove

local function add_item(item)
	ins(inventory, item)
end

local function remove_item(item)
	for i, v in pairs(inventory) do
		if v == item then
			rmv(inventory, i)
		end
	end
end

function init()
	-- Example usage
	add_item("Sword")
	add_item("Shield")
	add_item("Potion")
end

init()

function TIC()
	cls(0)
	print(table.concat(inventory, " | "))
end
