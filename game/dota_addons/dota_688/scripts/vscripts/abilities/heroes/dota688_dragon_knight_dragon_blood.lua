-- Dragon Blood (6.88): +3/6/9/12 regenerare si +3/6/9/12 armura.
LinkLuaModifier("modifier_dota688_dragon_knight_dragon_blood", "abilities/heroes/dota688_dragon_knight_dragon_blood", LUA_MODIFIER_MOTION_NONE)
dota688_dragon_knight_dragon_blood = class({})
function dota688_dragon_knight_dragon_blood:GetIntrinsicModifierName() return "modifier_dota688_dragon_knight_dragon_blood" end
modifier_dota688_dragon_knight_dragon_blood = class({})
function modifier_dota688_dragon_knight_dragon_blood:IsHidden() return true end
function modifier_dota688_dragon_knight_dragon_blood:IsPurgable() return false end
function modifier_dota688_dragon_knight_dragon_blood:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_dragon_knight_dragon_blood:GetModifierConstantHealthRegen()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end
function modifier_dota688_dragon_knight_dragon_blood:GetModifierPhysicalArmorBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
