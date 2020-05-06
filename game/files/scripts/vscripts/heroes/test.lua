require('../libraries/timers')
require('../libraries/animations')

-- Stop various sounds that are fired from the KV's
function StopLoopSound( keys )
	local caster = keys.caster
	caster:StopSound("Hero_WitchDoctor.Voodoo_Restoration.Loop")
end
function StopDrainSound( keys )
	local caster = keys.target
	caster:StopSound("Hero_Pugna.LifeDrain.Target")
end
function StopSoundDataDriven( keys )
	local caster = keys.caster
	StopSoundEvent(keys.eventName, caster)
end

function FireSoundForPlayer( keys )
	local target = keys.target
	EmitSoundOn(keys.sound, target)
end

function ForwardPoint( event )
	local caster = event.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	local distance = event.distance
	local front_position = origin + fv * distance
	return front_position
end

function ApplyAnimationTranslation( keys )
	local hero = keys.caster
	hero:AddNewModifier(hero, nil, 'modifier_animation_translate', {})
end

function ApplyWeaponGlow( keys )
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local glowParticle = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/underlord_atrophy_weapon.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(glowParticle, 0, caster, PATTACH_CUSTOMORIGIN_FOLLOW, 'attach_weapon', casterOrigin, true)
	ParticleManager:SetParticleControl(glowParticle, 2, Vector(200, 0, 0))
end


-- This function is the "Gravity Controller" that is applied in the ability KV's
function TestGravityFunc(args)
	local targetPos = args.target:GetAbsOrigin()
	local casterPos = args.caster:GetAbsOrigin()

	local direction = casterPos - targetPos
	local vec = direction:Normalized() * 3.0

	args.target:SetAbsOrigin(targetPos + vec)
end

function MoveParticleStart(keys)
	local caster = keys.caster
	local particlePos = caster:GetAbsOrigin()
	local ability = keys.ability
	ability.particlePos = particlePos
end

function MoveParticle(keys)
	local caster = keys.caster
	local ability = keys.ability
	local particleName = keys.particle_name
	local particlePos = ability.particlePos
	local dummy = {}
	local fxIndex
	local r
	local phase = keys.phase and keys.phase or 1
	local rStart = keys.radius
	local rEnd = keys.radius_end
	local calculatedRadius
	local particleDuration = keys.particle_duration
	local batch = keys.batch and keys.batch or 1 -- use the batch that is passed in else default batch of 1
	for i=1,batch do
		-- circle split into # of batch chunks; offset is the i'th chunk
		local t = 0
		local offset = ((2 * math.pi) / batch) * (i - 1) * (1 / phase)
		Timers:CreateTimer(0, function()
				local dt
				if not dummy[i] or (dummy[i] and dummy[i]:IsAlive()) then
					local rInterp
					if rEnd ~= nil then
						local fraction = t / particleDuration
						local rDiff = rEnd - rStart
						rInterp = rStart + (fraction * rDiff)
					end
					r = rInterp and rInterp or rStart
					--calculatedRadius = r + ( math.abs( ( r * 2 / math.pi) * math.asin( math.sin( 2 * math.pi *  t / 2 ) ) ) )
					calculatedRadius = r
					local _t = t
					if keys.no_rotate then _t = 0 end
					local particleX = calculatedRadius * math.cos( phase * (_t + offset) )
					local particleY = calculatedRadius * math.sin( phase * (_t + offset) )
					local tangentAngle = math.pi / 2
					local tangentX = particleX * math.cos(tangentAngle) - particleY * math.sin(tangentAngle)
					local tangentY = particleX * math.sin(tangentAngle) + particleY * math.cos(tangentAngle)
					local forwardVector = Vector(tangentX, tangentY, 0)

					-- Setting up the dummy/particle only once we know its starting position.
					-- This stops particle trails from going everywhere when it spawns
					if not dummy[i] then
						dummy[i] = MakeDummyTargetGeneric(keys)
						local thisDummy = dummy[i]
						thisDummy:SetAbsOrigin( particlePos + Vector( particleX, particleY, 0 ) )
						ability:ApplyDataDrivenModifier( thisDummy, thisDummy, keys.collision_modifier, {} )
						fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, thisDummy )
						thisDummy.pfx = fxIndex
						thisDummy:SetForwardVector( forwardVector )
					else
						dummy[i]:SetAbsOrigin( particlePos + Vector( particleX, particleY, 0 ) )
						dummy[i]:SetForwardVector( forwardVector )
					end


					dt = (1.0/30.0)
					t = t + dt
				else 
					dt = nil
				end
				return dt
			end
		)
		Timers:CreateTimer(particleDuration, function()	
				if dummy[i] and (not dummy[i]:IsNull() and dummy[i]:IsAlive()) then
					ParticleManager:DestroyParticle( dummy[i].pfx, false )
					dummy[i]:ForceKill( true )
				end
			end
		)
	end
end

function DestroyDummy( event )
	Timers:CreateTimer(1/30, function()	
			local dummy	= event.caster
			if dummy and not dummy:IsNull() and dummy:IsAlive() then dummy:ForceKill( true ) end
			if dummy and dummy.pfx then ParticleManager:DestroyParticle( dummy.pfx, false ) end
		end
	)
end


function ExplodeAuraCreated( keys )
	print('ExplodeAuraCreated')
end

-- Could be used to "enhance" the movement of a unit, but it would have to be turned off when they stop
function EnhanceSpeedFunc(args)
	local casterPos = args.caster:GetAbsOrigin()

	local direction = args.caster:GetForwardVector()
	local vec = direction:Normalized() * 20.0

	args.caster:SetAbsOrigin(casterPos + vec)
end

-- This removes the motion controllers that were applied in the KV's
function RemoveMotionController( args )
	local target = args.target
	target:InterruptMotionControllers(true)
end

-- Triggers attack/attack2 hero animation
function AttackAnimation( args )
	local caster = args.caster
	local animation = RandomInt(0,1) == 0 and ACT_DOTA_ATTACK or ACT_DOTA_ATTACK2
	caster:StartGesture(animation)
end

local fenceId = -1 

function StartElectricFence(keys)
	local caster = keys.caster
	fenceId = fenceId + 1
	caster.FenceParticles = {}
	MakeFenceParticle(keys)
end

function MakeFenceParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local casterForwardVector = caster:GetForwardVector()
	local fenceParticle = ParticleManager:CreateParticle("particles/electric_wire/electric_wire.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	caster.FenceParticle = fenceParticle
	caster.OldForwardVector = casterForwardVector
	table.insert(caster.FenceParticles, fencePartile)
	ParticleManager:SetParticleControlEnt(fenceParticle, 0, caster, PATTACH_POINT_FOLLOW, 'attach_hitloc', casterOrigin, true)
	local particleWorldOrigin = casterOrigin + Vector(0,0,100)
	caster.ParticleWorldOrigin = particleWorldOrigin	
	ParticleManager:SetParticleControl(fenceParticle, 1, particleWorldOrigin)
end

function PlaceFenceParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local fenceParticle = caster.FenceParticle
	-- Destroy the old particle
	ParticleManager:DestroyParticle(fenceParticle, true)
	-- Make a new dummy particle to mimic the old's location
	local particleWorldOrigin = caster.ParticleWorldOrigin
	local dummyParticle = ParticleManager:CreateParticle("particles/electric_wire/electric_wire.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(dummyParticle, 0, casterOrigin + Vector(0,0,100))
	ParticleManager:SetParticleControl(dummyParticle, 1, particleWorldOrigin)
	table.insert(caster.FenceParticles, dummyParticle)

	-- Set up a timer to destoy the particle
	Timers:CreateTimer(keys.duration, function()
		ParticleManager:DestroyParticle(dummyParticle, false )
			return nil
		end
	)
	MakeFenceParticle(keys)
end

function EndElectricFence(keys)
	local caster = keys.caster
	local fenceParticle = caster.FenceParticle
	-- Destroy the active particle
	ParticleManager:DestroyParticle(fenceParticle, true)
	caster.FenceParticle = nil
	caster.FenceParticles = nil
end

function ElectricFenceStun( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local stun_duration = ability:GetLevelSpecialValueFor("duration_stun", 1)

	if target.fenceId ~= fenceId then
		target.fenceId = fenceId
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
	end
end

function RemoveElectricSlow( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", 1)

	Timers:CreateTimer(tick_rate + 0.01, function()
		if not target:HasModifier('modifier_electric_wire_caught_hidden') then
			target:RemoveModifierByName('modifier_electric_wire_caught')
		end
		return nil
	end)
end

function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local pid = caster:GetPlayerID()
	local difference = point - casterPos
	local ability = keys.ability
	local range = ability:GetLevelSpecialValueFor("distance", (ability:GetLevel() - 1))

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false)
	ProjectileManager:ProjectileDodge(caster)
end

function CripplingAttacksStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local angle = tonumber(keys.angle)
	local casterForward = caster:GetForwardVector()
	local targetForward = target:GetForwardVector()
	local casterAngle = VectorToAngles(casterForward)
	local targetAngle = VectorToAngles(targetForward)
	local angleDiff = math.abs(targetAngle.y - casterAngle.y)

	local isFront = math.abs(angleDiff - 180) <= angle
	local isBack = angleDiff <= angle 

	if isFront then
		ability:ApplyDataDrivenModifier(caster, caster, keys.isFront, {})
	elseif isBack then
		ability:ApplyDataDrivenModifier(caster, caster, keys.isBack, {})
	end
end

function Echo(keys)
	local text = keys.text
	print("Echo: " .. text)
end

function FireSnowCone(keys)
	local caster = keys.caster
	local ability = keys.ability
	local pfx = ParticleManager:CreateParticle( "particles/ice_cone/snow_cone.vpcf", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_CUSTOMORIGIN, "attach_core", caster:GetAbsOrigin(), true )
	ParticleManager:SetParticleControl( pfx, 1, caster:GetAbsOrigin() + (caster:GetForwardVector() * ability:GetSpecialValueFor("travel_distance")) )
	caster.snow_cone_pfx = pfx
end

function SnowConeThink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local pfx = caster.snow_cone_pfx
	ParticleManager:SetParticleControl( pfx, 1, caster:GetAbsOrigin() + (caster:GetForwardVector() * ability:GetSpecialValueFor("travel_distance")) )
end

function DestroySnowCone(keys)
	local caster = keys.caster
	ParticleManager:DestroyParticle( caster.snow_cone_pfx, false )
end

function ShootDummyTarget(keys)
	local caster = keys.caster
	local ability = keys.ability
	local dummy = ability[keys.dummyName]
	local targetTeam = ability:GetAbilityTargetTeam() -- DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = ability:GetAbilityTargetType() -- DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlags = ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local damageType = ability:GetAbilityDamageType()
	local targetPos = dummy:GetAbsOrigin()
	local casterPos = caster:GetAbsOrigin()
	local vector_distance = targetPos - casterPos
	local distance = (vector_distance):Length2D()
	local direction = (vector_distance):Normalized()

	ProjectileManager:CreateLinearProjectile( {
		Ability				= ability,
		EffectName			= keys.effectName,
		vSpawnOrigin		= casterPos + Vector(0,0,100),
		fDistance			= keys.distance or distance,
		fStartRadius		= keys.start_radius,
		fEndRadius			= keys.end_radius,
		Source				= caster,
		bHasFrontalCone		= true,
		bReplaceExisting	= false,
		iUnitTargetTeam		= targetTeam,
		iUnitTargetFlags	= targetFlags,
		iUnitTargetType		= targetType,
	--	fExpireTime			= ,
		bDeleteOnHit		= keys.deleteOnHit or true,
		vVelocity			= direction * keys.speed,
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	} )
end

function DamageTarget(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_table = {}

	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1))

	ApplyDamage(damage_table)
end

function DamageUnit(unit, attacker, ability, type, damage)

	local damage_table = {}

	damage_table.victim = unit
	damage_table.attacker = attacker
	damage_table.ability = ability
	damage_table.damage_type = type
	damage_table.damage = damage

	ApplyDamage(damage_table)
end

function StayDead(keys)
	local caster = keys.caster
	caster:SetRespawnsDisabled(true)
end

function MakeDummyTargetGeneric(keys)
	--DeepPrintTable(keys.ability)
	local ability = keys.ability
	local caster = keys.caster
	local refModifierName = "modifier_dummy_unit_datadriven"
	local dummy = CreateUnitByName( "npc_dummy_blank", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam() )
	ability:ApplyDataDrivenModifier( caster, dummy, refModifierName, {} )
	return dummy
end

function OnDestroyDummy( event )
	local dummy	= event.target
	local ability = event.ability
	
	ParticleManager:DestroyParticle( dummy.pfx, false )
	dummy:ForceKill( true )
end

function MakeDummyTarget(keys)
	--DeepPrintTable(keys.ability)
	local ability = keys.ability
	local caster = keys.caster
	local refModifierName = "modifier_dummy_unit_datadriven"
	local dummy = CreateUnitByName( "npc_dummy_blank", keys.target_points[1], false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, refModifierName, {} )
	ability[keys.dummyName] = dummy
end

function DestroyDummyTarget(keys)
	local ability = keys.ability
	ability[keys.dummyName]:ForceKill( true )
end


function PrintArgs(keys)
	--DeepPrintTable(keys.ability)
	for k,v in pairs( keys ) do
		print( k )
	end

	if keys.target_points then
		print(keys.target_points[1])
	end

	if keys.caster and keys.caster.pfx then
		print('pfx: aka caster is dummy')
	end
end



--[[
	CHANGELIST:
	09.01.2015 - Standandized variables and remove ReleaseParticleIndex( .. )
]]

--[[
	Author: kritth
	Date: 5.1.2015.
	Order the explosion in clockwise direction
]]
function freezing_field_order_explosion( keys )
	Timers:CreateTimer( 0.1, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_northwest_thinker_datadriven", {} )
		return nil
		end )
		
	Timers:CreateTimer( 0.2, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_northeast_thinker_datadriven", {} )
		return nil
		end )
	
	Timers:CreateTimer( 0.3, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_southeast_thinker_datadriven", {} )
		return nil
		end )
	
	Timers:CreateTimer( 0.4, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_southwest_thinker_datadriven", {} )
		return nil
		end )
end

--[[
	Author: kritth
	Date: 09.01.2015.
	Apply the explosion
]]
function freezing_field_explode( keys )
	local ability = keys.ability
	local caster = keys.caster
	local casterLocation = keys.caster:GetAbsOrigin()
	local abilityDamage = ability:GetLevelSpecialValueFor( "damage", ( ability:GetLevel() - 1 ) )
	local minDistance = ability:GetLevelSpecialValueFor( "explosion_min_dist", ( ability:GetLevel() - 1 ) )
	local maxDistance = ability:GetLevelSpecialValueFor( "explosion_max_dist", ( ability:GetLevel() - 1 ) )
	local radius = ability:GetLevelSpecialValueFor( "explosion_radius", ( ability:GetLevel() - 1 ) )
	local directionConstraint = keys.section
	local modifierName = "modifier_freezing_field_debuff_datadriven"
	local refModifierName = "modifier_freezing_field_ref_point_datadriven"
	local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
	local soundEventName = "hero_Crystal.freezingField.explosion"
	local targetTeam = ability:GetAbilityTargetTeam() -- DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = ability:GetAbilityTargetType() -- DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlag = ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local damageType = ability:GetAbilityDamageType()
	
	-- Get random point
	local castDistance = RandomInt( minDistance, maxDistance )
	local angle = RandomInt( 0, 90 )
	local dy = castDistance * math.sin( angle )
	local dx = castDistance * math.cos( angle )
	local attackPoint = Vector( 0, 0, 0 )
	
	if directionConstraint == 0 then			-- NW
		attackPoint = Vector( casterLocation.x - dx, casterLocation.y + dy, casterLocation.z )
	elseif directionConstraint == 1 then		-- NE
		attackPoint = Vector( casterLocation.x + dx, casterLocation.y + dy, casterLocation.z )
	elseif directionConstraint == 2 then		-- SE
		attackPoint = Vector( casterLocation.x + dx, casterLocation.y - dy, casterLocation.z )
	else										-- SW
		attackPoint = Vector( casterLocation.x - dx, casterLocation.y - dy, casterLocation.z )
	end
	
	-- From here onwards might be possible to port it back to datadriven through modifierArgs with point but for now leave it as is
	-- Loop through units
	local units = FindUnitsInRadius( caster:GetTeam(), attackPoint, nil, radius,
			targetTeam, targetType, targetFlag, 0, false )
	for k, v in pairs( units ) do
		local damageTable =
		{
			victim = v,
			attacker = caster,
			damage = abilityDamage,
			damage_type = damageType
		}
		ApplyDamage( damageTable )
	end
	
	-- Fire effect
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 0, attackPoint )
	
	-- Fire sound at dummy
	local dummy = CreateUnitByName( "npc_dummy_blank", attackPoint, false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, refModifierName, {} )
	StartSoundEvent( soundEventName, dummy )
	Timers:CreateTimer( 0.1, function()
		dummy:ForceKill( true )
		return nil
	end )
end

function FireEffectCustom(keys)
	local ability = keys.ability
	local caster = keys.caster
	local casterLocation = keys.caster:GetAbsOrigin()
	local particleName = keys.particleName
	local attackPoint = keys.target_points and keys.target_points[1] or nil
	local duration = keys.duration
	local attach = keys.attach
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 0, attackPoint )
	Timers:CreateTimer( duration, function()
		ParticleManager:DestroyParticle(fxIndex, false)
	end )
end

function FireSnowConeEffect(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local dummy = ability[keys.dummyName]
	local casterLocation = caster:GetAbsOrigin()
	local dummyLocation = dummy:GetAbsOrigin()
	local particleName = keys.particleName
	local duration = keys.duration
	local attach = keys.attach
	local distance = keys.distance

	function moveDummy()
		casterLocation = caster:GetAbsOrigin()
		targetLocation = target:GetAbsOrigin()
		dummyLocation = dummy:GetAbsOrigin()
		local vector_distance = targetLocation - casterLocation
		local direction = (vector_distance):Normalized()
		local newDummyPos = casterLocation + (direction * distance)
		dummy:SetAbsOrigin(newDummyPos)
	end

	moveDummy() --initial call so that dummy is positioned before the pfx is created
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControlEnt(fxIndex, 0, caster, PATTACH_ABSORIGIN_FOLLOW, follow_origin, casterLocation, true)
	ParticleManager:SetParticleControlEnt(fxIndex, 1, dummy, PATTACH_ABSORIGIN_FOLLOW, follow_origin, dummyLocation, true)
	Timers:CreateTimer( duration, function()
		ParticleManager:DestroyParticle(fxIndex, false)
	end )

	-- Set up a timer to keep the dummy in the correct position
	Timers:CreateTimer( 0, function()
		local update = 0
		if not dummy:IsNull() and dummy:IsAlive() then
			moveDummy()
			update = 0.1
		else
			update = 0
		end
		return update
	end)
end



function CasterLeap( keys )
	local caster = keys.caster
	local fv = caster:GetForwardVector()
	local vCaster = caster:GetAbsOrigin()
	local len = keys.distance
	local rear_position = vCaster - fv * 2 -- arbitrary multiplier I think
	local knockbackModifierTable =
	{
		should_stun = false,
		knockback_duration = keys.duration,
		duration = keys.duration,
		mirana_leap_distance = 600,
		knockback_height = 100,
		center_x = rear_position.x,
		center_y = rear_position.y,
		center_z = rear_position.z
	}
	caster:AddNewModifier(caster, nil, 'modifier_item_forcestaff_active', {push_length = 600})
	--caster:RemoveModifierByName( 'modifier_spirit_breaker_greater_bash' )

	Timers:CreateTimer( 0.1, function()
		caster:RemoveEffects( EF_NODRAW )
		for i=0,caster:GetModifierCount() do
			print(i .. ':' .. caster:GetModifierNameByIndex(i))
		end
	end )
end

function Leap( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1	

	-- Clears any current command and disjoints projectiles
	caster:Stop()
	-- ProjectileManager:ProjectileDodge(caster)
	local backwards = ability:GetSpecialValueFor("backwards")
	if backwards == 1 then
		backwards = -1
	else
		backwards = 1
	end
	-- Ability variables
	ability.leap_direction = caster:GetForwardVector() * backwards
	ability.leap_distance = ability:GetLevelSpecialValueFor("leap_distance", ability_level)
	ability.leap_speed = ability:GetLevelSpecialValueFor("leap_speed", ability_level) * 1/30
	ability.leap_vertical_ratio = ability:GetLevelSpecialValueFor("leap_vertical_ratio", ability_level)
	ability.leap_traveled = 0
	ability.leap_z = 0

	-- StartAnimation(caster, {activity=ACT_DOTA_FLAIL, duration=1, rate=1.5})
	-- Timers:CreateTimer( 1, function()
	-- 	EndAnimation(caster)
	-- end )
end

--[[Moves the caster on the horizontal axis until it has traveled the distance]]
function LeapHorizonal( keys )
	local caster = keys.target
	local ability = keys.ability

	if ability.leap_traveled < ability.leap_distance then
		caster:SetAbsOrigin(caster:GetAbsOrigin() + ability.leap_direction * ability.leap_speed)
		ability.leap_traveled = ability.leap_traveled + ability.leap_speed
	else
		-- EndAnimation(caster)
		caster:InterruptMotionControllers(true)
		--StartAnimation(caster, {activity=ACT_DOTA_CAST_ABILITY_1, duration=1, rate=1.5})
	end
end

--[[Moves the caster on the vertical axis until movement is interrupted]]
function LeapVertical( keys )
	local caster = keys.target
	local ability = keys.ability

	-- For the first half of the distance the unit goes up and for the second half it goes down
	if ability.leap_traveled < ability.leap_distance/2 then
		-- Go up
		-- This is to memorize the z point when it comes to cliffs and such although the division of speed by 2 isnt necessary, its more of a cosmetic thing
		ability.leap_z = ability.leap_z + ability.leap_speed * ability.leap_vertical_ratio
		-- Set the new location to the current ground location + the memorized z point
	else
		-- Go down
		ability.leap_z = ability.leap_z - ability.leap_speed * ability.leap_vertical_ratio
	end
		caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,ability.leap_z))
end

function BerserkersCall( keys )
	local caster = keys.caster
	local target = keys.target

	-- Clear the force attack target
	target:SetForceAttackTarget(nil)

	-- Give the attack order if the caster is alive
	-- otherwise forces the target to sit and do nothing
	if caster:IsAlive() then
		local order = 
		{
			UnitIndex = target:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = caster:entindex()
		}

		ExecuteOrderFromTable(order)
	else
		target:Stop()
	end

	-- Set the force attack target to be the caster
	target:SetForceAttackTarget(caster)
end

-- Clears the force attack target upon expiration
function BerserkersCallEnd( keys )
	local target = keys.target

	target:SetForceAttackTarget(nil)
end

function AttachParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local delay = keys.delay
	local attach = keys.attach
	local particle = keys.particle
	local weaponParticle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(weaponParticle, 0, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 1, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 2, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 3, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	Timers:CreateTimer( delay, function()
		ParticleManager:DestroyParticle(weaponParticle, false)
	end)
end

function PurgeTarget(keys)
	keys.target:Purge(false, true, false, true, false)
end

function ResolveGlobal(unresolved_global)
	local script = "local x = " .. unresolved_global .. "; return x"
	local f = loadstring(script)
	local value = f()
	return value
end

function Animate(keys)
	if not keys.animation or not keys.script_target then
		print ('ERROR: Function test.lua:Animate has missing arguments')
		PrintTable(keys)
	else
		local animation = ResolveGlobal(keys.animation)
		local target = keys.script_target == 'TARGET' and keys.target or keys.script_target == 'CASTER' and keys.caster
		target:StartGesture(animation)
	end
end

function StopAnimate(keys)
	if not keys.animation or not keys.script_target then
		print ('ERROR: Function test.lua:Animate has missing arguments')
		PrintTable(keys)
	else
		local animation = ResolveGlobal(keys.animation)
		local target = keys.script_target == 'TARGET' and keys.target or keys.script_target == 'CASTER' and keys.caster
		target:RemoveGesture(animation)
	end
end

function RemoveModifier(keys)
	if not keys.target or not keys.modifierName then
		print ('ERROR: Function test.lua:RemoveModifier has missing arguments')
		PrintTable(keys)
	else
		local target = keys.target
		target:RemoveModifierByName( keys.modifierName )
	end
end

function SpawnPrison(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local dummy = CreateUnitByName( "npc_dota_prison", target:GetAbsOrigin(), false, caster, caster, DOTA_TEAM_BADGUYS )
	local duration_prison = ability:GetLevelSpecialValueFor("duration_prison", 1)
	ability:ApplyDataDrivenModifier(caster, dummy, "modifier_death_monitor", {})
	ability.Prisoner = target
	ability.Prison = dummy
end

function ReleasePrison(keys)
	print('Releasing Prisoner...')
	local caster = keys.caster
	local ability = keys.ability
	local prisoner = ability.Prisoner
	local prison = ability.Prison
	local prisonModifierName = keys.prisonModifierName
	if not prisoner:IsNull() then 
		prisoner:RemoveModifierByName(prisonModifierName)
	end
	if not prison:IsNull() then
		prison:Destroy()
	end
end

function DestroyPrison(keys)
	print('Destroying Prison...')
	local caster = keys.caster
	local ability = keys.ability
	local prisoner = ability.Prisoner
	local prison = ability.Prison
	--prison:SetModel('models/development/invisiblebox.vmdl')
	prison:Destroy()
end

function InitResurrect(keys)
	local caster = keys.caster
	local stackCount = 2
	if caster.resurrectCount == 0 or caster.resurrectCount == 1 then
		stackCount = caster.resurrectCount
	end
	caster.resurrectCount = stackCount
	Timers:CreateTimer(1, function()	
			local modifier = caster:FindModifierByName('modifier_resurrect')
			print(modifier)
			if modifier then modifier:SetStackCount(stackCount) end
			return nil
		end
	)	
end

function DecrementResurrect(keys)
	local caster = keys.caster
	local caster = keys.caster
	caster.resurrectCount = caster.resurrectCount - 1
	if caster.resurrectCount < 0 then caster.resurrectCount = 0 end
end