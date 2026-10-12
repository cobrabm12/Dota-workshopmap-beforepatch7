-- Berserker's Blood (6.88): viteza de atac si rezistenta magica crescand liniar cu viata lipsa (0 la 100 % HP, maxim 220-340 AS si
-- 20-50 % rezistenta la 10 % HP).
require("dota688/val")
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
	local threshold = Dota688Val(self, "hp_threshold_max") / 100  -- 10 %: pragul la care bonusul e maxim
	-- fractiune 0..1 din bonusul maxim ("Bonuses are provided linearly, no bonus at 100% HP and full bonus at 10% HP")
	return math.max(0, math.min(1, missing / math.max(0.01, 1 - threshold)))
end
function modifier_dota688_huskar_berserkers_blood:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end
function modifier_dota688_huskar_berserkers_blood:GetModifierAttackSpeedBonus_Constant()
	return Dota688Val(self, "maximum_attack_speed") * self:Steps()
end
function modifier_dota688_huskar_berserkers_blood:GetModifierMagicalResistanceBonus()
	return Dota688Val(self, "maximum_resistance") * self:Steps()
end
