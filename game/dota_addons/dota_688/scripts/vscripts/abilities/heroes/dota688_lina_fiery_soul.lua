-- Fiery Soul (6.88): la fiecare vraja: +40/55/70/85 AS si +5/6/7/8% MS per stack (max 3), 10 s.
local F = "abilities/heroes/dota688_lina_fiery_soul"
LinkLuaModifier("modifier_dota688_lina_fiery_soul", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lina_fiery_soul_stack", F, LUA_MODIFIER_MOTION_NONE)
dota688_lina_fiery_soul = class({})
function dota688_lina_fiery_soul:GetIntrinsicModifierName() return "modifier_dota688_lina_fiery_soul" end
modifier_dota688_lina_fiery_soul = class({})
function modifier_dota688_lina_fiery_soul:IsHidden() return true end
function modifier_dota688_lina_fiery_soul:IsPurgable() return false end
function modifier_dota688_lina_fiery_soul:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_lina_fiery_soul:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:IsItem() or self:GetParent():PassivesDisabled() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local m = self:GetParent():FindModifierByName("modifier_dota688_lina_fiery_soul_stack")
	if not m then m = self:GetParent():AddNewModifier(self:GetParent(), a, "modifier_dota688_lina_fiery_soul_stack", { duration = a:GetDuration() }); m:SetStackCount(0) end
	m:SetStackCount(math.min(a:GetSpecialValueFor("fiery_soul_max_stacks"), m:GetStackCount() + 1)); m:ForceRefresh()
end
modifier_dota688_lina_fiery_soul_stack = class({})
function modifier_dota688_lina_fiery_soul_stack:IsPurgable() return false end
function modifier_dota688_lina_fiery_soul_stack:GetEffectName() return "particles/units/heroes/hero_lina/lina_fiery_soul.vpcf" end
function modifier_dota688_lina_fiery_soul_stack:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_lina_fiery_soul_stack:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("fiery_soul_attack_speed_bonus") * self:GetStackCount() end
function modifier_dota688_lina_fiery_soul_stack:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("fiery_soul_move_speed_bonus") * self:GetStackCount() end
