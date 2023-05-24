describe("LibRingCache-2", function()
	it("does not expose internal functions", function()
		assert.is.Nil(LibRingCache);
		assert.is.Nil(liberr);
		assert.is.Nil(argerr);
		assert.is.Nil(kReorder);
		assert.is.Nil(isCollectableEntry);
	end)

	describe("table caches", function()
		it("cannot collect string values", function()
			local cache = lib:Table(1);
			cache[1] = "aasdsja;guhglisdyughflaskdufhlsakdufhsal;dkjfhsalidfuhsadlfiuashdf";
			cache[2] = "fvajh9pe8tuhaesrlzogf8iyxlot8gbrexdylgot8yu45ebg9l6x854y6xblgdf8yt";
			cache[3] = "sl.jkfhrdd9se0r65uthxlbiufkjhbg,xkufbvyg,xckfjtygcfb,kc8yutgvbx,kf";

			collectgarbage();

			assert.Not.Nil(cache[1]);
			assert.Not.Nil(cache[2]);
			assert.Not.Nil(cache[3]);
			assert.is.same(3, #cache);
		end)

		it("can collect table values", function()
			local cache = lib:Table(1);
			cache[1] = {};
			cache[2] = {};

			collectgarbage();

			assert.is.Nil(cache[1]);
			assert.is.same({}, cache[2]);
		end)

		it("can collect function values", function()
			local cache = lib:Table(1);
			cache[1] = function() end;
			cache[2] = function() end;

			collectgarbage();

			assert.is.Nil(cache[1]);
			assert.is.Function(cache[2]);
		end)
	end)

	describe("list caches", function()
		it("cannot collect string values", function()
			local cache = lib:List(1);
			cache[0] = "aasdsja;guhglisdyughflaskdufhlsakdufhsal;dkjfhsalidfuhsadlfiuashdf";
			cache[0] = "fvajh9pe8tuhaesrlzogf8iyxlot8gbrexdylgot8yu45ebg9l6x854y6xblgdf8yt";
			cache[0] = "sl.jkfhrdd9se0r65uthxlbiufkjhbg,xkufbvyg,xckfjtygcfb,kc8yutgvbx,kf";

			collectgarbage();

			assert.Not.Nil(cache[1]);
			assert.Not.Nil(cache[2]);
			assert.Not.Nil(cache[3]);
			assert.is.same(3, #cache);
		end)

		it("can collect table values", function()
			local cache = lib:List(1);
			cache[0] = {};
			cache[0] = {};

			assert.is.same(2, #cache);

			collectgarbage();
			lib:Reorder(cache);

			assert.is.same({}, cache[1]);
			assert.is.same(1, #cache);
		end)

		it("can collect function values", function()
			local cache = lib:List(1);
			cache[0] = function() end;
			cache[0] = function() end;

			assert.is.same(2, #cache);

			collectgarbage();
			lib:Reorder(cache);

			assert.is.Function(cache[1]);
			assert.is.same(1, #cache);
		end)
	end)
end)