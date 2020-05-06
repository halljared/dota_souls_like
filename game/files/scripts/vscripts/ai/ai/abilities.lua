--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai/core")
require("ai/ai/basic")
require("ai/behaviors/abilities")
require("ai/behaviors/idle")

AIAbilities = {}
AIAbilities.__index = AIAbilities

setmetatable(AIAbilities, {
	__index = AIBasic, -- this is what makes the inheritance work
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function AIAbilities:Spawn( entityKeyValues )
	local abilityBehavior = BehaviorAbilities(self.entity)
	local idleBehavior = BehaviorIdle(self.entity)
	self.abilityBehaviorSystem = AICore:CreateBehaviorSystem( {abilityBehavior, idleBehavior} )--, BehaviorRun }-- } )
	self:StartThinking()
end
