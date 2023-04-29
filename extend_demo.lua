local class = require "class"

person = class {
	"person",
	name = "undefined",
	age = 0,
	interact = function(self)
		print("Hi! I am a "..self.age.."-year-old person called "..self.name..".")
	end
}

studuent = class {
	"studuent",
	"person",
	grade = 0,
	interact = function(self)
		self:super():interact()
	end
}

local obj = studuent:new()
obj.name = "zhangsan"
obj.age = 18
obj:interact()