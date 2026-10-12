-- Berserker's Blood (6.88): pentru fiecare 10% viata lipsa (sub 100%): viteza de atac si rezistenta magica, pana la 220-340 AS si 20-50% rezistenta.
LinkLuaModifier("modifier_dota688_huskar_berserkers_blood", "abilities/heroes/dota688_huskar_berserkers_blood", LUA_MODIFIER_MOTION_NONE)
dota688_huskar_berserkers_blood = class({})
function dota688_huskar_berserkers_blood:GetIntrinsicModifierName() return "modifier_dota688_huskar_berserkers_blood" end

modifier_dota688_huskar_berserkers_blood = class({})
function modifier_dota688_huskar_berserkers_blood:IsHidden() return true end
function modifier_dota688_huskar_berserkers_blood:IsPurgable() return false end
function modifier_dota688_huskar_berserkers_blood:Steps()
	local parent = self:GetParent()
	if parent:PassivesDisabled() then return 0 end
	local missing = 1 - parent:GetHealth() / math.max(1, parent:GetMaxHealth())
	local threshold = self:GetAbility():GetSpecialValueFor("hp_threshold_max") / 100  -- 10%
	local steps = math.floor(missing / threshold + 0.0001)
	return math.min(steps, math.floor(1 / threshold) - 1)  -- max 9 trepte (10%..90% lipsa)
end
function modifier_dota688_huskar_berserkers_blood:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end
function modifier_dota688_huskar_berserkers_blood:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("maximum_attack_speed") / 9 * self:Steps()
end
function modifier_dota688_huskar_berserkers_blood:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("maximum_resistance") / 9 * self:Steps()
end
