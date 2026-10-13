-- Attribute Bonus clasic (6.88): +2 STR/AGI/INT pe nivel, 10 niveluri.
require("dota688/modifiers_link")   -- toti eroii au abilitatea, deci leaga modifierii globali si pe client
LinkLuaModifier("modifier_dota688_attribute_bonus", "abilities/dota688_attribute_bonus", LUA_MODIFIER_MOTION_NONE)

dota688_attribute_bonus = class({})
function dota688_attribute_bonus:GetIntrinsicModifierName() return "modifier_dota688_attribute_bonus" end
function dota688_attribute_bonus:ProcsMagicStick() return false end

-- Invoker 6.88: invoker_attribute_bonus (un nivel la 25, +6); acelasi modifier, alta valoare in KV
dota688_invoker_attribute_bonus = class({})
function dota688_invoker_attribute_bonus:GetIntrinsicModifierName() return "modifier_dota688_attribute_bonus" end
function dota688_invoker_attribute_bonus:ProcsMagicStick() return false end

modifier_dota688_attribute_bonus = class({})
function modifier_dota688_attribute_bonus:IsHidden() return true end
function modifier_dota688_attribute_bonus:IsPurgable() return false end
function modifier_dota688_attribute_bonus:RemoveOnDeath() return false end
function modifier_dota688_attribute_bonus:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_attribute_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end
function modifier_dota688_attribute_bonus:Bonus()
	local ab = self:GetAbility()
	if not ab then return 0 end
	return ab:GetLevel() * ab:GetSpecialValueFor("attribute_bonus_per_level")
end
function modifier_dota688_attribute_bonus:GetModifierBonusStats_Strength() return self:Bonus() end
function modifier_dota688_attribute_bonus:GetModifierBonusStats_Agility() return self:Bonus() end
function modifier_dota688_attribute_bonus:GetModifierBonusStats_Intellect() return self:Bonus() end
