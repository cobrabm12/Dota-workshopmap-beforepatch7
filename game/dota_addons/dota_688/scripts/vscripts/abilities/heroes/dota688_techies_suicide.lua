-- Suicide Squad, Attack! (6.88): Techies se arunca in aer: 500/650/850/1150 daune fizice in 200 (260-380 in 500); moare, dar cu respawn injumatatit.
require("abilities/heroes/dota688_techies_shared")
dota688_techies_suicide = class({})
function dota688_techies_suicide:OnSpellStart()
	local caster = self:GetCaster()
	local pos = caster:GetAbsOrigin()
	caster:EmitSound("Hero_Techies.Suicide")
	local small, big = self:GetSpecialValueFor("small_radius"), self:GetSpecialValueFor("big_radius")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_suicide.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, big, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		local dmg = ((e:GetAbsOrigin() - pos):Length2D() <= small) and self:GetSpecialValueFor("damage") or self:GetSpecialValueFor("partial_damage")
		ApplyDamage({ victim = e, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, ability = self })
	end
	caster.dota688_suicide = true
	caster:Kill(self, caster)
	Dota688Timers:After(0.1, function()
		if caster:IsNull() or caster:IsAlive() then return end
		caster:SetTimeUntilRespawn(caster:GetTimeUntilRespawn() * self:GetSpecialValueFor("respawn_time_percentage"))
	end)
end
