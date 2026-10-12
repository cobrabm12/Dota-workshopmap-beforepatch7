-- Jinada (6.88): la fiecare 12/10/8/6 s, urmatorul atac e critic 150/175/200/225% si incetineste tinta cu 15/20/25/30% MS si AS pentru 3 s.
local F = "abilities/heroes/dota688_bounty_hunter_jinada"
LinkLuaModifier("modifier_dota688_bounty_hunter_jinada", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bounty_hunter_jinada_slow", F, LUA_MODIFIER_MOTION_NONE)

dota688_bounty_hunter_jinada = class({})
function dota688_bounty_hunter_jinada:GetIntrinsicModifierName() return "modifier_dota688_bounty_hunter_jinada" end

modifier_dota688_bounty_hunter_jinada = class({})
function modifier_dota688_bounty_hunter_jinada:IsHidden() return true end
function modifier_dota688_bounty_hunter_jinada:IsPurgable() return false end
function modifier_dota688_bounty_hunter_jinada:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_bounty_hunter_jinada:GetModifierPreAttack_CriticalStrike(params)
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then return 0 end
	if parent:PassivesDisabled() or not ability:IsCooldownReady() then return nil end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() then return nil end
	self.procTarget = target
	return ability:GetSpecialValueFor("crit_multiplier")
end
function modifier_dota688_bounty_hunter_jinada:OnAttackLanded(params)
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() or params.target ~= self.procTarget then return end
	self.procTarget = nil
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then return end
	ability:UseResources(false, false, false, true)
	params.target:AddNewModifier(self:GetParent(), ability, "modifier_dota688_bounty_hunter_jinada_slow", { duration = ability:GetSpecialValueFor("duration") })
	params.target:EmitSound("Hero_BountyHunter.Jinada")
end

modifier_dota688_bounty_hunter_jinada_slow = class({})
function modifier_dota688_bounty_hunter_jinada_slow:IsDebuff() return true end
function modifier_dota688_bounty_hunter_jinada_slow:IsPurgable() return true end
function modifier_dota688_bounty_hunter_jinada_slow:OnCreated()
	self.ms = self:GetAbility():GetSpecialValueFor("bonus_movespeed")
	self.as = self:GetAbility():GetSpecialValueFor("bonus_attackspeed")
end
function modifier_dota688_bounty_hunter_jinada_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_dota688_bounty_hunter_jinada_slow:GetModifierMoveSpeedBonus_Percentage() return self.ms end
function modifier_dota688_bounty_hunter_jinada_slow:GetModifierAttackSpeedBonus_Constant() return self.as end
