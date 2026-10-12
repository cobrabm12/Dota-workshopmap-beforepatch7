-- Flesh Heap (6.88): +6/8/10/12% rezistenta magica; +1/1.5/2/2.5 STR permanent pentru fiecare erou inamic care moare in raza 450 (retroactiv).
LinkLuaModifier("modifier_dota688_pudge_flesh_heap", "abilities/heroes/dota688_pudge_flesh_heap", LUA_MODIFIER_MOTION_NONE)
dota688_pudge_flesh_heap = class({})
function dota688_pudge_flesh_heap:GetIntrinsicModifierName() return "modifier_dota688_pudge_flesh_heap" end

modifier_dota688_pudge_flesh_heap = class({})
function modifier_dota688_pudge_flesh_heap:IsHidden() return false end
function modifier_dota688_pudge_flesh_heap:IsPurgable() return false end
function modifier_dota688_pudge_flesh_heap:RemoveOnDeath() return false end
function modifier_dota688_pudge_flesh_heap:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_pudge_flesh_heap:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_STATS_STRENGTH_BONUS } end
function modifier_dota688_pudge_flesh_heap:OnDeath(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local unit = params.unit
	if not unit or not unit:IsRealHero() or unit:IsIllusion() or unit:GetTeamNumber() == parent:GetTeamNumber() then return end
	if (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > self:GetAbility():GetSpecialValueFor("flesh_heap_range") then return end
	self:IncrementStackCount()
end
function modifier_dota688_pudge_flesh_heap:GetModifierMagicalResistanceBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetAbility():GetSpecialValueFor("flesh_heap_magic_resist")
end
function modifier_dota688_pudge_flesh_heap:GetModifierBonusStats_Strength()
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("flesh_heap_strength_buff_amount")
end
