modifier_walk_animation = class({})

function modifier_walk_animation:OnCreated(keys) 
  self.translate = keys.translate
end

function modifier_walk_animation:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_walk_animation:IsHidden()
  return true
end

function modifier_walk_animation:IsDebuff() 
  return false
end

function modifier_walk_animation:IsPurgable() 
  return false
end

function modifier_walk_animation:DeclareFunctions() 
  local funcs = {
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
  }
  return funcs
end

function modifier_walk_animation:GetActivityTranslationModifiers(keys)
  return "walk"
end

LinkLuaModifier( "modifier_walk_animation", "lua_modifiers/walk_animation.lua", LUA_MODIFIER_MOTION_NONE )

--[[function modifier_animation_translate:CheckState() 
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }

  return state
end]]

