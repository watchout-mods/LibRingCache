describe("Using a list cache", function()
	local match = require("luassert.match")
	local LibStub = CreateMockLibStub();

	describe("can create a list cache", function()
		it("without any arguments", function()
			local tbl = lib:List();
			assert.Not.Nil(tbl);
		end)
		it("with one argument", function()
			assert.Not.Nil(lib:List(1));
			assert.Not.Nil(lib:List(10));
			assert.Not.Nil(lib:List(32000));
		end)
		it("with two arguments", function()
			assert.Not.Nil(lib:List(1, {}));
			assert.Not.Nil(lib:List(1, nil));
			assert.Not.Nil(lib:List(1, false));
		end)
	end)

	describe("cannot create a list cache with", function()
		it("zero size", function()
			assert.error(function() lib:List(0) end);
		end)

		it("negative size", function()
			assert.error(function() lib:List(-1) end);
		end)

		it("non-integer size", function()
			assert.error(function() lib:List(1.5) end);
			assert.error_matches(function() lib:List(1/0) end, "positive integer expected, got 'inf'");
		end)

		it("invalid feed", function()
			assert.error(function() lib:List(1, true) end);
			assert.error(function() lib:List(1, "foo") end);
			assert.error(function() lib:List(1, 42) end);

			assert.error_matches(function() lib:List(1, true) end, "table expected, got 'true'");
			assert.error_matches(function() lib:List(1, "foo") end, "table expected, got 'foo'");
			assert.error_matches(function() lib:List(1, 42) end, "table expected, got '42'");
		end)
	end)

	it("the documentation examples work as expected", function()
		local print = function() end; -- noop, we don't need to see this in unit tests

		-- @usage Example begins here
		local cache = LibStub:GetLibrary("LibRingCache-2"):List();
		cache[0] = {"a"};
		cache[0] = {"b"};
		cache[0] = {"c"};
		for k,v in ipairs(cache) do print(k, v) end;
		-- @usage Example end

		assert.is.Nil(cache[0]);
		assert.same({"a"}, cache[1]);
		assert.same({"b"}, cache[2]);
		assert.same({"c"}, cache[3]);
		assert.is.Nil(cache[4]);
	end)

	describe("the user can add entries with values", function()
		local cache = lib:List();

		it("of any type", function()
			assert.Not.Nil(cache);
			cache[0] = nil;
			cache[0] = true;
			cache[0] = 1;
			cache[0] = "foo";
			cache[0] = {};
			cache[0] = function() end;
		end)
	end)

	describe("the user can add and retrieve entries with", function()
		it("garbage-collectable values", function()
			local cache = lib:List(1);
			local noop_function = function() end;
			cache[0] = "foo";
			cache[0] = {1};
			cache[0] = noop_function;
			assert.same("foo", cache[1]);
			assert.same({1}, cache[2]);
			assert.same(noop_function, cache[3]);
			noop_function = nil;

			cache[0] = {2};
			collectgarbage();

			-- force reordering - this normally should happen automatically eventually on insert
			-- after garbage collection.
			lib:Reorder(cache);

			assert.same("foo", cache[1]);
			assert.same({2}, cache[2]);
			assert.same(nil, cache[3]);
		end)
	end)
end)
