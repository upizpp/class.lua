-- LuaExtensions.lua:
---分割字符串。
---@param delimiter string 割符，<strong>它既可以是字符串，也可以是正则表达式。</strong>
---@param allow_empty boolean? # 如果为true，结果中就会包含空字符串。
---@param maxsplit integer? # 就是最多分割的结果个数。
---@param remove boolean? # 如果为true，当超过maxsplit时会将多余的部分删除。
---@return table
function string:split(delimiter, allow_empty, maxsplit, remove)
	allow_empty = allow_empty or false
	maxsplit = maxsplit or -1
	if remove == nil then remove = true end
	local lto = 0
	local from, to = self:find(delimiter)
	local result = {}
	local idx = 0
	local function insert(s)
		if not allow_empty then
			if s ~= "" then
				table.insert(result, s)
			end
		else
			table.insert(result, s)
		end
	end
	while from ~= nil do
		if maxsplit ~= -1 then
			if not remove then
				if idx >= maxsplit - 1 then
					insert(self:sub(lto + 1))
					return result
				end
			elseif idx >= maxsplit then
				return result
			end
		end
		idx = idx + 1
		insert(self:sub(lto + 1, from - 1))
		lto = to
		from, to = self:find(delimiter, to + 1)
	end
	if maxsplit ~= -1 and remove and idx >= maxsplit then
		return result
	end
	insert(self:sub(lto + 1))
	return result
end

function string.byte_length(b)
	local d
	if b > 239 then
		d = 4
	elseif b > 223 then
		d = 3
	elseif b > 128 then
		d = 2
	else
		d = 1
	end
	return d
end

function string:to_byte_table()
	local result = {}
	local i = 1
	while true do
		local b = self:sub(i, i):byte()
		local d = string.byte_length(b)
		local s = self:sub(i, i + d - 1)
		table.insert(result, b)
		i = i + d
		if (i > self:len()) then
			break
		end
	end
	return result
end

---若此字符串以text开头，返回true。
---@param text string
---@return boolean
function string:begins_with(text)
	return self:sub(0, text:len()) == text
end

---若此字符串以text结尾，返回true。
---@param text string
---@return boolean
function string:ends_with(text)
	return self:sub(self:len() - text:len() + 1, self:len()) == text
end

---返回字符串是否为空。
---@return boolean
function string:empty()
	return self == ""
end

---向后添加文件path
---@param path string
---@return string
function string:plus_file(path)
	if self:ends_with("/") then
		return self .. path
	elseif self:empty() then
		return path
	else
		return self .. "/" .. path
	end
end

---如果字符串是一个有效的文件名或路径，返回不带句点的扩展名（.）。如果字符串不包含扩展名，则返回nil。
---@return string|nil
function string:get_extension()
	for i = self:len(), 1, -1 do
		if self:sub(i, i) == "." then
			return self:sub(i + 1)
		end
	end
	return nil
end

---字符串为有效文件路径时，返回基础目录名。
---@return string|stringlib
function string:get_base_dir()
	for i = self:len(), 1, -1 do
		if self:sub(i, i) == "/" then
			return self:sub(1, i - 1)
		end
	end
	return self
end

---字符串为有效文件路径时，返回完整的文件路径，不带扩展名。
---@return string|stringlib
function string:get_basename()
	for i = self:len(), 1, -1 do
		if self:sub(i, i) == "." then
			return self:sub(1, i - 1)
		end
	end
	return self
end

---字符串为有效文件路径时，返回文件名。 
---@return string|stringlib
function string:get_file()
	for i = self:len(), 1, -1 do
		if self:sub(i, i) == "/" then
			return self:sub(i + 1)
		end
	end
	return self
end

function safe_setmetatable(table, meta)
	if type(table) == "table" and type(meta) == "table" then
		setmetatable(table, meta)
	end	
end

function safe_call(f, ...)
	if type(f) == "function" then
		f(...)
	end
end

if not table.unpack then
	table.unpack = unpack
end

function table.make_reference(source, target)
	local meta = getmetatable(target) or {}
	meta.__index = source
	meta.__pairs = source
	safe_setmetatable(target, meta)
end

function table:join(delimiter)
	local result = ""
	for i = 1, #self do
		result = result .. self[i] .. delimiter
	end
	return result:sub(1, result:len() - delimiter:len())
end

---复制一个表。
---@return table
function table.copy(tab)
	if tab == nil then
		return {}
	end
	local result = {}
	for key, value in pairs(tab) do
		if type(value) == "table" then
			result[key] = table.copy(value)
		else
			result[key] = value
		end
	end
	return result
end

---@param what any
---@return boolean
function table:has(what)
	for key, value in pairs(self) do
		if value == what then
			return true
		end
	end
	return false
end

---@param what any
---@return any
function table:find(what)
	for key, value in pairs(self) do
		if value == what then
			return key
		end
	end
	return nil
end

---@param a table
---@param b table
---@param overwrite boolean?
---@return table
function table.merge(a, b, overwrite)
	overwrite = overwrite or false
	a = a or {}
	b = b or {}
	local result = table.copy(a)
	local offset = 0
	for key, value in pairs(b) do
		if type(key) == "number" then
			while not overwrite and a[key + offset] ~= nil do
				offset = offset + 1
			end
			result[key + offset] = value
		else
			if overwrite then
				if type(value) == "table" then
					result[key] = table.merge(result[key], value, overwrite) 
				else
					result[key] = value
				end
			elseif a[key] == nil then
				if type(value) == "table" then
				   result[key] = table.merge(result[key], value, overwrite) 
				else
					result[key] = value
				end
			end
		end
	end
	return result
end

---如果表为空，返回true。
---@param allow_table boolean 如果为true，则表内包含空表的表也为空。
function table:empty(allow_table)
	if #self ~= 0 then
		return false
	end
	for key, value in pairs(self) do
		if not allow_table then
			return false
		end
		if type(value) == "table" then
			if not table.empty(value, allow_table) then
				return false
			end
		else
			return false
		end
	end
	return true
end

---新建一个枚举
---@param table table
---@param step number?
---@return table
function table.enum(table, step, mode)
	step = step or 1
	mode = mode or 0
	local result = {}
	local current
	if mode == 0 then
		current = 0
	elseif mode == 1 then
		current = 1
	end
	for i = 1, #table do
		if type(table[i]) == "number" then
			current = table[i]
		end
		result[table[i]] = current
		if mode == 0 then
			current = current + step
		elseif mode == 1 then
			current = current * step
		end
	end
	return result
end

