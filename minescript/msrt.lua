local json = require("json")

local msrt = {}

---@param s string
local function print_err(s)
	io.stderr:write(tostring(s) .. "\n")
end

---@param f function
---@param ... any?
---@return thread
local function call(f, ...)
	assert(not coroutine.running(), "attempt to call a function from a coroutine")
	return coroutine.wrap(f)(...)
end

---@param f function
---@return function
local function wrap(f)
	return function(...)
		return call(f, ...)
	end
end

local _next_fcallid = 1000
msrt.calls = {}
msrt.hooks = {}

---Calls a script function, asynchronously streaming return value(s).
---@param func_name string name of Minescript function to call
---@param args table?
---@param retval_handler function callback invoked for each return value
---@param exception_handler function?
local function add_task(func_name, args, retval_handler, exception_handler)
	retval_handler = wrap(retval_handler)
	exception_handler = exception_handler and wrap(exception_handler)

	_next_fcallid = _next_fcallid + 1
	msrt.calls[_next_fcallid] = {func_name, retval_handler, exception_handler}
	print(("?%s %s %s"):format(_next_fcallid, func_name, json.encode(args or {})))

	local hook = msrt.hooks[func_name]
	if hook then
		hook()
	end
end

---Calls a script function and returns the function's return value.
---@param func_name string name of Minescript function to call
---@param ... any
---@return any ret script function's return value: number, string, list, or dict
local function call_async(func_name, ...)
	local c = assert(coroutine.running(), "attempt to yield from outside a coroutine")

	local function ret(retval)
		assert(coroutine.resume(c, retval))
	end

	add_task(func_name, {...}, ret, error)

	return coroutine.yield()
end

local function service_step()
	local json_input = io.read()
	local ok, reply = xpcall(json.decode, debug.traceback, json_input)
	if not ok then
		print_err(reply)
		print_err(("JSON error in: %s"):format(json_input))
		return
	end

	local func_call_id = reply.fcid
	if not func_call_id then
		print_err("'fcid' field missing in script function response")
		return
	end

	if func_call_id == 0 then
		if reply.retval == "exit!" then
			return true
		end
		return
	end

	if not msrt.calls[func_call_id] then
		print_err(("fcid=%s not found in calls"):format(
			func_call_id
		))
		return
	end

	local func_name, retval_handler, exception_handler = unpack(msrt.calls[func_call_id])
	if reply.conn == "close" then
		msrt.calls[func_call_id] = nil
	end

	if reply.except then
		local exception_type = reply.except.type
		local message = reply.except.message
		if not exception_handler then
			print_err(("%s in %s: %s"):format(exception_type, func_name, message))
		else
			exception_handler(("%s(%q)"):format(exception_type, message))
		end
	elseif reply.retval then
		retval_handler(reply.retval)
	end

	if not reply.conn and not reply.retval and not reply.except then
		print_err(("script function response missing 'conn', 'retval', and 'except': %s"):format(
			json_input
		))
	end
end

---@param f function
---@param ... any
local function _run(f, ...)
	local done = false

	wrap(function(...)
		f()
		msrt.call_async("flush")
		done = true
	end)()

	if done and not next(msrt.calls) then
		return
	end

	while true do
		if service_step() then
			return
		end
		if done and not next(msrt.calls) then
			return
		end
	end
end

---@param f function
---@param ... any
function msrt.run(f, ...)
	_run(f, ...)
	print("?0 exit!")
end

msrt.add_task = add_task
msrt.call_async = call_async
msrt.print_err = print_err

return msrt
