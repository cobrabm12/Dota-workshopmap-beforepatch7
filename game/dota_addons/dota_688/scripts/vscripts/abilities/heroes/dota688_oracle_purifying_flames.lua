-- Purifying Flames (6.88): 90/180/270/360 daune magice instant, apoi vindeca 11/22/33/44 HP/s timp de 9 s (aliat sau inamic).
-- Scepter: cooldown 1, cast point 0.1.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_purifying_flames", "abilities/heroes/dota688_oracle_purifying_flames", LUA_MODIFIER_MOTION_NONE)
dota688_oracle_purifying_flames = class({})
function dota688_oracle_purifying_flames:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_oracle_purifying_flames:GetCastPoint()
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("castpoint_scepter") end
	return self.BaseClass.GetCastPoint(self)
end
function dota688_oracle_purifying_flames:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Oracle.PurifyingFlames.Damage")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	if not target:IsMagicImmune() or target:GetTeamNumber() == caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	end
	target:AddNewModifier(caster, self, "modifier_dota688_purifying_flames", { duration = self:GetSpecialValueFor("duration") })
end
modifier_dota688_purifying_flames = class({})
function modifier_dota688_purifying_flames:IsPurgable() return true end
function modifier_dota688_purifying_flames:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_purifying_flames:OnCreated() if IsServer() then self:StartIntervalThink(Dota688Val(self, "tick_rate")) end end
function modifier_dota688_purifying_flames:OnIntervalThink()
	self:GetParent():Heal(Dota688Val(self, "heal_per_second") * Dota688Val(self, "tick_rate"), self:GetAbility())
end
