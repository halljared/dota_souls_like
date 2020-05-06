BehaviorAbilities = {}

BehaviorAbilities.__index = BehaviorAbilities

setmetatable(BehaviorAbilities, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function BehaviorAbilities.new(entity)
	local self = setmetatable({}, BehaviorAbilities)
	self.entity = entity
	self.baseDesire = 2
	self.maxDesireIncrease = 4
	self.desire = self.baseDesire
	return self
end


-- Find all the active abilities on this unit and build a list (assumes active abilities exist, this is not a robust solution for various npcs)
function GetAbilities(unit)
	local abilities = {}
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i) -- set this to minus one once jeff's changes are through to test the code fix
		if ability ~= nil and ability:IsFullyCastable() then
			local nBehaviorFlags = ability:GetBehavior()
			if DOTA_ABILITY_BEHAVIOR_HIDDEN ~= bit.band( DOTA_ABILITY_BEHAVIOR_HIDDEN, nBehaviorFlags ) and
					DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE ~= bit.band( DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE, nBehaviorFlags ) and
					DOTA_ABILITY_BEHAVIOR_PASSIVE ~= bit.band( DOTA_ABILITY_BEHAVIOR_PASSIVE, nBehaviorFlags ) and
					ability:GetAbilityName() ~= "attribute_bonus" then
				table.insert(abilities, ability)
			end
		end
	end
	return abilities
end



function BehaviorAbilities:MakeOrder()
	local order
	local thisEntity = self.entity
	local target = thisEntity:GetAggroTarget() 
	if target ~= nil then
		local abilities = GetAbilities(thisEntity)
		if #abilities > 0 then
			local abilitiesIndex = RandomInt( 1, #abilities )
			local ability = abilities[ abilitiesIndex ]
			local nBehaviorFlags = ability:GetBehavior()
			local nType = bit.band( DOTA_ABILITY_BEHAVIOR_NO_TARGET, nBehaviorFlags ) == DOTA_ABILITY_BEHAVIOR_NO_TARGET and DOTA_UNIT_ORDER_CAST_NO_TARGET or
							bit.band( DOTA_ABILITY_BEHAVIOR_POINT, nBehaviorFlags ) == DOTA_ABILITY_BEHAVIOR_POINT and DOTA_UNIT_ORDER_CAST_POSITION or
							bit.band( DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, nBehaviorFlags ) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET and DOTA_UNIT_ORDER_CAST_TARGET
			order = {
					UnitIndex = thisEntity:entindex(),
					OrderType = nType,
					AbilityIndex = ability:entindex()
				}

			if nType == DOTA_UNIT_ORDER_CAST_TARGET then
				order.TargetIndex = target:entindex()
			elseif nType == DOTA_UNIT_ORDER_CAST_POSITION then
				order.Position = target:GetOrigin()
			else
				--
			end	
		end
	end
	PrintTable(order)
	return order
end


function BehaviorAbilities:GetDesire()
	self.desire = self.desire + RandomInt(1, self.maxDesireIncrease)
	return self.desire
end

function BehaviorAbilities:Evaluate()
	self.endTime = GameRules:GetGameTime() + 2	
	self.desire = self.baseDesire
	return self:MakeOrder()	
end

function BehaviorAbilities:Begin()
end

function BehaviorAbilities:Continue()
end

function BehaviorAbilities:End()
	--
end

function BehaviorAbilities:Think(dt)
	
end