require("class")

person = class {
	"person",
	name = "undefined",
	age = 0,
	__constructor__ = function(self, name)
		self.name = name
	end
}

student = class {
	"student",
	"person",
	grades = 0,
	__constructor__ = function(self, name, grades)
		self:super().__constructor__(self, name)
		self.grades = grades
	end,
	__setters__ = {
		grades = function(self, value)
			self.grades = value
			print("Grades changed to "..value..".")
		end
	}
}

local zhangsan = student:new("张三", 120)
zhangsan.grades = 100