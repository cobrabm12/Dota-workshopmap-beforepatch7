-- Reaper's Scythe (6.88): stun 1.5 s, apoi 0.6/0.75/0.9 daune magice pentru fiecare HP lipsa; eroul omorat are +10/20/30 s la respawn.
-- Scepter: cooldown 70, mana 150/340/500, 0.6/0.9/1.2 daune/HP, eroul omorat nu poate face buyback (dota688/respawn_buyback.lua).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_reapers_scythe", "abilities/heroes/dota688_necrolyte_reapers_scythe", LUA_MODIFIER_MOTION_NONE)
dota688_necrolyte_reapers_scythe = class({})
function dota688_necrolyte_reapers_scythe:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_necrolyte_reapers_scythe:GetManaCost(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("mana_cost_scepter", level) end
	return self.BaseClass.GetManaCost(self, level)
end
function dota688_necrolyte_reapers_scythe:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Necrolyte.ReapersScythe.Cast")
	target:EmitSound("Hero_Necrolyte.ReapersScythe.Target")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_scythe.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:AddNewModifier(caster, self, "modifier_dota688_reapers_scythe", { duration = self:GetSpecialValueFor("stun_duration") })
end
modifier_dota688_reapers_scythe = class({})
function modifier_dota688_reapers_scythe:IsDebuff() return true end
function modifier_dota688_reapers_scythe:IsPurgable() return false end
function modifier_dota688_reapers_scythe:IsStunDebuff() return true end
function modifier_dota688_reapers_scythe:CheckState() return { [MODIFIER_STATE_STUNNED] = true } end
function modifier_dota688_reapers_scythe:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_dota688_reapers_scythe:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_reapers_scythe:OnDestroy()
	if not IsServer() then return end
	local p, a, caster = self:GetParent(), self:GetAbility(), self:GetCaster()
	if not p:IsAlive() or not a or not caster or caster:IsNull() then return end
	local mult = Dota688HasScepter(caster) and a:GetSpecialValueFor("damage_per_health_scepter") or a:GetSpecialValueFor("damage_per_health")
	local dmg = (p:GetMaxHealth() - p:GetHealth()) * mult
	-- marcam tinta pentru respawn_buyback (timp de respawn marit / fara buyback) chiar daca modifierul a expirat
	p.dota688_scythe_caster = caster
	p.dota688_scythe_time = GameRules:GetGameTime()
	p.dota688_scythe_respawn = a:GetSpecialValueFor("respawn_constant")
	if p:IsMagicImmune() then return end   -- "The stun goes through spell immunity, but not the damage"
	ApplyDamage({ victim = p, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
end
