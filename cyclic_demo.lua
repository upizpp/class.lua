local class = require("class")

vector2 = class {
	"vector2",
	x = 0,
	y = 0,
	__constructor__ = function(self, x, y)
		self.x = x
		self.y = y
	end,
	__metas__ = {
		__tostring = function(self)
			return "("..self.x..", "..self.y..")"
		end
	}
}

node = class {
	"node",
	position = class:make_placeholder("vector2", 0, 0),
	name = "undefined",
	__setters__ = {
		position = function(self, value)
			self.position = value
			print(value)
		end
	}
}

local obj = node:new()
obj.position.x = 1
obj.position.y = 2
