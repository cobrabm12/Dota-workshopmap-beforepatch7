-- Heat-Seeking Missile (6.88): 2 rachete (viteza 900) spre cei mai apropiati eroi inamici vizibili din 2500, 125/200/275/350 daune magice. Scepter: 4 rachete.
require("dota688/aghanim")
dota688_tinker_heat_seeking_missile = class({})
function dota688_tinker_heat_seeking_missile:OnSpellStart()
	local caster = self:GetCaster()
	local n = Dota688HasScepter(caster) and self:GetSpecialValueFor("targets_scepter") or self:GetSpecialValueFor("targets")
	local heroes = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_CLOSEST, false)
	caster:EmitSound("Hero_Tinker.Heat-Seeking_Missile")
	for i = 1, math.min(n, #heroes) do
		ProjectileManager:CreateTrackingProjectile({
			Target = heroes[i], Source = caster, Ability = self,
			EffectName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf",
			iMoveSpeed = self:GetSpecialValueFor("speed"), vSourceLoc = caster:GetAbsOrigin() + Vector(0, 0, 200), bDodgeable = true, bProvidesVision = true, iVisionRadius = 300, iVisionTeamNumber = caster:GetTeamNumber(),
		})
	end
end
function dota688_tinker_heat_seeking_missile:OnProjectileHit(target, location)
	if not target or target:IsMagicImmune() then return end
	target:EmitSound("Hero_Tinker.Heat-Seeking_Missile.Impact")
	ApplyDamage({ victim = target, attacker = self:GetCaster(), damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
end
