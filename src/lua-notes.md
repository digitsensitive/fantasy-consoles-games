# Lua

## Comments

```lua
-- simple one liner
--[[ multiline
		 comment ]]
```

## Variables

In lua every variable is by default global, which is a historical decision. Nowadays this is considered bad practice (f.e. in moonscript everything is by default local).

In general you should always use `local`. Same goes for functions, which you can also declare as local.

```lua
local x = 4
y,z = 4,9
```

## Enumerations

```lua
local COLORS = {
  BLUE = 1,
  GREEN = 2,
  RED = 3
}

-- the above is equivalent to
local COLORS = {
  ["BLUE"] = 1,
  ["GREEN"] = 2,
  ["RED"] = 3
}

-- reading the integer back
local color = COLORS.RED -- the same as COLORS["RED"]
```

## Tables and Arrays

Lua is descended from Sol, a language designed for petroleum engineers with no formal training in computer programming. People not trained in computing think it is damned weird to start counting at zero. By adopting **1-based array** and string indexing, the Lua designers avoided confounding the expectations of their first clients and sponsors.

```lua
t = {}
t = { a = 1, b = 2 }
t = { ["hello"] = 200 }

-- arrays are also tables
array = { "a", "b", "c", "d"}
print(array[1])	-- "a" (one-indexed)
print(#array)		-- 4 (length)
```

Lua always creates new tables without metatables.

```lua
t = {}
print(getmetatable(t)) --> nil
```

We can use `setmetatable` to set or change the metatable of a table.

```lua
t = {}
meta = {}
setmetatable(t, meta)
print(getmetatable(t) == meta) --> true
```

A group of related tables can share a common metatable, which describes their common behavior; a table can be its own metatable, so that it describes its own individual behavior. Any configuration is valid.

### \_ _index and _ \_newindex

Reading the content of the table. Note that the action is only triggered if the corresponding key is not present in the table.

```lua
-- first we want to set the __index method
-- this method gets called with the corresponding table and the used key
local meta = {}
meta.__index = function(object, index)
	print(string.format(
		"the key '%s' is not present in object '%s'",
		index, object))
  return -1
end

-- create a testobject
local t = {}

-- set the metatable
setmetatable(t, meta)

-- read a non-existend key
-- table[key] gets translated into meta.__index(table, key)
print(t["foo"]) -- the key 'foo' is not present in object  'table: 0x600002e8d2c0'
```

Writing the content of the table. Note that the action is only triggered if the corresponding key is not present in the table.

```lua
-- first we want to set the __newindex method
-- this method gets called with the corresponding table and the used key
local meta = {}
meta.__newindex = function(object, index, value)
	print(string.format(
		"writing the value '%s' to the object '%s' at the key `%s`",
		value, object, index))
  return -1
end

-- create a testobject
local t = {}

-- set the metatable
setmetatable(t, meta)

-- write a key (this triggers the method)
-- table[key] = value gets translated into meta.__newindex(table, key, value)
t.foo = 42
```

## Loops

### The numerical for loop

Do not use `pairs()` or `ipairs()` in critical code! For the performance tests, see here:
https://springrts.com/wiki/Lua_Performance#TEST_9:_for-loops

Try to save the table-size somewhere and use `for i = 1, x do end`.

```lua
-- i is a local control variable
-- the loop starts by evaluating the three control expressions:
-- initial value, limit, and the step
-- if the step is absent, it defaults to 1
for i = 1,5 do
end

-- the step value can be negative
for i = 20,-20,-1 do
end

-- here the step value is also defined (= delta)
for i = start,finish,delta do
end

-- iterable list of {key, value}
for k,v in pairs(tab) do
end

-- iterable list of {index, value}
for i,v in ipairs(tab) do
end

repeat
until condition

while x do
	if condition then break end
end
```

## Conditionals

```lua
if condition then
	print("right")
elseif condition then
	print("could be")
else
	print("no")
end
```

## Mathematical Functions

### math.floor(x)

Returns the largest integral value less than or equal to x.

### math.random([m [, n]])

The function uses the `xoshiro256**` algorithm to produce pseudo-random 64-bit integers.

If no argument specified, then returns [0,1).
If called with one positive argument n, then returns [1,n]
If called with two arguments, then returns [m,n].

### math.randomseed ([x [, y]])

When called with at least one argument, the integer parameters `x` and `y`are joined into a 128-bit seed. Equal seeds produce equal sequences of numbers. The default for `y` is zero.

### Exponentiation operator

Use the built-in `^` operator rather than the `math.pow()` function.

### Modulo

```lua
-- use of a modulo
local i = a%2 -- if a=2 then i=0; if a=3 then i=1
```

## Strings

### toString(v)

v can be of any type and will be coverted into a string.

```lua
local number = 20
local string = tostring(number)
print(string) -- "20"
```

### Concatenation of strings

```lua
local name = "pablo"
name = name .. "the number two" -- the two dots are called the string concetenation operator
```

### string.format

Returns a formatted version of its variable number of arguments following the description given in its first argument. The format string follows the same rules as the ISO C function `sprintf` (http://www.cplusplus.com/reference/cstdio/printf). The only differences are that the conversion specifiers and modifiers \*, h, L, l, and n are not supported and that there is an extra specifier, q.

```lua
local name = "Eric"
local age = 34
string.format("My name is %s and I am %d old.", name, age)
```

## API: Tables

```lua
table.insert(t,21) -- append (--> t[#t+1]=21)
```

With this function you can find a value in a table and return the index

```lua
function tblFind(t,e)
	for i, v in pairs(t) do
		if v == e then
			return i
		end
	end
end
```

## Classes

This is a simple example of how to create a class in lua.

```lua
local enemies = {}
local enemy = {}
function enemy:new(o)
	o = o or {}
	self.__index = self
	setmetatable(o, self)
	return o
end

function enemy:update()
	-- update enemy
end

function enemy:draw()
	-- draw enemy
end
```

Alternatively, you can pass predefined variables to the `new` class as follows:

```lua
function enemy:new(x, y, health)
  self.__index = self
	o = setmetatable({}, self)
  o.x = x
  o.y = y
  o.health = health
  return o
end
```

To create a new instance of the enemy, simple call `enemy:new()` and add it to your enemies array as follows:

```lua
table.insert(enemies, enemy:new(20, 40, 10))
```

To update and draw the enemies simple loop over it. You can also use `ipairs`.

```lua
for k,v in pairs(enemies) do
	v:update()
  v:draw()
end
```
