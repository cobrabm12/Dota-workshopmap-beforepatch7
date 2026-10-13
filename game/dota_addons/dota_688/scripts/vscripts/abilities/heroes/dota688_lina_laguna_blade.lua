-- Laguna Blade (6.88): 450/650/850 daune magice dupa 0.25 s. Scepter: daune pure, trece prin imunitatea la magie.
require("dota688/aghanim")
dota688_lina_laguna_blade = class({})
function dota688_lina_laguna_blade:GetAbilityTargetFlags()
	if Dota688HasScepter(self:GetCaster()) then return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function dota688_lina_laguna_blade:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local scepter = Dota688HasScepter(caster)
	caster:EmitSound("Hero_Lina.LagunaBlade")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_laguna_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	local dmg = self:GetSpecialValueFor("damage")
	Dota688Timers:After(self:GetSpecialValueFor("damage_delay"), function()
		if target:IsNull() or not target:IsAlive() then return end
		if not scepter and target:IsMagicImmune() then return end
		target:EmitSound("Hero_Lina.LagunaBladeImpact")
		ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = scepter and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, ability = self })
	end)
end
