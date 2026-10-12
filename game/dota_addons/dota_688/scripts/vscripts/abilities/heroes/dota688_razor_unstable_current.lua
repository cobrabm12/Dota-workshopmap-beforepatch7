-- Unstable Current (6.88): +4/8/12/16% MS; cand e tintit de o vraja inamica: 40/70/100/130 daune magice, purge si -100% MS 0.5-2 s pe caster.
require("dota688/val")
local F = "abilities/heroes/dota688_razor_unstable_current"
LinkLuaModifier("modifier_dota688_razor_unstable_current", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_razor_unstable_current_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_razor_unstable_current = class({})
function dota688_razor_unstable_current:GetIntrinsicModifierName() return "modifier_dota688_razor_unstable_current" end
modifier_dota688_razor_unstable_current = class({})
function modifier_dota688_razor_unstable_current:IsHidden() return true end
function modifier_dota688_razor_unstable_current:IsPurgable() return false end
function modifier_dota688_razor_unstable_current:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_razor_unstable_current:GetModifierMoveSpeedBonus_Percentage()
	if self:GetParent():PassivesDisabled() then return 0 end
	return Dota688Val(self, "movement_speed_pct")
end
function modifier_dota688_razor_unstable_current:OnAbilityExecuted(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.target ~= parent or parent:PassivesDisabled() then return end
	local caster = params.unit
	if not caster or caster:GetTeamNumber() == parent:GetTeamNumber() or caster:IsMagicImmune() or not caster:IsHero() then return end   -- "Only activates if the caster is a hero unit"
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	ApplyDamage({ victim = caster, attacker = parent, damage = a:GetAbilityDamage(), damage_type = a:GetAbilityDamageType(), ability = a })
	caster:Purge(true, false, false, false, false)
	caster:AddNewModifier(parent, a, "modifier_dota688_razor_unstable_current_slow", { duration = a:GetSpecialValueFor("slow_duration") })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_razor/razor_unstable_current.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end
modifier_dota688_razor_unstable_current_slow = class({})
function modifier_dota688_razor_unstable_current_slow:IsDebuff() return true end
function modifier_dota688_razor_unstable_current_slow:IsPurgable() return true end
function modifier_dota688_razor_unstable_current_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_razor_unstable_current_slow:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "slow_amount") end
