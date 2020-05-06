--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai/core")
require("ai/behaviors/idle")
require("internal/util")

AIBasic = {}

AIBasic.__index = AIBasic

setmetatable(AIBasic, {
	__index = AICore, -- this is what makes the inheritance work
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function AIBasic:_init(entity)
	self.entity = entity
	self.entity._rpgAI = self
end

function AIBasic:Spawn( entityKeyValues )
	local behavior = BehaviorIdle(self.entity)
	self.abilityBehaviorSystem = AICore:CreateBehaviorSystem( {behavior} )--, BehaviorRun }-- } )
	self:StartThinking()
end

function AIBasic:AIThink()
	if self.stopThinking or self.entity:IsNull() or not self.entity:IsAlive() then
		DebugPrint('stopped thinking')
		return nil -- deactivate this think function
	end
	return self.abilityBehaviorSystem:Think()
end

function AIBasic:StopThinking()
	DebugPrint('AIBasic:StopThinking')
	self.stopThinking = true;
end

function AIBasic:StartThinking()
	DebugPrint('AIBasic:StartThinking')
	self.stopThinking = false
	local _self = self
	self.entity:SetContextThink( "AIThink", function()
		return _self:AIThink()
	end, 0.25 )
end

function AIBasic:Freeze()
	self:StopThinking()
	self.entityAttackCapability = self.entity:GetAttackCapability()
	self.entityMoveCapability = self.entity:HasFlyMovementCapability() and DOTA_UNIT_CAP_MOVE_FLY or self.entity:HasGroundMovementCapability() and DOTA_UNIT_CAP_MOVE_GROUND or DOTA_UNIT_CAP_MOVE_NONE 
	self.entity:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	self.entity:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
end

function AIBasic:Unfreeze()
	self.entity:SetAttackCapability(self.entityAttackCapability)
	self.entity:SetMoveCapability(self.entityMoveCapability)
	self:StartThinking()
end