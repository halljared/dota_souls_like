modifier_resurrect_lua = class({})

function modifier_resurrect_lua:GetAttributes()
	return "MODIFIER_ATTRIBUTE_MULTIPLE | MODIFIER_ATTRIBUTE_PERMANENT"
end

function modifier_resurrect_lua:GetTexture()
	return "skeleton_king_reincarnation"
end

function modifier_resurrect_lua:RemoveOnDeath()
	return false
end

function modifier_resurrect_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN
	}
	return funcs
end

function modifier_resurrect_lua:OnToggle()
	-- Apply the rot modifier if the toggle is on
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "resurrect_lua", nil )

		if not self:GetCaster():IsChanneling() then
			self:GetCaster():StartGesture( ACT_DOTA_CAST_ABILITY_ROT )
		end
	else
		-- Remove it if it is off
		local hRotBuff = self:GetCaster():FindModifierByName( "resurrect_lua" )
		if hRotBuff ~= nil then
			hRotBuff:Destroy()
		end
	end
end


function modifier_resurrect_lua:OnDeath(keys)
	-- Apply the rot modifier if the toggle is on
	if IsServer() then
		local unit = keys.unit
		local modifier = unit:FindModifierByName('modifier_resurrect_lua')
		if modifier then modifier:DecrementStackCount() end
	end
end

function modifier_resurrect_lua:OnRespawn(keys)
	-- Apply the rot modifier if the toggle is on
	if IsServer() then
		local unit = keys.unit
		local modifier = unit:FindModifierByName('modifier_resurrect_lua')
		if modifier and modifier:GetStackCount() == 0 then
			unit:RemoveModifierByName('modifier_resurrect_lua')
			unit:SetRespawnsDisabled(true)
		end
	end
end

LinkLuaModifier( "modifier_resurrect_lua", "lua_modifiers/resurrect", LUA_MODIFIER_MOTION_NONE )
