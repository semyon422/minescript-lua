local minescript = require("minescript")

local env = {}
setmetatable(env, {__index = function(t, k)
	return _G[k] or minescript[k]
end})

local function run(code)
	local ok, res = pcall(load, "return " .. code)
	if ok and res then
		setfenv(res, env)
		minescript.echo(res())
		return
	end
	assert(load(code))()
end

run(table.concat({unpack(arg, 3)}, "\n"))
