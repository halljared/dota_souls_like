--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai/basic")

function Spawn( entityKeyValues )
	local ai_basic = AIBasic(thisEntity)
	ai_basic:Spawn(entityKeyValues)
end
