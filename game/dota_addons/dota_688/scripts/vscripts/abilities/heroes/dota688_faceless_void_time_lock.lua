-- Time Lock (6.88): pasiv; 10/15/20/25% sansa (PRD) ca atacul sa stuneze tinta 1 s (2 s pe creepi) si sa faca
-- +50/75/100/125 daune magice. Stunul trece prin imunitate (daunele magice nu). Nu pe cladiri, nu de pe iluzii.
require("dota688/val")
LinkLuaModifier("modifier_dota688_faceless_void_time_lock", "abilities/heroes/dota688_faceless_void_time_lock", LUA_MODIFIER_MOTION_NONE)
dota688_faceless_void_time_lock = class({})
function dota688_faceless_void_time_lock:GetIntrinsicModifierName() return "modifier_dota688_faceless_void_time_lock" end

modifier_dota688_faceless_void_time_lock = class({})
function modifier_dota688_faceless_void_time_lock:IsHidden() return true end
function modifier_dota688_faceless_void_time_lock:IsPurgable() return false end
function modifier_dota688_faceless_void_time_lock:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_faceless_void_time_lock:OnAttackLanded(params)
	if not IsServer() then return end
	local parent, target = self:GetParent(), params.target
	if params.attacker ~= parent or not target or target:IsNull() or not target:IsAlive() then return end
	if parent:PassivesDisabled() or parent:IsIllusion() then return end
	if target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 then return end
	if not RollPseudoRandomPercentage(a:GetSpecialValueFor("chance_pct"), DOTA_PSEUDO_RANDOM_FACELESS_BASH, parent) then return end
	local dur = (target:IsHero() or target:IsConsideredHero()) and a:GetSpecialValueFor("duration") or a:GetSpecialValueFor("duration_creep")
	target:AddNewModifier(parent, a, "modifier_stunned", { duration = dur })
	ApplyDamage({ victim = target, attacker = parent, damage = a:GetSpecialValueFor("bonus_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(fx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(fx, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(fx, 2, parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:EmitSound("Hero_FacelessVoid.TimeLockImpact")
end
