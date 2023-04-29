class = {}
class.ObjectPool = {}
class.datas = {}


require "LuaExtensions"


local function safe_setmetatable(table, meta)
	if table ~= nil and meta ~= nil then
		setmetatable(table, meta)
	end
end

function class:get_class(class_name)
	return self.data[self:get_full_path(class_name)]
end

function class:is_extends_from(child, parent)
	local child_path = self:get_full_path(child)
	return table.has(child_path:split("/"), parent)
end

function class:new(arguments)
	local result = arguments

	local class_name = arguments[1]
	local extends_from = arguments[2]

	local succeed, full_path = self:get_full_path(extends_from)
	if succeed then
		setmetatable(result, {
			__index = class.datas[full_path]
		})
		safe_setmetatable(result.__setters__, {
			__index = class.datas[full_path].__setters__
		})
		safe_setmetatable(result.__getters__, {
			__index = class.datas[full_path].__getters__
		})
	end

	result[1] = nil
	result[2] = nil
	result.class_name = class_name
	if result.__constructor__ == nil then
		result.__constructor__ = function() end
	end

	function result:new(...)
		return class:instance(class_name, ...)
	end

	self.datas[full_path:plus_file(class_name)] = result
	return result
end

function class:rawget(object, key)
	local result = rawget(object, key)
	if result == nil then
		return rawget(object, "__data")[key]
	end
	return result
end

function class:manipulate_variable(object, key)
	local value = self:rawget(object, key)
	if self:is_placeholder(value) then
		local member_object = self:instance(value.__class_name__, table.unpack(value.__arguments__))
		rawset(member_object, "__ref", {
			["object"] = object,
			["key"] = key
		})
		rawset(object, key, member_object)
	end
end

function class:spawn_rid(object)
	math.randomseed(os.time() + math.random(0, 1024))
	return "("..tostring(object)..")-(Identifier"..math.random(0x00000000, 0xffffffff)..")"
end

function class:instance(class_name, ...)
	local succeed, full_path = self:get_full_path(class_name)
	if not succeed then
		return nil
	end
	
	local data = self.datas[full_path]

	local result = {}

	result.__data = data
	result.__locked = false
	result.__lock = function() rawset(result, "__locked", true) end
	result.__unlock = function() rawset(result, "__locked", false) end

	result.class_name = class_name
	result.full_class_name = full_path
	result.rid = self:spawn_rid(result)
	self.ObjectPool[result.rid] = result

	local function super(self)
		local paths = self.full_class_name:split("/")
		table.remove(paths, #paths)
		if #paths == 0 then
			error("Try to call 'super', but the class has no parent class.")
		end
		local full_class_name = table.join(paths, "/")
		local data = class.datas[full_class_name]
		local parent = {}
		parent.full_class_name = full_class_name
		parent.super = super
		setmetatable(parent, {
			__index = function(table, key)
				if type(data[key]) == "function" then
					return data[key]
				elseif key == "super" then
					return super
				end
			end
		})
		return parent
	end
	result.super = super

	local data_storage = table.copy(data)
	data_storage.__data = data
	
	local metas = {
		__index = function(table, key)
			self:manipulate_variable(table, key)
			if rawget(table, "__locked") then
				return self:rawget(data_storage, key)
			end
			rawget(table, "__lock")()
			if table.__getters__ ~= nil then
				if table.__getters__[key] ~= nil then
					local value = table.__getters__[key](table)
					table.__unlock()
					return value
				elseif table.__getters__.__any_other__ ~= nil then
					return table.__getters__.__any_other__(table, key)
				end
			end
			table.__unlock()
			return self:rawget(data_storage, key)
		end,
		__newindex = function(table, key, value)
			self:manipulate_variable(table, key)
			data[key] = value
			if rawget(table, "__locked") then
				rawset(data_storage, key, value)
				return
			end
			rawget(table, "__lock")()
			if table.__ref and table.__ref.object.__setters__ then
				rawget(table.__ref.object, "__lock")()
				if table.__ref.object.__setters__.__any__ ~= nil then
					table.__ref.object.__setters__.__any__(table, table.__ref.key, table)
				end
				if table.__ref.object.__setters__[table.__ref.key] ~= nil then
					table.__ref.object.__setters__[table.__ref.key](table, table)
				else
					if table.__ref.object.__setters__.__any_other__ ~= nil then
						table.__ref.object.__setters__.__any_other__(table, table.__ref.key, table)
					end
				end
				table.__ref.object.__unlock()
			end
			if table.__setters__ ~= nil then
				if table.__setters__.__any__ ~= nil then
					table.__setters__.__any__(table, key, value)
				end
				if table.__setters__[key] ~= nil then
					table.__setters__[key](table, value)
					table.__unlock()
					return
				end
				if table.__setters__.__any_other__ ~= nil and data_storage[key] == nil then
					table.__setters__.__any_other__(table, key, value)
				end
			end
			table.__unlock()
			rawset(data_storage, key, value)
		end,
		__pairs = function (table)
			return pairs(data_storage)
		end
	}
	if data.__metas__ then
		metas = table.merge(metas, data.__metas__, false)
	end
	setmetatable(result, metas)
	
	result.__lock()
	result:__constructor__(...)
	result.__unlock()

	return result
end

function class:make_placeholder(class_name, ...)
	return {
		__is_placeholder__ = true,
		__class_name__ = class_name,
		__arguments__ = {...}
	}
end

function class:is_placeholder(value)
	return type(value) == "table" and value.__is_placeholder__ == true and value.__class_name__ and value.__arguments__
end

function class:get_full_path(class_name)
	if class_name == nil then
		return false, ""
	end
	for k, v in pairs(class.datas) do
		local paths = k:split("/")
		if paths[#paths] == class_name then
			return true, k
		end
	end
	return false, class_name
end

setmetatable(class, {
	__call = class.new
})
