--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai/abilities")

function Spawn( entityKeyValues )
	local ai_abilities = AIAbilities(thisEntity)
	ai_abilities:Spawn(entityKeyValues)
end