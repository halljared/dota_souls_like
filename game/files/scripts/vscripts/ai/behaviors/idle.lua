BehaviorIdle = {}

BehaviorIdle.__index = BehaviorIdle

setmetatable(BehaviorIdle, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function BehaviorIdle.new(entity)
	local self = setmetatable({}, BehaviorIdle)
	self.entity = entity
	self.baseDesire = 1
	self.maxDesireIncrease = 1
	self.desire = self.baseDesire
	return self
end

function GetPointNearPoint(point, distance)
	local rx = RandomInt(-distance, distance)
	local ry = RandomInt(-distance, distance)
	local vRandom = Vector(rx, ry, 0)
	local vNew = point + vRandom
	return vNew
end

function BehaviorIdle:MakeOrder()
	local thisEntity = self.entity
	local vNew = GetPointNearPoint(thisEntity:GetAbsOrigin(), 400)
	return {
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = vNew
		}
end

function BehaviorIdle:GetDesire()
	self.desire = self.desire + RandomInt(1, self.maxDesireIncrease)
	return self.desire
end

function BehaviorIdle:Evaluate()
	self.endTime = GameRules:GetGameTime() + 2	
	self.desire = self.baseDesire
	return self:MakeOrder()	
end

function BehaviorIdle:Begin()
	--
end

function BehaviorIdle:Continue()
	--
end

function BehaviorIdle:End()
	--
end

function BehaviorIdle:Think(dt)
	--
end
