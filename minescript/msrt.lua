local json = require("json")

local msrt = {}

function msrt.log(msg) end

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
msrt.wrap = wrap

local _next_fcallid = 1000
msrt.calls = {}

local _FUNCTION_PREFIX = "?mnsc:"

local function call_noreturn(executor_id, func_name, ...)
	local json_args = json.encode({...})
	local msg = ("%s0 %s %s %s"):format(_FUNCTION_PREFIX, executor_id, func_name, json_args)
	msrt.log(msg)
    print(msg)
end

---Calls a script function, asynchronously streaming return value(s).
---@param executor_id string
---@param func_name string name of Minescript function to call
---@param args table?
---@param retval_handler function callback invoked for each return value
---@param exception_handler function
---@return number
local function send(executor_id, func_name, args, retval_handler, exception_handler)
	_next_fcallid = _next_fcallid + 1
	msrt.calls[_next_fcallid] = {func_name, retval_handler, exception_handler}

	local json_args = json.encode(args or {})
	local msg = ("%s%s %s %s %s"):format(_FUNCTION_PREFIX, _next_fcallid, executor_id, func_name, json_args)
	msrt.log(msg)
	print(msg)

	return _next_fcallid
end

function msrt.cancel(func_call_id, func_name, executor_id)
    call_noreturn(executor_id, "cancelfn!", func_call_id, func_name)
end

---@async
---@param executor_id string
---@param on_error function
---@param func_name string name of Minescript function to call
---@param ... any
---@return any ret script function's return value: number, string, list, or dict
local function call_async_error(executor_id, on_error, func_name, ...)
	local c = assert(coroutine.running(), "attempt to yield from outside a coroutine")

	local function ret(retval)
		assert(coroutine.resume(c, retval))
	end

	send(executor_id, func_name, {...}, ret, on_error)

	return coroutine.yield()
end

---@async
---@param executor_id string
---@param func_name string name of Minescript function to call
---@param ... any
---@return any ret script function's return value: number, string, list, or dict
local function call_async(executor_id, func_name, ...)
	local c = assert(coroutine.running(), "attempt to yield from outside a coroutine")

	local err
	local function errf(e)
		err = e
		assert(coroutine.resume(c))
	end

	local retval = call_async_error(executor_id, errf, func_name, ...)
	if err then
		error(err)
	end

	return retval
end

local function service_step()
	local json_input = io.read("*L")
	msrt.log(json_input)
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
		local e = reply.except
		if not exception_handler then
			print_err(("%s in %s: %s %s"):format(e.type, func_name, e.message, e.desc))
			for _, s in ipairs(e.stack) do
				print_err(("%s %s %s"):format(s.file, s.method, s.line))
			end
		else
			exception_handler(("%s(%q)"):format(e.type, e.message))
		end
	else
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
		call_async("T", "flush")
		done = true
	end)()

	while true do
		if done and not next(msrt.calls) then
			return
		end
		if service_step() then
			return
		end
	end
end

---@param f function
---@param ... any
function msrt.run(f, ...)
	_run(f, ...)
	call_noreturn("T", "exit!")
end

msrt.send = send
msrt.call_async = call_async
msrt.call_noreturn = call_noreturn
msrt.print_err = print_err

return msrt
