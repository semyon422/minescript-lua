local msrt = require("msrt")
local class = require("class")

local java = setmetatable({}, {__index = function(t, k)
	local v = rawget(t, k)
	if v then
		return v
	end
	t[k] = function(...)
		return msrt.call_async("S", "java_" .. k, ...)
	end
	return t[k]
end})
-- function java.call_method(...) return msrt.call_async("R", "java_call_method", ...) end

local java_reflect = {}

local JavaObject = class()

local oc_mt = {__index = function(t, k)
	if k == "class" then
		local v = rawget(t, k)
		if v then
			return v
		end
		t[k] = java.class(t[1])
		return t[k]
	end
	local v = rawget(t, k)
	if v then
		return v
	end
	t[k] = java.member(t.class, k)
	return t[k]
end}

local _Object = setmetatable({"java.lang.Object"}, oc_mt)
local _Class = setmetatable({"java.lang.Class"}, oc_mt)

local Float = class()
function Float:new(value)
	self.value = value
end
Float.value = 0

local function to_java_type(value)
	local t = type(value)
	if t == "boolean" then
		return java.bool(value)
	elseif t == "cdata" then
		return java.int(value)
	elseif t == "table" and Float * value then
		return java.float(value.value)
	elseif t == "number" then
		return java.double(value)
	elseif t == "string" then
		return java.string(value)
	elseif t == "table" and JavaObject * value then
		return value.handle
	end
	error("type not convertible")
end
java_reflect.to_java_type = to_java_type

local function from_java_type(jhandle)
	local cls = java.call_method(jhandle, _Object.getClass)
	local cls_name = java.call_method(cls, _Class.getName)
	local java_type = java.to_string(cls_name)
	if java_type == "java.lang.Boolean" then
		return java.to_string(jhandle) == "true"
	elseif java_type == "java.lang.Integer" then
		return 0LL + tonumber(java.to_string(jhandle))
	elseif java_type == "java.lang.Float" then
		return Float(tonumber(java.to_string(jhandle)))
	elseif java_type == "java.lang.Double" then
		return tonumber(java.to_string(jhandle))
	elseif java_type == "java.lang.String" then
		return java.to_string(jhandle)
	end
	return JavaObject(jhandle)
end
java_reflect.from_java_type = from_java_type

local function to_java_types(...)
	if ... == nil then
		return
	end
	return to_java_type((...)), to_java_types(select(2, ...))
end

function JavaObject:new(handle, own)
	if own == nil then
		own = true
	end
    self.handle = handle
    self.own = own
    self.is_array = nil
end

function JavaObject:toString()
	return java.to_string(self.handle)
end

function JavaObject:getClass()
	return JavaObject(java.call_method(self.handle, _Object.getClass))
end

-- function JavaObject:__tostring()  -- error on yield across C
-- 	return java_to_string(self.handle)
-- end

function JavaObject:__gc()
	if self.own then
    	java.release(self.handle)
	end
end

function JavaObject:__index(name)
	local v = JavaObject[name]
	if v then return v end

    local target_class = java.call_method(self.handle, _Object.getClass)
	local member = java.member(target_class, name)

	local ok, field = pcall(java.access_field, self.handle, member)
    if ok then
		return from_java_type(field)
	end
	return function(self, ...)
		local result = java.call_method(self.handle, member, to_java_types(...))
		return from_java_type(result)
	end
end

local JavaClass = JavaObject + {}

function JavaClass:new(name)
	JavaObject.new(self, java.class(name))
end

function JavaClass:__index(name)
	local v = JavaObject[name]
	if v then return v end

    if name == "class_" then
   		return JavaObject(self.handle, false)
	end

    if from_java_type(java.call_method(self.handle, _Class.isEnum)) then
		local valueOf = java.member(self.handle, "valueOf")
		return JavaObject(java.call_method(0, valueOf, java.string(name)))
	end

	local member = java.member(self.handle, name)
	local ok, field = pcall(java.access_field, self.handle, member)

    if ok then
		return from_java_type(field)
	end
	return function(_, ...)
		local result = java.call_method(0, member, to_java_types(...))
		return from_java_type(result)
	end
end

function JavaClass:__call(...)
    local ctors = java.ctor(self.handle)
    return JavaObject(java.new_instance(self.handle, ctors, to_java_types(...)))
end

java_reflect.JavaObject = JavaObject
java_reflect.JavaClass = JavaClass

return java_reflect
