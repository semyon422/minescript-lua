local msrt = require("msrt")

local f = assert(io.open("minescript/msrt.log", "w"))
f:setvbuf("no")

function msrt.log(msg)
	f:write(msg)
	f:write("\n")
end

local p = msrt.call_async("S", "player_position")
msrt.call_noreturn("R", "echo", table.concat(p, ", "))
