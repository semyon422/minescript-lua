local msrt = require("msrt")

local handler_id = msrt.call_async("S", "register_key_listener")
local task_id
task_id = msrt.send("T", "start_key_listener", {handler_id}, msrt.wrap(function(res)
	print(res.key)
	if res.action == 1 and res.key == 257 then  -- return key
		msrt.calls[task_id] = nil
		msrt.call_async("S", "unregister_event_handler", handler_id)
		print("exited")
	end
end), error)
