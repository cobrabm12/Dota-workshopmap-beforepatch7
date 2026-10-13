-- Warpath (6.88): la fiecare vraja castata: +20/25/30 daune si +3/4/5% MS de baza plus la fel per stack (max 5/6/7), 14 s.
local F = "abilities/heroes/dota688_bristleback_warpath"
LinkLuaModifier("modifier_dota688_bristleback_warpath", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bristleback_warpath_stack", F, LUA_MODIFIER_MOTION_NONE)
dota688_bristleback_warpath = class({})
function dota688_bristleback_warpath:GetIntrinsicModifierName() return "modifier_dota688_bristleback_warpath" end
modifier_dota688_bristleback_warpath = class({})
function modifier_dota688_bristleback_warpath:IsHidden() return true end
function modifier_dota688_bristleback_warpath:IsPurgable() return false end
function modifier_dota688_bristleback_warpath:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_bristleback_warpath:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:IsItem() or params.ability == self:GetAbility() then return end
	if self:GetParent():PassivesDisabled() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local m = self:GetParent():FindModifierByName("modifier_dota688_bristleback_warpath_stack")
	if not m then m = self:GetParent():AddNewModifier(self:GetParent(), a, "modifier_dota688_bristleback_warpath_stack", { duration = a:GetSpecialValueFor("stack_duration") }); m:SetStackCount(0) end
	m:SetStackCount(math.min(a:GetSpecialValueFor("max_stacks"), m:GetStackCount() + 1))
	m:ForceRefresh()
end
modifier_dota688_bristleback_warpath_stack = class({})
function modifier_dota688_bristleback_warpath_stack:IsPurgable() return false end
function modifier_dota688_bristleback_warpath_stack:GetEffectName() return "particles/units/heroes/hero_bristleback/bristleback_warpath.vpcf" end
function modifier_dota688_bristleback_warpath_stack:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_bristleback_warpath_stack:GetModifierPreAttack_BonusDamage()
	local a = self:GetAbility(); return a:GetSpecialValueFor("base_damage") + a:GetSpecialValueFor("damage_per_stack") * (self:GetStackCount() - 1)
end
function modifier_dota688_bristleback_warpath_stack:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility(); return a:GetSpecialValueFor("base_move_speed") + a:GetSpecialValueFor("move_speed_per_stack") * (self:GetStackCount() - 1)
end
