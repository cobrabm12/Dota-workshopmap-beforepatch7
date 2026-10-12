-- Sacrifice / Dark Ritual (6.88): sacrifica un creep aliat si transforma 30/50/70/90% din viata lui in mana.
-- Experienta creep-ului ii revine lui Lich.
dota688_lich_dark_ritual = class({})

function dota688_lich_dark_ritual:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if not target or not target:IsAlive() then return end
	local mana = target:GetHealth() * self:GetSpecialValueFor("health_conversion") / 100
	local xp = target:GetDeathXP()
	caster:EmitSound("Hero_Lich.DarkRitual")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lich/lich_dark_ritual.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:Kill(self, caster)
	caster:GiveMana(mana)
	if xp > 0 and caster:IsRealHero() then
		Dota688Creeps:GiveXP(caster, xp)   -- XP-ul CreepKill trece prin filtrul creepilor (dota688/creeps.lua)
	end
end
