-- Take Aim (6.88): +100/200/300/400 raza de atac, pasiv.
LinkLuaModifier("modifier_dota688_sniper_take_aim", "abilities/heroes/dota688_sniper_take_aim", LUA_MODIFIER_MOTION_NONE)
dota688_sniper_take_aim = class({})
function dota688_sniper_take_aim:GetIntrinsicModifierName() return "modifier_dota688_sniper_take_aim" end
modifier_dota688_sniper_take_aim = class({})
function modifier_dota688_sniper_take_aim:IsHidden() return true end
function modifier_dota688_sniper_take_aim:IsPurgable() return false end
function modifier_dota688_sniper_take_aim:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACK_RANGE_BONUS } end
function modifier_dota688_sniper_take_aim:GetModifierAttackRangeBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end
