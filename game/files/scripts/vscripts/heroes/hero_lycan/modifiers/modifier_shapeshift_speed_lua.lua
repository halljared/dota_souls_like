modifier_shapeshift_speed_lua = class({})

--[[Author: Perry,Noya
	Date: 26.09.2015.
	Creates a modifier that allows to go beyond the 522 movement speed limit]]
function modifier_shapeshift_speed_lua:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
	}

	return funcs
end

function modifier_shapeshift_speed_lua:GetModifierMoveSpeed_Max()
	return self:GetAbility():GetSpecialValueFor("speed")
end

function modifier_shapeshift_speed_lua:GetModifierMoveSpeed_Limit()
	return self:GetAbility():GetSpecialValueFor("speed")
end

function modifier_shapeshift_speed_lua:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor("speed")
end

function modifier_shapeshift_speed_lua:IsHidden()
	return true
end
