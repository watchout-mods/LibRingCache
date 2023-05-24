describe("LibRingCache-2", function()
	describe("can create a table cache", function()
		it("without any arguments", function()
			local tbl = lib:Table();
			assert.Not.Nil(tbl);
		end)
		it("with one argument", function()
			assert.Not.Nil(lib:Table(1));
			assert.Not.Nil(lib:Table(10));
			assert.Not.Nil(lib:Table(32000));
		end)
		it("with two arguments", function()
			assert.Not.Nil(lib:Table(1, {}));
			assert.Not.Nil(lib:Table(1, nil));
			assert.Not.Nil(lib:Table(1, false));
		end)
	end)

	describe("cannot create a table cache with", function()
		it("zero size", function()
			assert.error(function() lib:Table(0) end);
		end)

		it("negative size", function()
			assert.error(function() lib:Table(-1) end);
		end)

		it("non-integer size", function()
			assert.error(function() lib:Table(1.5) end);
			assert.error_matches(function() lib:Table(1/0) end, "positive integer expected, got 'inf'");
		end)

		it("invalid feed", function()
			assert.error(function() lib:Table(1, true) end);
			assert.error(function() lib:Table(1, "foo") end);
			assert.error(function() lib:Table(1, 42) end);

			assert.error_matches(function() lib:Table(1, true) end, "table expected, got 'true'");
			assert.error_matches(function() lib:Table(1, "foo") end, "table expected, got 'foo'");
			assert.error_matches(function() lib:Table(1, 42) end, "table expected, got '42'");
		end)
	end)
end)