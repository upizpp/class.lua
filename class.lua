local class = {}
class.datas = {}

require "LuaExtensions"

--- 新建一个类
---@param members table
---@return table
function class:new(members)
	local class_name = members[1]
	local extends_from = members[2]
	local full_class_name = class_name

	local result = members
	result[1] = nil
	result[2] = nil

	if extends_from ~= nil then
		extends_from = self:get_full_path(extends_from)
		assert(extends_from ~= "", "Cannot find the class. ("..extends_from..")")
		full_class_name = extends_from:plus_file(class_name)
		table.make_reference(self.datas[extends_from], result)
	end
	
	function result:new(...)
		return class:instance(class_name, ...)
	end

	self.datas[full_class_name] = result
	return result
end

function class:has_class(class_name)
	return class:get_full_path(class_name) ~= ""
end

---@param class_name string
---@return string
function class:get_full_path(class_name)
	for k, v in pairs(self.datas) do
		if table.has(k:split("/"), class_name) then
			return k
		end
	end
	return ""
end

---@param class_name string
function class:get_class(class_name)
	return self[self:get_full_path(class_name)]
end

function class:make_placeholder(class_name, ...)
	assert(self:has_class(class_name), "Cannot find the class. ("..class_name..")")
	return {
		__is_placeholder__ = true,
		__class_name__ = class_name,
		__args__ = {...}
	}
end

function class:is_placeholder(value)
	return (
		type(value) == "table" and
		type(value.__class_name__) == "string" and
		type(value.__args__) == "table" and
		value.__is_placeholder__ == true
	)
end

function class:handle_variable(object, data, key)
	if self:is_placeholder(data[key]) then
		local member_object = self:instance(data[key].__class_name__, table.unpack(data[key].__args__))
		rawget(member_object, "__datas")["__ref__"] = {
			["object"] = object,
			["key"] = key
		}
		rawset(data, key, member_object)
	end
end

function class:instance(class_name, ...)
	local full_path = self:get_full_path(class_name)
	assert(full_path ~= "", "Cannot find the class. ("..class_name..")")

	local data = self.datas[full_path]
	data.__metas__ = data.__metas__ or {}

	local result = {}
	result.__datas = {}
	result.__locked = false
	result.__lock = function() rawset(result, "__locked", true) end
	result.__unlock = function() rawset(result, "__locked", false) end
	result.full_class_path = full_path

	local function super(self)
		local paths = self.full_class_path:split("/")
		table.remove(paths, #paths)
		if #paths == 0 then
			error("Try to call 'super', but the class has no parent class.")
		end
		local full_class_path = table.join(paths, "/")
		local data = class.datas[full_class_path]
		local parent = {}
		parent.full_class_path = full_class_path
		parent.super = super
		setmetatable(parent, {
			__index = function(table, key)
				if type(data[key]) == "function" then
					return data[key]
				elseif key == "super" then
					return super
				else
					return result[key]
				end
			end
		})
		return parent
	end
	result.super = super

	data.__metas__.__index = function(object, key)
		if rawget(result, "__datas")[key] == nil then
			rawget(result, "__datas")[key] = data[key]
		end
		self:handle_variable(result, rawget(result, "__datas"), key)

		if rawget(result, "__locked") then
			return rawget(result, "__datas")[key]
		end

		local getters = data.__getters__
		if getters ~= nil then
			rawget(result, "__lock")()
			if getters.__any__ ~= nil then
				assert(type(getters.__any__) == "function", "The setter should be a function.")
				local res = getters.__any__(result, key)
				if res ~= nil then
					rawget(result, "__unlock")()
					return res
				end
			end
			if getters[key] ~= nil then
				assert(type(getters[key]) == "function", "The getter should be a function.")
				local res = getters[key](result)
				if res ~= nil then
					rawget(result, "__unlock")()
					return res
				end
			elseif getters.__any_other__ ~= nil then
				assert(type(getters.__any_other__) == "function", "The getter should be a function.")
				local res = getters.__any_other__(result, key)
				if res ~= nil then
					rawget(result, "__unlock")()
					return res
				end
			end
			rawget(result, "__unlock")()
		end

		return rawget(result, "__datas")[key]
	end

	data.__metas__.__newindex = function(object, key, value)
		self:handle_variable(result, object, key)

		if rawget(result, "__locked") then
			rawget(result, "__datas")[key] = value
			return
		end

		local setters = data.__setters__
		if setters ~= nil then
			rawget(result, "__lock")()
			if setters.__any__ ~= nil then
				assert(type(setters.__any__) == "function", "The setter should be a function.")
				setters.__any__(result, key, value)
			end
			if setters[key] ~= nil then
				assert(type(setters[key]) == "function", "The setter should be a function.")
				setters[key](result, value)
			elseif setters.__any_other__ ~= nil then
				assert(type(setters.__any_other__) == "function", "The setter should be a function.")
				setters.__any_other__(result, key, value)
			end
			rawget(result, "__unlock")()
		end

		rawget(result, "__datas")[key] = value

		local ref = rawget(result, "__datas").__ref__
		if ref ~= nil then
			ref.object[ref.key] = result
		end
	end

	safe_setmetatable(result, data.__metas__)
	safe_call(result.__constructor__, result, ...)

	return result
end

setmetatable(class, {
	__call = class.new
})

return class