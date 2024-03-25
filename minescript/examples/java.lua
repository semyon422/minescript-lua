local java_reflect = require("java_reflect")

local Minecraft = java_reflect.JavaClass("net.minecraft.class_310")  -- Minecraft
local minecraft = Minecraft:method_1551()  -- getInstance
print(minecraft:method_47599())  -- getFps

local player = minecraft.field_1724
print(player:method_24828())  -- isOnGround
print(player:method_17682().value)  -- getHeight
print(player:method_18800(0, 1, 0))  -- setDeltaMovement
print(player:method_24828())  -- isOnGround
