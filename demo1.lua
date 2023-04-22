require("class")

vector2 = class {
	"vector2",
	x = 0,
	y = 0,
	__constructor__ = function(self, x, y)
		self.x = x or 0
		self.y = y or 0
	end,
	dot = function(self, with)
		return self.x * with.x + self.y * with.y
	end,
	__metas__ = {
		__add = function(a, b)
			return vector2:new(a.x + b.x, a.y + b.y)
		end,
		__tostring = function(self)
			return "("..self.x..", "..self.y..")"
		end
	}
}

local v1 = vector2:new(2, 3)
local v2 = vector2:new(4, 1)
print(v1 + v2)
print(v1:dot(v2))