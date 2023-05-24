lib = require("LibRingCache-2");

function CreateMockLibStub()
	local libs = {
		["LibRingCache-2"] = lib
	}

	return {
		GetLibrary = function(self, major)
			return libs[major];
		end
	}
end
