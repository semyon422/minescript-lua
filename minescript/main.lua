package.path = package.path .. ";minescript/?.lua"
io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

local msrt = require("msrt")

local f = assert(loadfile(arg[1]))
msrt.run(f, unpack(arg, 2))
