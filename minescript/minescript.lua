local msrt = require("msrt")

local minescript = {}

---Sends the given message to the chat.
---@param message any
function minescript.echo(message)
	msrt.print_err(message)
end

---Sends the given message to latest.log.
---@param message string
function minescript.log(message)
	msrt.call_async("log", message)
end

---Takes a screenshot, similar to pressing the F2 key.
---@async
---@param filename string
---@return boolean
function minescript.screenshot(filename)
	return msrt.call_async("screenshot", filename)
end

---Wait for all previously issued script commands from this job to complete.
---@async
function minescript.flush()
	return msrt.call_async("flush")
end

---Gets the local player's name.
---@async
---@return string
function minescript.player_name()
	return msrt.call_async("player_name")
end

---Gets the local player's position.
---@async
---@return table
function minescript.player_position()
	return msrt.call_async("player_position")
end

---Sets the player's position, and optionally orientation.
---@async
---@param x number
---@param y number
---@param z number
---@param yaw number?
---@param pitch number?
---@return boolean
function minescript.player_set_position(x, y, z, yaw, pitch)
	return msrt.call_async("player_set_position", x, y, z, yaw, pitch)
end

---Gets the items in the local player's hands.
---@async
---@return table
function minescript.player_hand_items()
	return msrt.call_async("player_hand_items")
end

---Gets the items in the local player's inventory.
---@async
---@return table
function minescript.player_inventory()
	return msrt.call_async("player_inventory")
end

---Swaps an inventory item into the hotbar.
---@async
---@param slot number
---@return number
function minescript.player_inventory_slot_to_hotbar(slot)
	return msrt.call_async("player_inventory_slot_to_hotbar", slot)
end

---Selects the given slot within the player's hotbar.
---@async
---@param slot number
---@return number
function minescript.player_inventory_select_slot(slot)
	return msrt.call_async("player_inventory_select_slot", slot)
end

---Simulating press/release.
---@async
---@param key "forward" | "backward" | "left" | "right" | "jump" | "sprint" | "sneak" | "pick_item" | "use" | "attack" | "swap_hands" | "drop"
---@param pressed boolean
function minescript.player_press(key, pressed)
	msrt.call_async("player_press_" .. key, pressed)
end

---Gets the local player's orientation.
---@async
---@return table
function minescript.player_orientation()
	return msrt.call_async("player_orientation")
end

---Gets the local player's orientation.
---@async
---@param yaw number
---@param pitch number
---@return boolean
function minescript.player_set_orientation(yaw, pitch)
	return msrt.call_async("player_set_orientation", yaw, pitch)
end

---Gets info about the nearest block, if any, in the local player's crosshairs.
---@async
---@param max_distance number
---@return table
function minescript.player_get_targeted_block(max_distance)
	return msrt.call_async("player_get_targeted_block", max_distance or 20)
end

---Gets the local player's health.
---@async
---@return number
function minescript.player_health()
	return msrt.call_async("player_health")
end

---Gets a list of nearby players and their attributes.
---@async
---@param nbt boolean
---@return table
function minescript.players(nbt)
	return msrt.call_async("players", nbt)
end

---Gets a list of nearby entities and their attributes.
---@async
---@param nbt boolean
---@return table
function minescript.entities(nbt)
	return msrt.call_async("entities", nbt)
end

---Gets world properties.
---@async
---@return table
function minescript.world_properties()
	return msrt.call_async("world_properties")
end

---Gets the type of block at position (x, y, z).
---@async
---@param x number
---@param y number
---@param z number
---@return table
function minescript.getblock(x, y, z)
	return msrt.call_async("getblock", x, y, z)
end

---Gets the types of block at the specified [x, y, z] positions.
---@async
---@param positions table
---@return table
function minescript.getblocklist(positions)
	return msrt.call_async("getblocklist", positions)
end

---Notifies the caller when the region from (x1, z1) to (x2, z2) is loaded.
---@async
---@param x1 number
---@param z1 number
---@param x2 number
---@param z2 number
function minescript.await_loaded_region(x1, z1, x2, z2)
	msrt.call_async("await_loaded_region", x1, z1, x2, z2)
end

---Registers a listener for receiving keyboard events. One listener allowed per job.
---@param listener function
---@param exception_handler function?
function minescript.register_key_event_listener(listener, exception_handler)
	msrt.add_task("register_key_event_listener", nil, listener, exception_handler)
end

---Unregisters a key event listener, if any, for the currently running job.
---@async
function minescript.unregister_key_event_listener()
	msrt.call_async("unregister_key_event_listener")
end

msrt.hooks.unregister_key_event_listener = function()
	for k, v in pairs(msrt.calls) do
		if v[1] == "register_key_event_listener" then
			msrt.calls[k] = nil
		end
	end
end

---Registers a listener for receiving chat messages. One listener allowed per job.
---@param listener function
---@param exception_handler function?
function minescript.register_chat_message_listener(listener, exception_handler)
	msrt.add_task("register_chat_message_listener", nil, listener, exception_handler)
end

---Unregisters a chat message listener, if any, for the currently running job.
---@async
function minescript.unregister_chat_message_listener()
	msrt.call_async("unregister_chat_message_listener")
end

msrt.hooks.unregister_chat_message_listener = function()
	for k, v in pairs(msrt.calls) do
		if v[1] == "register_chat_message_listener" then
			msrt.calls[k] = nil
		end
	end
end

---Registers an interceptor for swallowing chat messages.
---@param interceptor function
---@param exception_handler function?
function minescript.register_chat_message_interceptor(interceptor, exception_handler)
	msrt.add_task("register_chat_message_interceptor", nil, interceptor, exception_handler)
end

---Unregisters the chat message interceptor, if one is currently registered.
---@async
function minescript.unregister_chat_message_interceptor()
	msrt.call_async("unregister_chat_message_interceptor")
end

msrt.hooks.unregister_chat_message_interceptor = function()
	for k, v in pairs(msrt.calls) do
		if v[1] == "register_chat_message_interceptor" then
			msrt.calls[k] = nil
		end
	end
end

---Gets the current GUI screen name, if there is one.
---@async
function minescript.screen_name()
	msrt.call_async("screen_name")
end

return minescript
