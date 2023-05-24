---
-- LibRingCache is a pure Lua implementation of a FIFO cache.
--
-- That means that it will keep the most recently added `N` items within the cache (value can be
-- freely defined via the size parameter to the constructor functions. The goal is to reduce the
-- performance impact of managing the cache by delegating the burden of cleaning up the data to the
-- garbage collector.
-- 
-- Old items are discarded in order of insertion, if size is N and the N+1th item was just inserted,
-- then the 1st item is available for collection by the GC, __if__ the item is not in use anywhere
-- else. This way any cached data can be safely used, but you should be aware of global variables
-- holding cached data and so preventing the GC from collecting them.
-- 
-- Also note that the cache will only work correctly if either the key or the value (or both) is a
-- table or other type that can be collected from weak tables by the Lua garbage collector.
-- 
-- At this time `Lua 5.1` can collect the following types can be collected:
-- 
-- * `table`
-- * `function`
-- * `thread`
-- * `userdata`
-- @module LibRingCache
local MAJOR, MINOR = "LibRingCache-2", 1;
local LibRingCache = (LibStub and LibStub:NewLibrary(MAJOR, MINOR)) or (not LibStub and {});
if not LibRingCache then return LibStub:GetLibrary(MAJOR) end -- Same/Better version already exists

local rawset, math_floor, math_huge = rawset, math.floor, math.huge;
local wipe = wipe or function(self)
	for k, v in pairs(self) do
		self[k] = nil;
	end
end

local liberr, argerr; do
	local ERR_PREFIX = MAJOR .. ": ";
	function liberr(message, ...)
		error(ERR_PREFIX .. message:format(...));
	end

	function argerr(f, argnum, expect, got)
		liberr("Bad argument #%s to %s (%s expected, got '%s')", argnum, f, expect, tostring(got));
	end
end

local collectableTypes = {
	["number"]   = false,
	["string"]   = false,
	["table"]    = true,
	["function"] = true,
	["thread"]   = true,	
	["userdata"] = true,	
}

---
-- Validate that a given key-value pair can be collected by the Lua garbage collector.
local function isCollectableEntry(key, value)
	return collectableTypes[type(key)] or collectableTypes[type(value)];
end

local kReorder;
local CLEAR, REMOVE, REORDER = {}, {}, {};

---
-- Create a new ring cache of size 'size' and returns a reference.
-- 
-- @param size  the desired size of the cache, actual size may vary depending on how much of the data
--  is being held by other variables
-- @param feed  feed an existing table to use in the cache. This table is _not_ copied but directly
--  used internally
-- @return `cache`, a table set up as a cache
-- @usage
-- local cache = LibStub:GetLibrary("LibRingCache-2"):Table();
-- cache["foo"] = {"bar"};
-- print(cache.foo);
function LibRingCache:Table(size, feed)
	local start, size, ring = 1, size or 100, {};
	local data = feed or {};

	if size < 1 or size >= math_huge or math_floor(size) ~= size then
		argerr("LibRingCache:Table(size, feed)", 1, "positive integer", size);
	end
	if feed and type(feed) ~= "table" then
		argerr("LibRingCache:Table(size, feed)", 2, "table", feed);
	end

	-- Load ring with initial data
	for k, v in pairs(data) do
		ring[start] = v;
		start = (start % size) + 1;
	end
	
	local meta = {
		__mode = "kv",
		__call = function(self, method, ...)
			if method == CLEAR then
				wipe(self);
				wipe(ring);
				start = 1;
			end
		end,
		__newindex = function(self, key, value)
			rawset(self, key, value);
			ring[start] = value;
			start = (start % size) + 1; -- stay in range 1..n to use array tables
		end
	};

	return setmetatable(data, meta);
end

---
-- Create a "list" cache.
--
-- The array is still 1-indexed, index 0 will never contain a value, Use array[0] = value to append
-- values to the end
-- @param size the target size of the cache, actual size may vary depending on how much of the data
--  is being held by other variables
-- @param feed  feed an existing table to use in the cache
-- @usage
-- local cache = LibStub:GetLibrary("LibRingCache-2"):List();
-- cache[0] = {"a"};
-- cache[0] = {"b"};
-- cache[0] = {"c"};
-- for k,v in ipairs(cache) do print(k, v) end;
function LibRingCache:List(size, feed)
	local next_index, start, size, ring = 1, 1, size or 100, {};
	local data = feed or {};

	if size < 1 or size >= math_huge or math_floor(size) ~= size then
		argerr("LibRingCache:List(size, feed)", 1, "positive integer", size);
	end
	if feed and type(feed) ~= "table" then
		argerr("LibRingCache:List(size, feed)", 2, "table", feed);
	end

	-- Load ring with initial data
	for k, v in ipairs(data) do
		ring[start] = v;
		start = (start % size) + 1;
	end
	
	local meta = {
		__mode = "kv",
		__call = function(self, method, ...)
			if method == CLEAR then
				wipe(self);
				wipe(ring);
				start = 1;
			elseif method == REORDER then
				start = kReorder(self);
			end
		end,
		__newindex = function(self, key, value)
			if key == 0 then
				rawset(self, next_index, value);
				next_index = next_index + 1;
			else
				rawset(self, key, value);
			end
			ring[start] = value;
			start = (start % size) + 1; -- stay in range 1..n to use array tables
		end
	};

	return setmetatable(data, meta);
end

---
-- Clears the given cache.
function LibRingCache:Clear(cache)
	cache(CLEAR);
end

---
-- Reorders a List cache, has no effect on Table caches.
-- 
-- @param cache the List cache to apply to
function LibRingCache:Reorder(cache)
	cache(REORDER);
end

---
-- Validate that a cache has no uncollectible data.
--
-- This function will cause an error if it encounters an entry in the cache that cannot be collected
-- by the Lua garbage collector. The operation is not free nor can it easily be made almost-free.
-- 
-- @param cache the cache to operate on
function LibRingCache:Check(cache)
	for k,v in pairs(table_name) do
		if not isCollectableEntry(k, v) then
			liberr("Uncollectable cache entry {%s, %s}", k, v)
		end
	end
end

---
-- Sorts table entries with numeric keys by their keys and makes the table gapless.
--
-- Keys will change, but entries will retain their relative position.
-- 
-- @return first unused (numeric) key
-- @local
function kReorder(tbl)
	-- get a list of keys
	local keys, numkeys = {}, 0;
	for k, v in pairs(tbl) do
		if type(k) == "number" then
			numkeys = numkeys + 1;
			keys[numkeys] = k;
		end
	end
	table.sort(keys);
	
	local j = 1;
	-- reorder the elements gapless
	for i = 1, #keys do
		local key = keys[i];
		local val = tbl[key];
		-- print(("move %s => %s"):format(key, j));
		tbl[key] = nil;
		tbl[j] = val
		j = j + 1;
	end
	
	-- returns the first unused index
	return j;
end

return LibRingCache;